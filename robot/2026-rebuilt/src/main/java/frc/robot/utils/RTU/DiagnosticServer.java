package frc.robot.utils.RTU;


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

import frc.robot.utils.RTU.TestResult.Alert;
import frc.robot.utils.RTU.TestResult.DataSample;



public final class DiagnosticServer {

    private final int port;
    private HttpServer server;
    private List<TestResult> latestResults = List.of();
    private final List<CollectedSample> collectedSamples = new java.util.ArrayList<>();
    private final String sessionId = UUID.randomUUID().toString().substring(0, 8);
    private String safetyMessage = null;

    private static class CollectedSample {
        final long t;
        final double velocityRps;
        final double hoodDeg;
        final double distanceM;

        CollectedSample(long t, double velocityRps, double hoodDeg, double distanceM) {
            this.t = t;
            this.velocityRps = velocityRps;
            this.hoodDeg = hoodDeg;
            this.distanceM = distanceM;
        }
    }

    private static final DateTimeFormatter TIME_FMT =
        DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")
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
            // Telemetry JSON endpoint (live values published by robotPeriodic)
            server.createContext("/diag/" + sessionId + "/telemetry", exchange -> {
                String json = String.format(
                    "{\"shooterRps\":%.4f,\"hoodDeg\":%.3f,\"distM\":%.3f}",
                    frc.robot.utils.RTU.TelemetryPublisher.getShooterVelocityRps(),
                    frc.robot.utils.RTU.TelemetryPublisher.getHoodAngleDeg(),
                    frc.robot.utils.RTU.TelemetryPublisher.getDistanceToHubM()
                );
                byte[] bytes = json.getBytes(StandardCharsets.UTF_8);
                exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                exchange.sendResponseHeaders(200, bytes.length);
                try (OutputStream os = exchange.getResponseBody()) { os.write(bytes); }
            });

            // Collector: record a 'hit' (POST) — snapshot current telemetry and store it
            server.createContext("/diag/" + sessionId + "/collector/hit", exchange -> {
                if (!"POST".equals(exchange.getRequestMethod())) {
                    exchange.sendResponseHeaders(405, -1);
                    return;
                }
                double v = frc.robot.utils.RTU.TelemetryPublisher.getShooterVelocityRps();
                double h = frc.robot.utils.RTU.TelemetryPublisher.getHoodAngleDeg();
                double d = frc.robot.utils.RTU.TelemetryPublisher.getDistanceToHubM();
                CollectedSample s = new CollectedSample(System.currentTimeMillis(), v, h, d);
                synchronized (collectedSamples) { collectedSamples.add(s); }
                String resp = "OK";
                byte[] bytes = resp.getBytes(StandardCharsets.UTF_8);
                exchange.sendResponseHeaders(200, bytes.length);
                try (OutputStream os = exchange.getResponseBody()) { os.write(bytes); }
            });

            // Collector: list samples (JSON)
            server.createContext("/diag/" + sessionId + "/collector/list", exchange -> {
                StringBuilder jb = new StringBuilder();
                jb.append("[");
                synchronized (collectedSamples) {
                    for (int i = 0; i < collectedSamples.size(); i++) {
                        if (i > 0) jb.append(',');
                        CollectedSample s = collectedSamples.get(i);
                        jb.append(String.format("{\"t\":%d,\"v\":%.4f,\"h\":%.3f,\"d\":%.3f}",
                            s.t, s.velocityRps, s.hoodDeg, s.distanceM));
                    }
                }
                jb.append("]");
                byte[] bytes = jb.toString().getBytes(StandardCharsets.UTF_8);
                exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                exchange.sendResponseHeaders(200, bytes.length);
                try (OutputStream os = exchange.getResponseBody()) { os.write(bytes); }
            });

            // Collector: CSV download
            server.createContext("/diag/" + sessionId + "/collector/csv", exchange -> {
                StringBuilder cb = new StringBuilder();
                cb.append("timestamp_ms,shooter_rps,hood_deg,distance_m\n");
                synchronized (collectedSamples) {
                    for (CollectedSample s : collectedSamples) {
                        cb.append(String.format("%d,%.6f,%.4f,%.4f\n", s.t, s.velocityRps, s.hoodDeg, s.distanceM));
                    }
                }
                byte[] bytes = cb.toString().getBytes(StandardCharsets.UTF_8);
                exchange.getResponseHeaders().set("Content-Type", "text/csv; charset=UTF-8");
                exchange.getResponseHeaders().set("Content-Disposition", "attachment; filename=collected_samples.csv");
                exchange.sendResponseHeaders(200, bytes.length);
                try (OutputStream os = exchange.getResponseBody()) { os.write(bytes); }
            });
            // Collector: set shooter/hood directly via query params
            server.createContext("/diag/" + sessionId + "/collector/set", exchange -> {
                try {
                    var q = exchange.getRequestURI().getQuery();
                    double velocity = Double.NaN;
                    double hood = Double.NaN;
                    if (q != null) {
                        for (String part : q.split("&")) {
                            String[] kv = part.split("=");
                            if (kv.length != 2) continue;
                            String k = kv[0];
                            String v = java.net.URLDecoder.decode(kv[1], StandardCharsets.UTF_8);
                            try {
                                if (k.equals("velocity")) velocity = Double.parseDouble(v);
                                if (k.equals("hoodDeg")) hood = Double.parseDouble(v);
                            } catch (NumberFormatException nfe) { }
                        }
                    }
                    var rc = frc.robot.RobotContainer.getInstance();
                    if (rc != null) {
                        if (!Double.isNaN(velocity)) rc.setShooterVelocityRps(velocity);
                        if (!Double.isNaN(hood)) rc.setHoodAngleDeg(hood);
                    }
                    String resp = "{\"ok\":true}\n";
                    byte[] bytes = resp.getBytes(StandardCharsets.UTF_8);
                    exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                    exchange.sendResponseHeaders(200, bytes.length);
                    try (OutputStream os = exchange.getResponseBody()) { os.write(bytes); }
                } catch (Exception e) {
                    exchange.sendResponseHeaders(500, -1);
                }
            });

            // Collector: automatic sweep
            server.createContext("/diag/" + sessionId + "/collector/auto", exchange -> {
                try {
                    var q = exchange.getRequestURI().getQuery();
                    double min = Double.NaN, max = Double.NaN, step = Double.NaN, hoodDeg = Double.NaN;
                    int holdMs = 1000;
                    if (q != null) {
                        for (String part : q.split("&")) {
                            String[] kv = part.split("=");
                            if (kv.length != 2) continue;
                            String k = kv[0];
                            String v = java.net.URLDecoder.decode(kv[1], StandardCharsets.UTF_8);
                            try {
                                if (k.equals("min")) min = Double.parseDouble(v);
                                if (k.equals("max")) max = Double.parseDouble(v);
                                if (k.equals("step")) step = Double.parseDouble(v);
                                if (k.equals("hoodDeg")) hoodDeg = Double.parseDouble(v);
                                if (k.equals("holdMs")) holdMs = Integer.parseInt(v);
                            } catch (NumberFormatException nfe) { }
                        }
                    }
                    var rc = frc.robot.RobotContainer.getInstance();
                    if (rc != null && !Double.isNaN(min) && !Double.isNaN(max) && !Double.isNaN(step)) {
                        rc.startAutoSweep(min, max, step, Double.isNaN(hoodDeg) ? 0.0 : hoodDeg, holdMs);
                        String resp = "{\"started\":true}\n";
                        byte[] bytes = resp.getBytes(StandardCharsets.UTF_8);
                        exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                        exchange.sendResponseHeaders(200, bytes.length);
                        try (OutputStream os = exchange.getResponseBody()) { os.write(bytes); }
                        return;
                    }
                    exchange.sendResponseHeaders(400, -1);
                } catch (Exception e) {
                    exchange.sendResponseHeaders(500, -1);
                }
            });

            // Collector: auto stop
            server.createContext("/diag/" + sessionId + "/collector/auto/stop", exchange -> {
                var rc = frc.robot.RobotContainer.getInstance();
                if (rc != null) rc.stopAutoSweep();
                String resp = "{\"stopped\":true}\n";
                byte[] bytes = resp.getBytes(StandardCharsets.UTF_8);
                exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                exchange.sendResponseHeaders(200, bytes.length);
                try (OutputStream os = exchange.getResponseBody()) { os.write(bytes); }
            });

            // Collector: auto status
            server.createContext("/diag/" + sessionId + "/collector/auto/status", exchange -> {
                var rc = frc.robot.RobotContainer.getInstance();
                boolean running = rc != null && rc.isAutoRunning();
                double current = rc != null ? rc.getAutoCurrent() : 0.0;
                String resp = String.format("{\"running\":%b,\"current\":%.4f}\n", running, current);
                byte[] bytes = resp.getBytes(StandardCharsets.UTF_8);
                exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                exchange.sendResponseHeaders(200, bytes.length);
                try (OutputStream os = exchange.getResponseBody()) { os.write(bytes); }
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
        sb.append("<title>FEDS 201 - Root Test Diagnostics</title>");
        sb.append("<script src='https://cdn.jsdelivr.net/npm/chart.js'></script>");
        sb.append("<style>");
        sb.append(CSS);
        sb.append("</style></head><body>");
        sb.append("<div class='container'>");

        // Header
        sb.append("<h1>FEDS 201 Root Test Diagnostics</h1>");
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

        // Collector UI: live telemetry and hit recording
        sb.append("<div class='card'>");
        sb.append("<h2>Interactive Data Collector</h2>");
        sb.append("<p>Live telemetry and operator-driven sample recording. Click 'Record Hit' when the ball goes in.</p>");
        sb.append("<div style='display:flex;gap:12px;align-items:center;margin-bottom:12px;'>");
        sb.append("<div>Shooter RPS: <b id='tel_shooter'>--</b></div>");
        sb.append("<div>Hood (deg): <b id='tel_hood'>--</b></div>");
        sb.append("<div>Distance (m): <b id='tel_dist'>--</b></div>");
        sb.append("</div>");
        sb.append("<div style='display:flex;gap:12px;margin-bottom:12px;'>");
        sb.append("<button id='btn_record'>Record Hit</button>");
        sb.append("<a id='btn_csv' href='/diag/").append(sessionId).append("/collector/csv' target='_blank'><button>Download CSV</button></a>");
        sb.append("</div>");
    sb.append("<div style='display:flex;gap:12px;align-items:center;margin-bottom:12px;'>");
    sb.append("<label>min RPS: <input id='in_min' style='width:90px' value='0'></label>");
    sb.append("<label>max RPS: <input id='in_max' style='width:90px' value='60'></label>");
    sb.append("<label>step: <input id='in_step' style='width:70px' value='5'></label>");
    sb.append("<label>hood (deg): <input id='in_hood' style='width:70px' value='15'></label>");
    sb.append("<label>hold(ms): <input id='in_hold' style='width:70px' value='1500'></label>");
    sb.append("<button id='btn_start_auto'>Start Sweep</button>");
    sb.append("<button id='btn_stop_auto'>Stop Sweep</button>");
    sb.append("<div id='auto_status' style='margin-left:12px;color:#93c5fd'>Status: idle</div>");
    sb.append("</div>");
        sb.append("<div>");
        sb.append("<h3>Recorded Samples</h3>");
        sb.append("<table id='samples_tbl' style='width:100%;border-collapse:collapse;'><thead><tr><th>t</th><th>shooter_rps</th><th>hood_deg</th><th>distance_m</th></tr></thead><tbody></tbody></table>");
        sb.append("</div>");
        sb.append("</div>");

        // Client-side JS for polling telemetry and recording hits
        sb.append("<script>");
        sb.append("const base = '/diag/").append(sessionId).append("';\n");
        sb.append("async function pollTelemetry(){try{const r=await fetch(base+'/telemetry'); if(r.ok){const j=await r.json();document.getElementById('tel_shooter').textContent=j.shooterRps.toFixed(3);document.getElementById('tel_hood').textContent=j.hoodDeg.toFixed(2);document.getElementById('tel_dist').textContent=j.distM.toFixed(2);} }catch(e){} finally{setTimeout(pollTelemetry,250);} }\n");
    sb.append("async function recordHit(){ try{ const r=await fetch(base+'/collector/hit',{method:'POST'}); if(r.ok){ await refreshList(); } }catch(e){ alert('Record failed: '+e); } }\n");
    sb.append("async function refreshList(){ try{ const r=await fetch(base+'/collector/list'); if(!r.ok) return; const arr=await r.json(); const tb=document.querySelector('#samples_tbl tbody'); tb.innerHTML=''; for(const s of arr){ const tr=document.createElement('tr'); tr.innerHTML=`<td>${s.t}</td><td>${s.v.toFixed(4)}</td><td>${s.h.toFixed(3)}</td><td>${s.d.toFixed(3)}</td>`; tb.appendChild(tr);} }catch(e){} }\n");
    sb.append("async function startAuto(){ try{ const min=document.getElementById('in_min').value; const max=document.getElementById('in_max').value; const step=document.getElementById('in_step').value; const hood=document.getElementById('in_hood').value; const hold=document.getElementById('in_hold').value; const q='?min='+encodeURIComponent(min)+'&max='+encodeURIComponent(max)+'&step='+encodeURIComponent(step)+'&hoodDeg='+encodeURIComponent(hood)+'&holdMs='+encodeURIComponent(hold); const r=await fetch(base+'/collector/auto'+q); if(r.ok){ document.getElementById('auto_status').textContent='Status: running'; pollAutoStatus(); } else { alert('Failed to start'); } }catch(e){ alert('Start failed:'+e);} }\n");
    sb.append("async function stopAuto(){ try{ await fetch(base+'/collector/auto/stop'); document.getElementById('auto_status').textContent='Status: stopped'; }catch(e){ alert('Stop failed:'+e);} }\n");
    sb.append("async function pollAutoStatus(){ try{ const r=await fetch(base+'/collector/auto/status'); if(r.ok){ const j=await r.json(); document.getElementById('auto_status').textContent='Status: '+(j.running?('running @ '+j.current.toFixed(3)+' rps'):'idle'); } }catch(e){} finally{ setTimeout(pollAutoStatus,1000); } }\n");
    sb.append("document.getElementById('btn_record').addEventListener('click', ()=>recordHit());\n");
    sb.append("document.getElementById('btn_start_auto').addEventListener('click', ()=>startAuto());\n");
    sb.append("document.getElementById('btn_stop_auto').addEventListener('click', ()=>stopAuto());\n");
    sb.append("window.addEventListener('load', ()=>{ pollTelemetry(); refreshList(); pollAutoStatus(); });");
    sb.append("</script>");
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

                    // Build chart data
                    List<DataSample> samples = entry.getValue();
                    sb.append("<script>");
                    sb.append("new Chart(document.getElementById('").append(canvasId).append("'),{");
                    sb.append("type:'line',data:{labels:[");
                    for (int i = 0; i < samples.size(); i++) {
                        if (i > 0) sb.append(",");
                        sb.append(String.format("%.1f", samples.get(i).timestampMs()));
                    }
                    sb.append("],datasets:[{label:'").append(esc(entry.getKey())).append("',");
                    sb.append("data:[");
                    for (int i = 0; i < samples.size(); i++) {
                        if (i > 0) sb.append(",");
                        sb.append(String.format("%.4f", samples.get(i).value()));
                    }
                    sb.append("],borderColor:'#3b82f6',backgroundColor:'rgba(59,130,246,0.1)',");
                    sb.append("fill:true,tension:0.3,pointRadius:2}]},");
                    sb.append("options:{responsive:true,plugins:{title:{display:true,text:'");
                    sb.append(esc(entry.getKey())).append("'}},");
                    sb.append("scales:{x:{title:{display:true,text:'Time (ms)'}},");
                    sb.append("y:{title:{display:true,text:'Value'}}}}");
                    sb.append("});</script>");
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
            if (i > 0) sb.append(",");
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
                if (j > 0) sb.append(",");
                Alert a = r.getAlerts().get(j);
                sb.append("{\"level\":\"").append(a.level().name()).append("\"");
                sb.append(",\"message\":\"").append(jsonEsc(a.message())).append("\"}");
            }
            sb.append("]");
            // Data profiles
            sb.append(",\"dataProfiles\":{");
            int pIdx = 0;
            for (var entry : r.getDataProfiles().entrySet()) {
                if (pIdx++ > 0) sb.append(",");
                sb.append("\"").append(jsonEsc(entry.getKey())).append("\":[");
                for (int j = 0; j < entry.getValue().size(); j++) {
                    if (j > 0) sb.append(",");
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
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    private static String jsonEsc(String s) {
        if (s == null) return "";
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
