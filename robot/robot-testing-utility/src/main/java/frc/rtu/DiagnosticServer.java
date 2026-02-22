package frc.rtu;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import com.sun.net.httpserver.HttpServer;

import frc.rtu.DiagnosticContext.Alert;
import frc.rtu.DiagnosticContext.DataSample;

/**
 * Lightweight embedded HTTP server that serves a diagnostic dashboard for
 * the Root Testing Utility. Uses the JDK built-in
 * {@code com.sun.net.httpserver}
 * -- no external dependencies required. Works on both roboRIO and desktop
 * (sim).
 *
 * <h3>Usage</h3>
 * 
 * <pre>{@code
 * DiagnosticServer server = new DiagnosticServer(5800);
 * server.start();
 * // ... run tests ...
 * server.updateResults(results);
 * // Console: "Diagnostic dashboard: http://<ip>:5800/diag/<session-id>"
 * }</pre>
 */
public final class DiagnosticServer {

    private final int port;
    private HttpServer server;
    private List<TestResult> latestResults = List.of();
    private final String sessionId = UUID.randomUUID().toString().substring(0, 8);
    private String safetyMessage = null;

    private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")
            .withZone(ZoneId.systemDefault());

    public DiagnosticServer(int port) {
        this.port = port;
    }

    /** Start the HTTP server (non-blocking). */
    public void start() {
        try {
            server = HttpServer.create(new InetSocketAddress(port), 0);
            server.createContext("/diag/" + sessionId, exchange -> {
                String html = buildHtml();
                byte[] bytes = html.getBytes(StandardCharsets.UTF_8);
                exchange.getResponseHeaders().set("Content-Type", "text/html; charset=UTF-8");
                exchange.sendResponseHeaders(200, bytes.length);
                try (OutputStream os = exchange.getResponseBody()) {
                    os.write(bytes);
                }
            });
            // JSON API endpoint for programmatic access
            server.createContext("/diag/" + sessionId + "/json", exchange -> {
                String json = buildJson();
                byte[] bytes = json.getBytes(StandardCharsets.UTF_8);
                exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                exchange.sendResponseHeaders(200, bytes.length);
                try (OutputStream os = exchange.getResponseBody()) {
                    os.write(bytes);
                }
            });
            server.setExecutor(null);
            server.start();
        } catch (IOException e) {
            System.err.println("[DiagnosticServer] Failed to start on port " + port + ": " + e.getMessage());
        }
    }

    /** Update the results displayed on the dashboard. Thread-safe. */
    public synchronized void updateResults(List<TestResult> results) {
        this.latestResults = List.copyOf(results);
    }

    /** Set a safety message to display on the dashboard. Thread-safe. */
    public synchronized void setSafetyMessage(String message) {
        this.safetyMessage = message;
    }

    /** @return the full URL to the diagnostic dashboard. */
    public String getUrl() {
        return "http://localhost:" + port + "/diag/" + sessionId;
    }

    /** @return the session ID for this run. */
    public String getSessionId() {
        return sessionId;
    }

    /** Stop the server. */
    public void stop() {
        if (server != null) {
            server.stop(0);
        }
    }

    // ── HTML Generation ──────────────────────────────────────

    private synchronized String buildHtml() {
        var sb = new StringBuilder();
        sb.append("<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'>");
        sb.append("<meta http-equiv='refresh' content='3'>");
        sb.append("<title>RTU Diagnostic Dashboard</title>");
        sb.append("<script src='https://cdn.jsdelivr.net/npm/chart.js'></script>");
        sb.append("<style>");
        sb.append(CSS);
        sb.append("</style></head><body>");
        sb.append("<div class='container'>");

        // Header
        sb.append("<h1>RTU Diagnostic Dashboard</h1>");
        sb.append("<p class='session'>Session: <code>").append(sessionId).append("</code></p>");

        if (safetyMessage != null) {
            sb.append("<div class='safety-alert'><b>Safety Alert:</b> ");
            sb.append(esc(safetyMessage)).append("</div>");
        }

        if (latestResults.isEmpty()) {
            sb.append("<p class='waiting'>Waiting for test results...</p>");
            sb.append("</div></body></html>");
            return sb.toString();
        }

        // Summary bar
        long passed = latestResults.stream().filter(TestResult::isPassed).count();
        long failed = latestResults.size() - passed;
        String summaryClass = failed == 0 ? "summary-pass" : "summary-fail";
        sb.append("<div class='summary ").append(summaryClass).append("'>");
        sb.append("<span>Total: <b>").append(latestResults.size()).append("</b></span>");
        sb.append("<span>Passed: <b>").append(passed).append("</b></span>");
        sb.append("<span>Failed: <b>").append(failed).append("</b></span>");
        sb.append("</div>");

        // Per-test cards
        int chartIndex = 0;
        for (TestResult r : latestResults) {
            String cardClass = r.isPassed() ? "card pass" : "card fail";
            sb.append("<div class='").append(cardClass).append("'>");
            sb.append("<div class='card-header'>");
            sb.append("<span class='status-badge ").append(r.getStatus().name().toLowerCase()).append("'>");
            sb.append(r.getStatus().name()).append("</span>");
            sb.append("<h2>").append(esc(r.getActionName())).append("</h2>");
            sb.append("<span class='subsystem'>").append(esc(r.getSubsystemName())).append("</span>");
            sb.append("</div>");

            sb.append("<p class='desc'>").append(esc(r.getDescription())).append("</p>");
            sb.append("<p class='meta'>Duration: <b>").append(String.format("%.2f", r.getDurationMs()));
            sb.append(" ms</b> | Timestamp: ").append(TIME_FMT.format(r.getTimestamp())).append("</p>");

            // Error
            if (r.getError() != null) {
                sb.append("<div class='error-box'><b>Error:</b> ");
                sb.append(esc(r.getError().getMessage())).append("</div>");
            }

            // Alerts
            if (!r.getAlerts().isEmpty()) {
                sb.append("<div class='alerts'><h3>Alerts</h3><ul>");
                for (Alert a : r.getAlerts()) {
                    String alertClass = a.level().name().toLowerCase();
                    sb.append("<li class='alert-").append(alertClass).append("'>");
                    sb.append("<b>[").append(a.level().name()).append("]</b> ");
                    sb.append(esc(a.message())).append("</li>");
                }
                sb.append("</ul></div>");
            }

            // Data profile charts
            if (!r.getDataProfiles().isEmpty()) {
                sb.append("<div class='profiles'><h3>Data Profiles</h3>");
                for (Map.Entry<String, List<DataSample>> entry : r.getDataProfiles().entrySet()) {
                    String canvasId = "chart_" + chartIndex++;
                    sb.append("<div class='chart-container'>");
                    sb.append("<canvas id='").append(canvasId).append("'></canvas>");
                    sb.append("</div>");

                    List<DataSample> samples = entry.getValue();
                    sb.append("<script>");
                    sb.append("new Chart(document.getElementById('").append(canvasId).append("'),{");
                    sb.append("type:'line',data:{labels:[");
                    for (int i = 0; i < samples.size(); i++) {
                        if (i > 0)
                            sb.append(",");
                        sb.append(String.format("%.1f", samples.get(i).timestampMs()));
                    }
                    sb.append("],datasets:[{label:'").append(esc(entry.getKey())).append("',");
                    sb.append("data:[");
                    for (int i = 0; i < samples.size(); i++) {
                        if (i > 0)
                            sb.append(",");
                        sb.append(String.format("%.4f", samples.get(i).value()));
                    }
                    sb.append("],borderColor:'#3b82f6',backgroundColor:'rgba(59,130,246,0.1)',");
                    sb.append("fill:true,tension:0.3,pointRadius:2}]},");
                    sb.append("options:{responsive:true,plugins:{title:{display:true,text:'");
                    sb.append(esc(entry.getKey())).append("'}},");
                    sb.append("scales:{x:{title:{display:true,text:'Time (ms)'}},");
                    sb.append("y:{title:{display:true,text:'Value'}}}}}");
                    sb.append(");</script>");
                }
                sb.append("</div>");
            }

            sb.append("</div>"); // card
        }

        sb.append("</div></body></html>");
        return sb.toString();
    }

    // ── JSON Generation ──────────────────────────────────────

    private synchronized String buildJson() {
        var sb = new StringBuilder();
        sb.append("{\"session\":\"").append(sessionId).append("\"");
        if (safetyMessage != null) {
            sb.append(",\"safetyMessage\":\"").append(jsonEsc(safetyMessage)).append("\"");
        }
        sb.append(",\"results\":[");
        for (int i = 0; i < latestResults.size(); i++) {
            if (i > 0)
                sb.append(",");
            TestResult r = latestResults.get(i);
            sb.append("{\"subsystem\":\"").append(jsonEsc(r.getSubsystemName())).append("\"");
            sb.append(",\"action\":\"").append(jsonEsc(r.getActionName())).append("\"");
            sb.append(",\"status\":\"").append(r.getStatus().name()).append("\"");
            sb.append(",\"passed\":").append(r.isPassed());
            sb.append(",\"durationMs\":").append(String.format("%.2f", r.getDurationMs()));
            sb.append(",\"description\":\"").append(jsonEsc(r.getDescription())).append("\"");
            if (r.getError() != null) {
                sb.append(",\"error\":\"").append(jsonEsc(r.getError().getMessage())).append("\"");
            }
            // Alerts
            sb.append(",\"alerts\":[");
            for (int j = 0; j < r.getAlerts().size(); j++) {
                if (j > 0)
                    sb.append(",");
                Alert a = r.getAlerts().get(j);
                sb.append("{\"level\":\"").append(a.level().name()).append("\"");
                sb.append(",\"message\":\"").append(jsonEsc(a.message())).append("\"}");
            }
            sb.append("]");
            // Data profiles
            sb.append(",\"dataProfiles\":{");
            int pIdx = 0;
            for (var entry : r.getDataProfiles().entrySet()) {
                if (pIdx++ > 0)
                    sb.append(",");
                sb.append("\"").append(jsonEsc(entry.getKey())).append("\":[");
                for (int j = 0; j < entry.getValue().size(); j++) {
                    if (j > 0)
                        sb.append(",");
                    DataSample s = entry.getValue().get(j);
                    sb.append("{\"t\":").append(String.format("%.2f", s.timestampMs()));
                    sb.append(",\"v\":").append(String.format("%.4f", s.value())).append("}");
                }
                sb.append("]");
            }
            sb.append("}}");
        }
        sb.append("]}");
        return sb.toString();
    }

    // ── Utilities ────────────────────────────────────────────

    private static String esc(String s) {
        if (s == null)
            return "";
        return s.replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    private static String jsonEsc(String s) {
        if (s == null)
            return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r");
    }

    // ── CSS ──────────────────────────────────────────────────

    private static final String CSS = """
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                       background: #0f172a; color: #e2e8f0; padding: 24px; }
                .container { max-width: 960px; margin: 0 auto; }
                h1 { color: #f8fafc; margin-bottom: 4px; font-size: 1.8rem; }
                .session { color: #94a3b8; margin-bottom: 20px; }
                .session code { background: #1e293b; padding: 2px 8px; border-radius: 4px; }
                .waiting { color: #fbbf24; font-size: 1.2rem; margin-top: 40px; text-align: center; }

                .summary { display: flex; gap: 32px; padding: 16px 24px; border-radius: 8px;
                           margin-bottom: 24px; font-size: 1.1rem; }
                .summary-pass { background: #065f46; border: 1px solid #10b981; }
                .summary-fail { background: #7f1d1d; border: 1px solid #ef4444; }

                .card { background: #1e293b; border-radius: 8px; padding: 20px; margin-bottom: 16px;
                        border-left: 4px solid #475569; }
                .card.pass { border-left-color: #10b981; }
                .card.fail { border-left-color: #ef4444; }
                .card-header { display: flex; align-items: center; gap: 12px; margin-bottom: 8px; }
                .card-header h2 { font-size: 1.15rem; color: #f1f5f9; flex: 1; }
                .subsystem { color: #94a3b8; font-size: 0.85rem; background: #334155;
                             padding: 2px 10px; border-radius: 12px; }
                .status-badge { font-size: 0.75rem; font-weight: 700; padding: 3px 10px;
                                border-radius: 4px; text-transform: uppercase; }
                .status-badge.passed { background: #10b981; color: #022c22; }
                .status-badge.failed { background: #ef4444; color: #450a0a; }
                .status-badge.timed_out { background: #f59e0b; color: #451a03; }

                .desc { color: #94a3b8; margin-bottom: 6px; }
                .meta { color: #64748b; font-size: 0.85rem; margin-bottom: 12px; }
                .error-box { background: #450a0a; border: 1px solid #ef4444; color: #fca5a5;
                             padding: 10px 14px; border-radius: 6px; margin-bottom: 12px;
                             font-family: monospace; font-size: 0.9rem; }

                .alerts h3, .profiles h3 { color: #cbd5e1; font-size: 0.95rem; margin-bottom: 8px; }
                .alerts ul { list-style: none; }
                .alerts li { padding: 4px 0; font-size: 0.9rem; border-bottom: 1px solid #334155; }
                .alert-info { color: #38bdf8; }
                .alert-warning { color: #fbbf24; }
                .alert-error { color: #f87171; }

                .safety-alert { background: #7f1d1d; border: 2px solid #ef4444; color: #fca5a5;
                                padding: 16px; border-radius: 8px; margin-bottom: 24px;
                                font-size: 1.2rem; text-align: center; font-weight: bold; }

                .chart-container { background: #0f172a; border-radius: 6px; padding: 12px;
                                   margin-bottom: 12px; max-height: 300px; }
                canvas { max-height: 260px; }
            """;
}
