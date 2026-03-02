package frc.utils.RTU;

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

    /** A single discovered action (subsystem instance + reflective method + annotation metadata). */
    private record DiscoveredAction(
        SubsystemBase subsystem,
        Method method,
        RobotAction annotation
    ) {}

    private final List<SubsystemBase> registeredSubsystems = new ArrayList<>();
    private final List<DiscoveredAction> actions = new ArrayList<>();
    private final List<TestResult> results = new ArrayList<>();

    private static final String LOG_PREFIX = "RootTests/";
    private static final int DIAG_PORT = 5800;

    private boolean hasRun = false;
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private DiagnosticServer diagServer;

    public interface SafetyCheck {
        /** Returns an error message if safety check fails, or null if it passes. */
        String checkSafety();
    }

    private SafetyCheck safetyCheck;

    /** Set a safety check that must pass before and during test execution. */
    public void setSafetyCheck(SafetyCheck check) {
        this.safetyCheck = check;
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
        actions.clear();

        for (SubsystemBase subsystem : registeredSubsystems) {
            Class<?> clazz = subsystem.getClass();
            for (Method m : clazz.getDeclaredMethods()) {
                RobotAction ann = m.getAnnotation(RobotAction.class);
                if (ann == null) continue;

                // Validate return type
                Class<?> ret = m.getReturnType();
                if (ret != boolean.class && ret != Boolean.class && ret != void.class) {
                    System.err.println("[RootTestingUtility] Skipping " + clazz.getSimpleName()
                        + "." + m.getName() + " -- return type must be boolean or void, got "
                        + ret.getSimpleName());
                    continue;
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
                actions.add(new DiscoveredAction(subsystem, m, ann));
            }
        }

        // Sort by annotation order, then by name for stability
        actions.sort(Comparator.<DiscoveredAction>comparingInt(a -> a.annotation().order())
                               .thenComparing(a -> resolveName(a)));

        System.out.println("[RootTestingUtility] Discovered " + actions.size()
            + " @RobotAction(s) across " + registeredSubsystems.size() + " subsystem(s):");
        for (DiscoveredAction a : actions) {
            System.out.println("  - " + a.subsystem().getName() + " -> " + resolveName(a));
        }
    }

    // ── Execution ────────────────────────────────────────────

    /**
     * Runs every discovered action sequentially in a background thread, records
     * {@link TestResult}s, publishes to AK Logger, and updates
     * the diagnostic server.
     */
    public void runAll() {
        if (actions.isEmpty()) {
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

            for (DiscoveredAction action : actions) {
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
        }).start();
    }

    /**
     * Execute a single discovered action with timeout and
     * optional {@link DiagnosticContext} injection.
     */
    private TestResult executeAction(DiscoveredAction action) {
        String subsystemName = action.subsystem().getName();
        String actionName = resolveName(action);
        String description = action.annotation().description();
        long timeoutMs = (long) (action.annotation().timeoutSeconds() * 1000);

        // Create a DiagnosticContext for this test
        DiagnosticContext ctx = new DiagnosticContext();

        long startNs = System.nanoTime();

        // Determine whether the method wants a DiagnosticContext param
        boolean wantsContext = action.method().getParameterCount() == 1;

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
                            durationMs, ctx.getAlerts(), ctx.getDataProfiles());
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
                    durationMs, ctx.getAlerts(), ctx.getDataProfiles());
            }

            double durationMs = (System.nanoTime() - startNs) / 1_000_000.0;

            // void methods pass if they didn't throw
            if (action.method().getReturnType() == void.class) {
                return new TestResult(subsystemName, actionName, description,
                    TestResult.Status.PASSED, null, durationMs,
                    ctx.getAlerts(), ctx.getDataProfiles());
            }

            // boolean methods
            boolean passed = Boolean.TRUE.equals(returnValue);
            return new TestResult(subsystemName, actionName, description,
                passed ? TestResult.Status.PASSED : TestResult.Status.FAILED,
                passed ? null : new AssertionError("Returned false"),
                durationMs, ctx.getAlerts(), ctx.getDataProfiles());

        } catch (Exception e) {
            double durationMs = (System.nanoTime() - startNs) / 1_000_000.0;
            Throwable cause = e.getCause() != null ? e.getCause() : e;
            return new TestResult(subsystemName, actionName, description,
                TestResult.Status.FAILED, cause, durationMs,
                ctx.getAlerts(), ctx.getDataProfiles());
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
        Logger.recordOutput(LOG_PREFIX + "Summary/PassedList", passedNames.toArray(new String[0]));
        Logger.recordOutput(LOG_PREFIX + "Summary/FailedList", failedNames.toArray(new String[0]));

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

    /** @return count of discovered actions (after discovery). */
    public int getActionCount() {
        return actions.size();
    }

    // ── Helpers ──────────────────────────────────────────────

    /** Resolve display name: annotation name if set, otherwise the method name. */
    private static String resolveName(DiscoveredAction a) {
        String n = a.annotation().name();
        return (n == null || n.isEmpty()) ? a.method().getName() : n;
    }
}
