package frc.rtu;

import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

import frc.rtu.DiagnosticContext.Alert;
import frc.rtu.DiagnosticContext.AlertLevel;

/**
 * Unit tests for {@link TestResult}.
 * These run entirely on the JVM — no robot hardware or WPILib runtime needed.
 */
class TestResultTest {

    // ── Status helpers ────────────────────────────────────────

    @Test
    void passed_result_isPassed() {
        var r = new TestResult("Shooter", "Spin Up", "Verify flywheel",
                TestResult.Status.PASSED, null, 42.0);
        assertTrue(r.isPassed());
        assertEquals(TestResult.Status.PASSED, r.getStatus());
    }

    @Test
    void failed_result_isNotPassed() {
        var r = new TestResult("Intake", "Motor Check", "Speed test",
                TestResult.Status.FAILED, new AssertionError("Returned false"), 10.0);
        assertFalse(r.isPassed());
        assertEquals(TestResult.Status.FAILED, r.getStatus());
        assertNotNull(r.getError());
    }

    @Test
    void timedOut_result_hasCorrectStatus() {
        var r = new TestResult("Climber", "Extend", "Extend test",
                TestResult.Status.TIMED_OUT, new RuntimeException("timed out"), 5000.0);
        assertFalse(r.isPassed());
        assertEquals(TestResult.Status.TIMED_OUT, r.getStatus());
    }

    // ── Alert immutability ────────────────────────────────────

    @Test
    void alerts_list_is_immutable() {
        var alerts = new ArrayList<Alert>();
        alerts.add(new Alert(AlertLevel.INFO, "hello"));

        var r = new TestResult("Sub", "action", "desc",
                TestResult.Status.PASSED, null, 1.0, alerts, null);

        assertThrows(UnsupportedOperationException.class,
                () -> r.getAlerts().add(new Alert(AlertLevel.ERROR, "boom")));
    }

    @Test
    void alerts_original_mutation_does_not_affect_result() {
        var alerts = new ArrayList<Alert>();
        alerts.add(new Alert(AlertLevel.WARNING, "first"));

        var r = new TestResult("Sub", "action", "desc",
                TestResult.Status.PASSED, null, 1.0, alerts, null);

        alerts.add(new Alert(AlertLevel.ERROR, "added after"));
        assertEquals(1, r.getAlerts().size(), "Original mutation must not affect the result");
    }

    // ── Data profiles ─────────────────────────────────────────

    @Test
    void dataProfiles_are_captured() {
        var ctx = new DiagnosticContext();
        ctx.sample("Velocity", 100.0);
        ctx.sample("Velocity", 200.0);
        ctx.sample("Current", 5.5);

        var r = new TestResult("Drive", "Motor Ramp", "Ramp test",
                TestResult.Status.PASSED, null, 500.0,
                ctx.getAlerts(), ctx.getDataProfiles());

        assertEquals(2, r.getDataProfiles().size());
        assertEquals(2, r.getDataProfiles().get("Velocity").size());
        assertEquals(1, r.getDataProfiles().get("Current").size());
    }

    @Test
    void null_alerts_and_profiles_become_empty_collections() {
        var r = new TestResult("Sub", "action", "desc",
                TestResult.Status.PASSED, null, 0.0, null, null);
        assertNotNull(r.getAlerts());
        assertTrue(r.getAlerts().isEmpty());
        assertNotNull(r.getDataProfiles());
        assertTrue(r.getDataProfiles().isEmpty());
    }

    // ── toString ─────────────────────────────────────────────

    @Test
    void toString_contains_status_and_name() {
        var r = new TestResult("Shooter", "Flywheel", "",
                TestResult.Status.PASSED, null, 123.4);
        String s = r.toString();
        assertTrue(s.contains("PASS"), "Expected PASS in: " + s);
        assertTrue(s.contains("Shooter"), "Expected subsystem name in: " + s);
        assertTrue(s.contains("Flywheel"), "Expected action name in: " + s);
    }
}
