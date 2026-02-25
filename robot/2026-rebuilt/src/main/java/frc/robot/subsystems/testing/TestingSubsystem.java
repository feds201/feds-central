package frc.robot.subsystems.testing;

import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.utils.RTU.DiagnosticContext;
import frc.robot.utils.RTU.RobotAction;

public class TestingSubsystem extends SubsystemBase {

    public TestingSubsystem() {
        // Constructor
    }

    @RobotAction(
        name = "1. Simple Pass",
        description = "A test that simply returns true to demonstrate a passing test.",
        order = 1
    )
    public boolean testSimplePass() {
        return true;
    }

    @RobotAction(
        name = "2. Simple Fail",
        description = "A test that simply returns false to demonstrate a failing test.",
        order = 2
    )
    public boolean testSimpleFail() {
        return false;
    }

    @RobotAction(
        name = "3. Exception Test",
        description = "A test that throws an exception to demonstrate error handling.",
        order = 3
    )
    public boolean testException() {
        throw new RuntimeException("This is a simulated exception for testing purposes.");
    }

    @RobotAction(
        name = "4. Timeout Test",
        description = "A test that sleeps longer than its timeout to demonstrate timeout handling.",
        order = 4,
        timeoutSeconds = 2.0
    )
    public boolean testTimeout() {
        try {
            Thread.sleep(3000); // Sleep for 3 seconds, timeout is 2 seconds
        } catch (InterruptedException e) {
            // Expected when interrupted by timeout
        }
        return true;
    }

    @RobotAction(
        name = "5. Diagnostic Alerts",
        description = "A test that logs info, warnings, and errors using DiagnosticContext.",
        order = 5
    )
    public boolean testDiagnosticAlerts(DiagnosticContext ctx) {
        ctx.info("This is an informational message.");
        ctx.warn("This is a warning message.");
        ctx.error("This is an error message.");
        return true;
    }

    @RobotAction(
        name = "6. Data Profiling",
        description = "A test that generates a sine wave and cosine wave to demonstrate data profiling charts.",
        order = 6,
        timeoutSeconds = 5.0
    )
    public boolean testDataProfiling(DiagnosticContext ctx) {
        ctx.info("Generating 100 samples of sine and cosine waves...");
        
        for (int i = 0; i < 100; i++) {
            double time = i * 0.1;
            double sineValue = Math.sin(time);
            double cosineValue = Math.cos(time);
            
            ctx.sample("Sine Wave", sineValue);
            ctx.sample("Cosine Wave", cosineValue);
            
            try {
                Thread.sleep(20); // Simulate some work
            } catch (InterruptedException e) {
                break;
            }
        }
        
        ctx.info("Data generation complete.");
        return true;
    }
}
