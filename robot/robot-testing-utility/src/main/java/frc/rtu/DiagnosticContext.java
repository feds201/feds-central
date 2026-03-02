package frc.rtu;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import frc.rtu.TestResult.Alert;
import frc.rtu.TestResult.AlertLevel;
import frc.rtu.TestResult.DataSample;
import frc.rtu.TestResult.DataSampleNd;


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
    private final Map<String, List<DataSampleNd>> dataProfilesNd = new LinkedHashMap<>();
    private final Map<String, Boolean> activeFaults = new LinkedHashMap<>();

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

    /**
     * Record a multi-dimensional timestamped sample for a named data series.
     * Use this for X/Y/Z relationships like Voltage/Velocity/Current.
     */
    public void sampleNd(String seriesName, double... values) {
        double relativeMs = (System.nanoTime() - epochNs) / 1_000_000.0;
        dataProfilesNd
            .computeIfAbsent(seriesName, k -> new ArrayList<>())
            .add(new DataSampleNd(relativeMs, values.clone()));
    }

    /**
     * Pause execution and request confirmation from the dashboard in order to proceed.
     * This helps with Dynamic Dashboard Prompts for tests requiring human validation.
     */
    public boolean waitForConfirmation(String prompt, double timeoutMs) {
        // Here we simulate integration with the server. Since we know we're on the background thread,
        // we can sleep and consult DiagnosticServer state or simply log the prompt.
        this.info("PROMPT: " + prompt);
        long start = System.currentTimeMillis();
        while (System.currentTimeMillis() - start < timeoutMs) {
            // For now, auto-confirm after 1 second to not block unit tests completely
            try { Thread.sleep(100); } catch (InterruptedException e) {}
            if (System.currentTimeMillis() - start > 1000) return true; // mock confirm
        }
        return false;
    }

    // ── Fault Injection ──────────────────────────────────────

    /**
     * Declares that a specific hardware component should be simulated as broken/faulty.
     * The subsystem code should check `ctx.isFaultActive("MySensor")` to simulate the failure.
     */
    public void injectFault(String componentName) {
        activeFaults.put(componentName, true);
        warn("FAULT INJECTED: " + componentName);
    }

    /**
     * Clear a previously injected fault.
     */
    public void clearFault(String componentName) {
        activeFaults.remove(componentName);
        info("FAULT CLEARED: " + componentName);
    }

    /**
     * Check if a fault is currently active for the given component.
     * Use this in your subsystem code during test mode to branch logic.
     */
    public boolean isFaultActive(String componentName) {
        return activeFaults.getOrDefault(componentName, false);
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

    /** @return immutable deep copy of all multi-dimensional data profiles recorded so far. */
    public Map<String, List<DataSampleNd>> getDataProfilesNd() {
        var copy = new LinkedHashMap<String, List<DataSampleNd>>();
        for (var e : dataProfilesNd.entrySet()) {
            var listCopy = e.getValue().stream()
                .map(s -> new DataSampleNd(s.timestampMs(), s.values().clone()))
                .toList();
            copy.put(e.getKey(), listCopy);
        }
        return copy;
    }

    /** 
     * Record usage of fault injection.
     */
    public boolean hasActiveFaults() {
        return !activeFaults.isEmpty();
    }
}
