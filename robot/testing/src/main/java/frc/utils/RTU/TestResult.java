package frc.utils.RTU;

import java.time.Instant;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Immutable record that captures the outcome of a single {@link RobotAction}
 * test executed by the {@link RootTestingUtility}.
 *
 * <p>
 * Now also carries:
 * <ul>
 * <li><b>Alerts</b> -- human-readable messages attached by the test (info /
 * warning / error).</li>
 * <li><b>Data profiles</b> -- named series of timestamped numeric samples
 * (e.g. motor velocity over time) for anomaly detection / charting.</li>
 * </ul>
 */
public final class TestResult {

    public enum Status {
        PASSED, FAILED, TIMED_OUT
    }

    // ── Core fields ──────────────────────────────────────────

    private final String subsystemName;
    private final String actionName;
    private final String description;
    private final Status status;
    private final Throwable error;
    private final double durationMs;
    private final Instant timestamp;


    /** Alerts attached by the test via {@link DiagnosticContext}. */
    private final List<Alert> alerts;

    /** Named data-profile series attached by the test. */
    private final Map<String, List<DataSample>> dataProfiles;

    // ── Nested types ─────────────────────────────────────────

    /** Severity for diagnostic alerts. */
    public enum AlertLevel {
        INFO, WARNING, ERROR
    }

    /** A single alert message. */
    public record Alert(AlertLevel level, String message) {
    }

    /** A single timestamped numeric sample. */
    public record DataSample(double timestampMs, double value) {
    }


    public TestResult(String subsystemName,
            String actionName,
            String description,
            Status status,
            Throwable error,
            double durationMs,
            List<Alert> alerts,
            Map<String, List<DataSample>> dataProfiles) {
        this.subsystemName = subsystemName;
        this.actionName = actionName;
        this.description = description;
        this.status = status;
        this.error = error;
        this.durationMs = durationMs;
        this.timestamp = Instant.now();
        this.alerts = alerts != null ? List.copyOf(alerts) : List.of();
        this.dataProfiles = dataProfiles != null
                ? deepCopyProfiles(dataProfiles)
                : Map.of();
    }

    /** Backwards-compatible constructor (no alerts / profiles). */
    public TestResult(String subsystemName,
            String actionName,
            String description,
            Status status,
            Throwable error,
            double durationMs) {
        this(subsystemName, actionName, description, status, error, durationMs, null, null);
    }

    // ── Getters ──────────────────────────────────────────────

    public String getSubsystemName() {
        return subsystemName;
    }

    public String getActionName() {
        return actionName;
    }

    public String getDescription() {
        return description;
    }

    public Status getStatus() {
        return status;
    }

    public boolean isPassed() {
        return status == Status.PASSED;
    }

    public Throwable getError() {
        return error;
    }

    public double getDurationMs() {
        return durationMs;
    }

    public Instant getTimestamp() {
        return timestamp;
    }

    public List<Alert> getAlerts() {
        return alerts;
    }

    public Map<String, List<DataSample>> getDataProfiles() {
        return dataProfiles;
    }

    // ── Display ──────────────────────────────────────────────

    @Override
    public String toString() {
        String icon = switch (status) {
            case PASSED -> "PASS";
            case FAILED -> "FAIL";
            case TIMED_OUT -> "TIMEOUT";
        };
        String base = String.format("[%s] [%s] %s  (%.1f ms)",
                icon, subsystemName, actionName, durationMs);
        if (error != null) {
            base += " -- " + error.getMessage();
        }
        if (!alerts.isEmpty()) {
            base += " [" + alerts.size() + " alert(s)]";
        }
        if (!dataProfiles.isEmpty()) {
            int totalSamples = dataProfiles.values().stream().mapToInt(List::size).sum();
            base += " [" + dataProfiles.size() + " profile(s), " + totalSamples + " samples]";
        }
        return base;
    }

    // ── Helpers ──────────────────────────────────────────────

    private static Map<String, List<DataSample>> deepCopyProfiles(
            Map<String, List<DataSample>> src) {
        var copy = new LinkedHashMap<String, List<DataSample>>();
        for (var e : src.entrySet()) {
            copy.put(e.getKey(), List.copyOf(e.getValue()));
        }
        return Collections.unmodifiableMap(copy);
    }
}
