package frc.rtu.example;

import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.rtu.DiagnosticContext;
import frc.rtu.RobotAction;

/**
 * Example subsystem demonstrating all {@link RobotAction} features.
 *
 * <p>
 * Copy this class to your robot project, adapt the tests to your hardware,
 * and register the subsystem with
 * {@link frc.rtu.RootTestingUtility#registerSubsystem}.
 *
 * <p>
 * This class is <b>not</b> required at runtime — it is provided as
 * a reference implementation only.
 */
public class ExampleTestSubsystem extends SubsystemBase {

    public ExampleTestSubsystem() {
        // No hardware wired — purely demonstrative
    }

    // ── Example 1: Simple pass (boolean return) ───────────────

    @RobotAction(name = "1. Simple Pass", description = "Demonstrates a test that always passes by returning true.", order = 1)
    public boolean testSimplePass() {
        return true;
    }

    // ── Example 2: Simple fail (boolean return) ───────────────

    @RobotAction(name = "2. Simple Fail", description = "Demonstrates a test that always fails by returning false.", order = 2)
    public boolean testSimpleFail() {
        return false;
    }

    // ── Example 3: Void pass (no exception thrown) ────────────

    @RobotAction(name = "3. Void Pass", description = "Demonstrates a void test — passes if no exception is thrown.", order = 3)
    public void testVoidPass() {
        // do work here; throwing any exception = FAILED
    }

    // ── Example 4: Exception (FAILED status) ──────────────────

    @RobotAction(name = "4. Exception Test", description = "Demonstrates how an uncaught exception is recorded as a FAILED result.", order = 4)
    public boolean testException() {
        throw new RuntimeException("Simulated hardware fault");
    }

    // ── Example 5: Timeout (TIMED_OUT status) ─────────────────

    @RobotAction(name = "5. Timeout Test", description = "Sleeps longer than the 2-second timeout to demonstrate TIMED_OUT handling.", order = 5, timeoutSeconds = 2.0)
    public boolean testTimeout() {
        try {
            Thread.sleep(5000);
        } catch (InterruptedException e) {
            // expected — the executor cancelled us
        }
        return true;
    }

    // ── Example 6: DiagnosticContext alerts ───────────────────

    @RobotAction(name = "6. Diagnostic Alerts", description = "Shows info, warning, and error messages via DiagnosticContext.", order = 6)
    public boolean testDiagnosticAlerts(DiagnosticContext ctx) {
        ctx.info("Informational message — everything looks fine.");
        ctx.warn("Warning — value slightly out of range.");
        ctx.error("Error — this would indicate a hardware problem.");
        return true; // still passes; alerts are informational
    }

    // ── Example 7: Data profiling (charted on dashboard) ──────

    @RobotAction(name = "7. Data Profiling", description = "Records 100 sine/cosine samples — shows up as charts on the dashboard.", order = 7, timeoutSeconds = 5.0)
    public boolean testDataProfiling(DiagnosticContext ctx) {
        ctx.info("Generating 100 synthetic data samples...");

        for (int i = 0; i < 100; i++) {
            double t = i * 0.1;
            ctx.sample("Sine", Math.sin(t));
            ctx.sample("Cosine", Math.cos(t));
            try {
                Thread.sleep(10);
            } catch (InterruptedException e) {
                break;
            }
        }

        ctx.info("Data generation complete.");
        return true;
    }
}
