package frc.robot.utils.RTU;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import frc.robot.utils.RTU.TestResult.Alert;
import frc.robot.utils.RTU.TestResult.AlertLevel;
import frc.robot.utils.RTU.TestResult.DataSample;

/**
 * Mutable context object passed into {@code @RobotAction} methods that accept
 * it.  Lets the test author:
 * <ul>
 *   <li>Record <b>alerts</b> (info / warning / error) that surface on the
 *       diagnostic dashboard.</li>
 *   <li>Record <b>data-profile samples</b> (named series of timestamped
 *       numeric values) for motor speed profiling, acceleration analysis,
 *       anomaly detection, etc.</li>
 * </ul>
 *
 * <h3>Usage inside a {@code @RobotAction} method</h3>
 * <pre>{@code
 * @RobotAction(name = "Motor Profile Test")
 * public boolean testMotorProfile(DiagnosticContext ctx) {
 *     ctx.info("Starting motor ramp-up");
 *     for (int i = 0; i < 50; i++) {
 *         double velocity = readMotorVelocity();
 *         ctx.sample("Velocity (RPM)", velocity);
 *         Thread.sleep(20);
 *     }
 *     double finalVelocity = readMotorVelocity();
 *     if (finalVelocity < 1000) {
 *         ctx.error("Motor did not reach target speed: " + finalVelocity);
 *         return false;
 *     }
 *     ctx.info("Final velocity: " + finalVelocity + " RPM");
 *     return true;
 * }
 * }</pre>
 *
 * The utility automatically snapshots the context after the method returns and
 * bakes the alerts + data profiles into the resulting {@link TestResult}.
 */
public final class DiagnosticContext {

    private final List<Alert> alerts = new ArrayList<>();
    private final Map<String, List<DataSample>> dataProfiles = new LinkedHashMap<>();

    /** Epoch nanos captured at construction, used for relative sample timestamps. */
    private final long epochNs = System.nanoTime();

    // ── Alerts ───────────────────────────────────────────────

    /** Record an informational message. */
    public void info(String message) {
        alerts.add(new Alert(AlertLevel.INFO, message));
    }

    /** Record a warning. */
    public void warn(String message) {
        alerts.add(new Alert(AlertLevel.WARNING, message));
    }

    /** Record an error message. */
    public void error(String message) {
        alerts.add(new Alert(AlertLevel.ERROR, message));
    }

    // ── Data Profiling ───────────────────────────────────────

    /**
     * Record a timestamped sample for a named data series.
     * The timestamp is automatically calculated relative to the
     * start of this context (i.e. the start of the test).
     *
     * @param seriesName human-readable name, e.g. "Velocity (RPM)"
     * @param value      the numeric sample
     */
    public void sample(String seriesName, double value) {
        double relativeMs = (System.nanoTime() - epochNs) / 1_000_000.0;
        dataProfiles
            .computeIfAbsent(seriesName, k -> new ArrayList<>())
            .add(new DataSample(relativeMs, value));
    }

    /**
     * Record a sample with an explicit relative timestamp.
     *
     * @param seriesName human-readable name
     * @param timestampMs relative milliseconds from test start
     * @param value       the numeric sample
     */
    public void sample(String seriesName, double timestampMs, double value) {
        dataProfiles
            .computeIfAbsent(seriesName, k -> new ArrayList<>())
            .add(new DataSample(timestampMs, value));
    }

    // ── Snapshot ─────────────────────────────────────────────

    /** @return immutable copy of all alerts recorded so far. */
    public List<Alert> getAlerts() {
        return List.copyOf(alerts);
    }

    /** @return immutable deep copy of all data profiles recorded so far. */
    public Map<String, List<DataSample>> getDataProfiles() {
        var copy = new LinkedHashMap<String, List<DataSample>>();
        for (var e : dataProfiles.entrySet()) {
            copy.put(e.getKey(), List.copyOf(e.getValue()));
        }
        return copy;
    }
}
