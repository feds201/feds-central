package frc.rtu;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import org.littletonrobotics.junction.Logger;

import edu.wpi.first.wpilibj2.command.SubsystemBase;
import edu.wpi.first.wpilibj.RobotBase;

/**
 * <h2>Root Testing Utility</h2>
 *
 * Automatically discovers methods annotated with {@link RobotAction} on any
 * {@link SubsystemBase} instance, then executes them in order when the robot
 * enters <b>Test mode</b>.
 *
 * <h3>Lifecycle</h3>
 * <ol>
 *   <li>{@link #registerSubsystem(SubsystemBase...)} -- call once from
 *       {@code RobotContainer} to hand the utility every subsystem you want
 *       tested.</li>
 *   <li>{@link #discoverActions()} -- called internally; scans registered
 *       subsystems for {@code @RobotAction} methods via reflection.</li>
 *   <li>{@link #runAll()} -- invoked from {@code Robot.testInit()} to run
 *       every discovered action and record results.</li>
 *   <li>{@link #periodic()} -- invoked from {@code Robot.testPeriodic()} to
 *       keep logged data fresh.</li>
 * </ol>
 *
 * <h3>Result recording</h3>
 * Results are published to:
 * <ul>
 *   <li><b>Console</b> (System.out)</li>
 *   <li><b>AdvantageKit Logger</b> -- under {@code RootTests/...} keys,
 *       viewable in AdvantageScope</li>
 *   <li><b>Diagnostic Server</b> -- embedded HTTP dashboard at
 *       {@code http://&lt;ip&gt;:5800/diag/&lt;session&gt;} with charts,
 *       alerts, and data profiles</li>
 * </ul>
 *
 * <h3>DiagnosticContext injection</h3>
 * If a {@code @RobotAction} method declares a single
 * {@link DiagnosticContext} parameter, the utility will automatically
 * create one and pass it in.  The test can then call
 * {@code ctx.info(...)}, {@code ctx.warn(...)}, {@code ctx.error(...)},
 * and {@code ctx.sample(series, value)} to record alerts and profiling data.
 */
public final class RootTestingUtility {

    private record DiscoveredTest(
        SubsystemBase subsystem,
        Method method,
        String name,
        String description,
        int order,
        double timeoutSeconds,
        RobotAction.ActionType actionType,
        boolean isSequence
    ) {}

    private final List<SubsystemBase> registeredSubsystems = new ArrayList<>();
    private final List<DiscoveredTest> tests = new ArrayList<>();
    private final List<TestResult> results = new ArrayList<>();

    private static final String LOG_PREFIX = "RootTests/";
    private static final int DIAG_PORT = 5800;
    private static final String DB_PATH = "/home/lvuser/rtu_history.sqlite";

    private boolean hasRun = false;
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private DiagnosticServer diagServer;
    private final TestHistoryDatabase db = new TestHistoryDatabase(DB_PATH);

    public interface SafetyCheck {
        /** Returns an error message if safety check fails, or null if it passes. */
        String checkSafety();
    }

    private SafetyCheck safetyCheck;

    /** Set a safety check that must pass before and during test execution. */
    public void setSafetyCheck(SafetyCheck check) {
        this.safetyCheck = check;
    }

    // ── Headless CI Simulation ───────────────────────────────

    /** 
     * Detects if running in a headless CI environment. 
     * Tests can use this to swap to WPILib PhysicsSim classes instead of physical calls.
     */
    public static boolean isHeadlessSim() {
        return RobotBase.isSimulation() && (System.getenv("CI") != null || System.getProperty("CI") != null);
    }

    // ── Registration ─────────────────────────────────────────

    /**
     * Register one or more subsystems whose {@code @RobotAction} methods
     * should be discovered and executed during test mode.
     */
    public void registerSubsystem(SubsystemBase... subsystems) {
        for (SubsystemBase s : subsystems) {
            if (s != null && !registeredSubsystems.contains(s)) {
                registeredSubsystems.add(s);
            }
        }
    }

    // ── Discovery ────────────────────────────────────────────

    /**
     * Scans every registered subsystem for methods carrying
     * {@link RobotAction} and stores them sorted by
     * {@link RobotAction#order()}.
     *
     * <p>Methods may have zero parameters, or a single
     * {@link DiagnosticContext} parameter.  Any other signature is skipped.
     */
    public void discoverActions() {
        tests.clear();

        for (SubsystemBase subsystem : registeredSubsystems) {
            Class<?> clazz = subsystem.getClass();
            for (Method m : clazz.getDeclaredMethods()) {
                RobotAction annAction = m.getAnnotation(RobotAction.class);
                RobotSequence annSeq = m.getAnnotation(RobotSequence.class);
                if (annAction == null && annSeq == null) continue;

                boolean isSeq = annSeq != null;
                String name = isSeq ? annSeq.name() : annAction.name();
                String desc = isSeq ? annSeq.description() : annAction.description();
                int order = isSeq ? annSeq.order() : annAction.order();
                double timeout = isSeq ? annSeq.timeoutSeconds() : annAction.timeoutSeconds();
                RobotAction.ActionType type = isSeq ? RobotAction.ActionType.DIAGNOSTIC : annAction.type();
                
                // Validate return type
                Class<?> ret = m.getReturnType();
                if (!isSeq) {
                    if (ret != boolean.class && ret != Boolean.class && ret != void.class) {
                        System.err.println("[RootTestingUtility] Skipping " + clazz.getSimpleName()
                            + "." + m.getName() + " -- return type must be boolean or void for @RobotAction, got "
                            + ret.getSimpleName());
                        continue;
                    }
                } else {
                    if (!edu.wpi.first.wpilibj2.command.Command.class.isAssignableFrom(ret)) {
                        System.err.println("[RootTestingUtility] Skipping " + clazz.getSimpleName()
                            + "." + m.getName() + " -- return type must be Command for @RobotSequence, got "
                            + ret.getSimpleName());
                        continue;
                    }
                }

                // Validate parameters: () or (DiagnosticContext)
                Class<?>[] params = m.getParameterTypes();
                if (params.length > 1) {
                    System.err.println("[RootTestingUtility] Skipping " + clazz.getSimpleName()
                        + "." + m.getName() + " -- expected 0 or 1 (DiagnosticContext) params, got "
                        + params.length);
                    continue;
                }
                if (params.length == 1 && params[0] != DiagnosticContext.class) {
                    System.err.println("[RootTestingUtility] Skipping " + clazz.getSimpleName()
                        + "." + m.getName() + " -- param must be DiagnosticContext, got "
                        + params[0].getSimpleName());
                    continue;
                }

                m.setAccessible(true);
                tests.add(new DiscoveredTest(subsystem, m, name, desc, order, timeout, type, isSeq));
            }
        }

        // Sort by annotation order, then by name for stability
        tests.sort(Comparator.<DiscoveredTest>comparingInt(t -> t.order())
                               .thenComparing(t -> resolveName(t)));

        System.out.println("[RootTestingUtility] Discovered " + tests.size()
            + " test(s) across " + registeredSubsystems.size() + " subsystem(s):");
        for (DiscoveredTest t : tests) {
            System.out.println("  - " + t.subsystem().getName() + " -> " + resolveName(t));
        }
    }

    // ── Execution ────────────────────────────────────────────

    /**
     * Runs every discovered action sequentially in a background thread, records
     * {@link TestResult}s, publishes to AK Logger, and updates
     * the diagnostic server.
     */
    public void runAll() {
        if (tests.isEmpty()) {
            discoverActions();
        }

        // Start diagnostic server on first run
        if (diagServer == null) {
            diagServer = new DiagnosticServer(DIAG_PORT);
            diagServer.start();
        }

        results.clear();
        hasRun = true;

        new Thread(() -> {
            System.out.println("\n+==========================================+");
            System.out.println("|      ROOT TESTING UTILITY -- START        |");
            System.out.println("+==========================================+");
            System.out.println("| Diagnostic dashboard:                     |");
            System.out.println("|   " + diagServer.getUrl());
            System.out.println("+==========================================+");

            for (DiscoveredTest action : tests) {
                // Wait for safety check before starting the test
                while (safetyCheck != null) {
                    String safetyError = safetyCheck.checkSafety();
                    if (safetyError == null) {
                        diagServer.setSafetyMessage(null);
                        break;
                    }
                    diagServer.setSafetyMessage(safetyError);
                    try {
                        Thread.sleep(50);
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                        return;
                    }
                }

                TestResult result = executeAction(action);
                results.add(result);
                System.out.println(result);

                // If safety check failed during execution, stop tests
                if (safetyCheck != null && safetyCheck.checkSafety() != null) {
                    System.out.println("[RootTestingUtility] Safety check failed, stopping tests.");
                    break;
                }
            }

            int passed = (int) results.stream().filter(TestResult::isPassed).count();
            int failed = results.size() - passed;

            System.out.println("+==========================================+");
            System.out.printf("|  TOTAL: %d  |  PASSED: %d  |  FAILED: %d%n", results.size(), passed, failed);
            System.out.println("+==========================================+");
            System.out.println("| Dashboard: " + diagServer.getUrl());
            System.out.println("+==========================================+\n");

            publishResults();
            diagServer.updateResults(results);
            db.saveResults(results); // Save to local SQLite
        }).start();
    }

    /**
     * Execute a single discovered action with timeout and
     * optional {@link DiagnosticContext} injection.
     */
    private TestResult executeAction(DiscoveredTest action) {
        String subsystemName = action.subsystem().getName();
        String actionName = resolveName(action);
        String description = action.description();
        long timeoutMs = (long) (action.timeoutSeconds() * 1000);

        // Create a DiagnosticContext for this test
        DiagnosticContext ctx = new DiagnosticContext();

        long startNs = System.nanoTime();

        // Determine whether the method wants a DiagnosticContext param
        boolean wantsContext = action.method().getParameterCount() == 1;

        if (action.isSequence()) {
            return executeSequence(action, ctx, subsystemName, actionName, description, timeoutMs, startNs, wantsContext);
        }

        Callable<Object> task = () -> {
            if (wantsContext) {
                return action.method().invoke(action.subsystem(), ctx);
            } else {
                return action.method().invoke(action.subsystem());
            }
        };

        try {
            Future<Object> future = executor.submit(task);
            Object returnValue = null;
            boolean finished = false;
            long startMs = System.currentTimeMillis();

            while (System.currentTimeMillis() - startMs < timeoutMs) {
                if (safetyCheck != null) {
                    String safetyError = safetyCheck.checkSafety();
                    if (safetyError != null) {
                        future.cancel(true);
                        diagServer.setSafetyMessage(safetyError);
                        double durationMs = (System.nanoTime() - startNs) / 1_000_000.0;
                        return new TestResult(subsystemName, actionName, description,
                            TestResult.Status.FAILED,
                            new RuntimeException("Safety check failed: " + safetyError),
                            durationMs, ctx.getAlerts(), ctx.getDataProfiles(), ctx.getDataProfilesNd());
                    }
                }
                try {
                    returnValue = future.get(20, TimeUnit.MILLISECONDS);
                    finished = true;
                    break;
                } catch (TimeoutException te) {
                    // continue waiting
                }
            }

            if (!finished) {
                future.cancel(true);
                double durationMs = (System.nanoTime() - startNs) / 1_000_000.0;
                return new TestResult(subsystemName, actionName, description,
                    TestResult.Status.TIMED_OUT,
                    new RuntimeException("Timed out after " + timeoutMs + " ms"),
                    durationMs, ctx.getAlerts(), ctx.getDataProfiles(), ctx.getDataProfilesNd());
            }

            double durationMs = (System.nanoTime() - startNs) / 1_000_000.0;

            // void methods pass if they didn't throw
            if (action.method().getReturnType() == void.class) {
                return new TestResult(subsystemName, actionName, description,
                    TestResult.Status.PASSED, null, durationMs,
                    ctx.getAlerts(), ctx.getDataProfiles(), ctx.getDataProfilesNd());
            }

            // boolean methods
            boolean passed = Boolean.TRUE.equals(returnValue);
            return new TestResult(subsystemName, actionName, description,
                passed ? TestResult.Status.PASSED : TestResult.Status.FAILED,
                passed ? null : new AssertionError("Returned false"),
                durationMs, ctx.getAlerts(), ctx.getDataProfiles(), ctx.getDataProfilesNd());

        } catch (Exception e) {
            double durationMs = (System.nanoTime() - startNs) / 1_000_000.0;
            Throwable cause = e.getCause() != null ? e.getCause() : e;
            return new TestResult(subsystemName, actionName, description,
                TestResult.Status.FAILED, cause, durationMs,
                ctx.getAlerts(), ctx.getDataProfiles(), ctx.getDataProfilesNd());
        }
    }

    private TestResult executeSequence(DiscoveredTest action, DiagnosticContext ctx, 
            String subsystemName, String actionName, String description, long timeoutMs, long startNs, boolean wantsContext) {
        
        try {
            edu.wpi.first.wpilibj2.command.Command cmd = null;
            if (wantsContext) {
                cmd = (edu.wpi.first.wpilibj2.command.Command) action.method().invoke(action.subsystem(), ctx);
            } else {
                cmd = (edu.wpi.first.wpilibj2.command.Command) action.method().invoke(action.subsystem());
            }
            if (cmd == null) {
                return new TestResult(subsystemName, actionName, description,
                    TestResult.Status.FAILED, new RuntimeException("Command was null"),
                    (System.nanoTime() - startNs) / 1_000_000.0, ctx.getAlerts(), ctx.getDataProfiles(), ctx.getDataProfilesNd());
            }

            edu.wpi.first.wpilibj2.command.CommandScheduler.getInstance().schedule(cmd);
            long startMs = System.currentTimeMillis();
            boolean passed = false;

            while (System.currentTimeMillis() - startMs < timeoutMs) {
                if (safetyCheck != null) {
                    String safetyError = safetyCheck.checkSafety();
                    if (safetyError != null) {
                        cmd.cancel();
                        diagServer.setSafetyMessage(safetyError);
                        return new TestResult(subsystemName, actionName, description,
                            TestResult.Status.FAILED,
                            new RuntimeException("Safety check failed: " + safetyError),
                            (System.nanoTime() - startNs) / 1_000_000.0, ctx.getAlerts(), ctx.getDataProfiles(), ctx.getDataProfilesNd());
                    }
                }
                if (!edu.wpi.first.wpilibj2.command.CommandScheduler.getInstance().isScheduled(cmd)) {
                    passed = true;
                    break;
                }
                Thread.sleep(20);
            }

            if (!passed) {
                cmd.cancel();
                return new TestResult(subsystemName, actionName, description,
                    TestResult.Status.TIMED_OUT,
                    new RuntimeException("Sequence timed out after " + timeoutMs + " ms"),
                    (System.nanoTime() - startNs) / 1_000_000.0, ctx.getAlerts(), ctx.getDataProfiles(), ctx.getDataProfilesNd());
            }

            return new TestResult(subsystemName, actionName, description,
                TestResult.Status.PASSED, null, (System.nanoTime() - startNs) / 1_000_000.0,
                ctx.getAlerts(), ctx.getDataProfiles(), ctx.getDataProfilesNd());

        } catch (Exception e) {
            Throwable cause = e.getCause() != null ? e.getCause() : e;
            return new TestResult(subsystemName, actionName, description,
                TestResult.Status.FAILED, cause, (System.nanoTime() - startNs) / 1_000_000.0,
                ctx.getAlerts(), ctx.getDataProfiles(), ctx.getDataProfilesNd());
        }
    }

    // ── AdvantageKit Logging ────────────────────────────────

    private void publishResults() {
        int passed = 0;
        int failed = 0;

        List<String> passedNames = new ArrayList<>();
        List<String> failedNames = new ArrayList<>();

        for (TestResult r : results) {
            String base = LOG_PREFIX + r.getSubsystemName() + "/" + r.getActionName();

            Logger.recordOutput(base + "/Passed", r.isPassed());
            Logger.recordOutput(base + "/Status", r.getStatus().name());
            Logger.recordOutput(base + "/DurationMs", r.getDurationMs());
            Logger.recordOutput(base + "/Description", r.getDescription());
            if (r.getError() != null) {
                Logger.recordOutput(base + "/Error", r.getError().getMessage());
            }

            // Log alert count
            Logger.recordOutput(base + "/AlertCount", r.getAlerts().size());

            // Log data profile series names and sample counts
            for (var entry : r.getDataProfiles().entrySet()) {
                String profileBase = base + "/Profiles/" + entry.getKey();
                double[] values = entry.getValue().stream()
                    .mapToDouble(TestResult.DataSample::value).toArray();
                Logger.recordOutput(profileBase + "/Values", values);
            }

            if (r.isPassed()) {
                passed++;
                passedNames.add(r.getSubsystemName() + "/" + r.getActionName());
            } else {
                failed++;
                failedNames.add(r.getSubsystemName() + "/" + r.getActionName());
            }
        }

        // Summary
        Logger.recordOutput(LOG_PREFIX + "Summary/AllPassed", failed == 0);
        Logger.recordOutput(LOG_PREFIX + "Summary/TotalTests", results.size());
        Logger.recordOutput(LOG_PREFIX + "Summary/PassedCount", passed);
        Logger.recordOutput(LOG_PREFIX + "Summary/FailedCount", failed);
        Logger.recordOutput(LOG_PREFIX + "Summary/PassedList", (String[]) passedNames.toArray(new String[0]));
        Logger.recordOutput(LOG_PREFIX + "Summary/FailedList", (String[]) failedNames.toArray(new String[0]));

        if (diagServer != null) {
            Logger.recordOutput(LOG_PREFIX + "Summary/DashboardUrl", diagServer.getUrl());
        }
    }

    // ── Periodic (call from testPeriodic) ────────────────────

    /**
     * Call from {@code Robot.testPeriodic()} to keep AK Logger and
     * diagnostic server data fresh.
     */
    public void periodic() {
        if (hasRun) {
            publishResults();
            if (diagServer != null) {
                diagServer.updateResults(results);
            }
        }
    }

    // ── Queries ──────────────────────────────────────────────

    /** @return unmodifiable view of the latest results. */
    public List<TestResult> getResults() {
        return Collections.unmodifiableList(results);
    }

    /** @return true only if every recorded test passed. */
    public boolean isAllPassed() {
        if (results.isEmpty()) return false;
        return results.stream().allMatch(TestResult::isPassed);
    }

    /** @return count of discovered tests (after discovery). */
    public int getActionCount() {
        return tests.size();
    }

    // ── Helpers ──────────────────────────────────────────────

    /** Resolve display name: annotation name if set, otherwise the method name. */
    private static String resolveName(DiscoveredTest a) {
        String n = a.name();
        return (n == null || n.isEmpty()) ? a.method().getName() : n;
    }
}
