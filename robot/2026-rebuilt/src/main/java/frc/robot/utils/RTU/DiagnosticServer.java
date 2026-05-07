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
        final int successRating; // 0-5 scale (0=miss, 5=perfect)
        final String notes;

        CollectedSample(long t, double velocityRps, double hoodDeg, double distanceM) {
            this.t = t;
            this.velocityRps = velocityRps;
            this.hoodDeg = hoodDeg;
            this.distanceM = distanceM;
            this.successRating = -1; // unrated
            this.notes = "";
        }

        CollectedSample(long t, double velocityRps, double hoodDeg, double distanceM, int successRating, String notes) {
            this.t = t;
            this.velocityRps = velocityRps;
            this.hoodDeg = hoodDeg;
            this.distanceM = distanceM;
            this.successRating = successRating;
            this.notes = notes != null ? notes : "";
        }
    }

    // Auto-sweep cycle tracking
    private static class SweepCycle {

        final List<CollectedSample> trials = new java.util.ArrayList<>();
        boolean completed = false;
        int bestTrialIndex = -1;
        double targetDistance = 0.0;

        void addTrial(double velocityRps, double hoodDeg, double distanceM) {
            trials.add(new CollectedSample(System.currentTimeMillis(), velocityRps, hoodDeg, distanceM));
        }

        void complete(int bestTrialIndex) {
            this.completed = true;
            this.bestTrialIndex = bestTrialIndex;
        }
    }

    private SweepCycle currentCycle = null;

    private static final DateTimeFormatter TIME_FMT
            = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")
                    .withZone(ZoneId.systemDefault());

    public DiagnosticServer(int port) {
        this.port = port;
    }

    /**
     * Start the HTTP server (non-blocking).
     */
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
                        "{\"shooterRps\":%.4f,\"hoodDeg\":%.3f,\"hoodRot\":%.3f,\"distM\":%.3f}",
                        frc.robot.utils.RTU.TelemetryPublisher.getShooterVelocityRps(),
                        frc.robot.utils.RTU.TelemetryPublisher.getHoodAngleDeg(),
                        frc.robot.utils.RTU.TelemetryPublisher.getHoodPositionRotations(),
                        frc.robot.utils.RTU.TelemetryPublisher.getDistanceToHubM()
                );
                byte[] bytes = json.getBytes(StandardCharsets.UTF_8);
                exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                exchange.sendResponseHeaders(200, bytes.length);
                try (OutputStream os = exchange.getResponseBody()) {
                    os.write(bytes);
                }
            });

            // Collector: record a 'hit' (POST) — snapshot current telemetry and store it
            server.createContext("/diag/" + sessionId + "/collector/hit", exchange -> {
                if (!"POST".equals(exchange.getRequestMethod())) {
                    exchange.sendResponseHeaders(405, -1);
                    return;
                }
                double v = frc.robot.utils.RTU.TelemetryPublisher.getShooterVelocityRps();
                double h = frc.robot.utils.RTU.TelemetryPublisher.getHoodPositionRotations();
                double d = frc.robot.utils.RTU.TelemetryPublisher.getDistanceToHubM();
                CollectedSample s = new CollectedSample(System.currentTimeMillis(), v, h, d);
                synchronized (collectedSamples) {
                    collectedSamples.add(s);
                }
                String resp = "OK";
                byte[] bytes = resp.getBytes(StandardCharsets.UTF_8);
                exchange.sendResponseHeaders(200, bytes.length);
                try (OutputStream os = exchange.getResponseBody()) {
                    os.write(bytes);
                }
            });

            // Collector: list samples (JSON)
            server.createContext("/diag/" + sessionId + "/collector/list", exchange -> {
                StringBuilder jb = new StringBuilder();
                jb.append("[");
                synchronized (collectedSamples) {
                    for (int i = 0; i < collectedSamples.size(); i++) {
                        if (i > 0) {
                            jb.append(',');
                        }
                        CollectedSample s = collectedSamples.get(i);
                        jb.append(String.format("{\"t\":%d,\"v\":%.4f,\"h\":%.3f,\"d\":%.3f,\"r\":%d,\"notes\":\"%s\"}",
                                s.t, s.velocityRps, s.hoodDeg, s.distanceM, s.successRating, jsonEsc(s.notes)));
                    }
                }
                jb.append("]");
                byte[] bytes = jb.toString().getBytes(StandardCharsets.UTF_8);
                exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                exchange.sendResponseHeaders(200, bytes.length);
                try (OutputStream os = exchange.getResponseBody()) {
                    os.write(bytes);
                }
            });

            // Collector: CSV download
            server.createContext("/diag/" + sessionId + "/collector/csv", exchange -> {
                StringBuilder cb = new StringBuilder();
                cb.append("timestamp_ms,shooter_rps,hood_deg,distance_m,success_rating,notes\n");
                synchronized (collectedSamples) {
                    for (CollectedSample s : collectedSamples) {
                        cb.append(String.format("%d,%.6f,%.4f,%.4f,%d,\"%s\"\n",
                                s.t, s.velocityRps, s.hoodDeg, s.distanceM, s.successRating, s.notes.replace("\"", "\"\"")));
                    }
                }
                byte[] bytes = cb.toString().getBytes(StandardCharsets.UTF_8);
                exchange.getResponseHeaders().set("Content-Type", "text/csv; charset=UTF-8");
                exchange.getResponseHeaders().set("Content-Disposition", "attachment; filename=shooter_tuning_data.csv");
                exchange.sendResponseHeaders(200, bytes.length);
                try (OutputStream os = exchange.getResponseBody()) {
                    os.write(bytes);
                }
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
                            if (kv.length != 2) {
                                continue;
                            }
                            String k = kv[0];
                            String v = java.net.URLDecoder.decode(kv[1], StandardCharsets.UTF_8);
                            try {
                                if (k.equals("velocity")) {
                                    velocity = Double.parseDouble(v);
                                }
                                if (k.equals("hoodDeg")) {
                                    hood = Double.parseDouble(v);
                                }
                            } catch (NumberFormatException nfe) {
                            }
                        }
                    }
                    var rc = frc.robot.RobotContainer.getInstance();
                    if (rc != null) {
                        if (!Double.isNaN(velocity)) {
                            rc.setShooterVelocityRps(velocity);
                        }
                        if (!Double.isNaN(hood)) {
                            rc.setHoodPosition(hood);
                        }
                    }
                    String resp = "{\"ok\":true}\n";
                    byte[] bytes = resp.getBytes(StandardCharsets.UTF_8);
                    exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                    exchange.sendResponseHeaders(200, bytes.length);
                    try (OutputStream os = exchange.getResponseBody()) {
                        os.write(bytes);
                    }
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
                            if (kv.length != 2) {
                                continue;
                            }
                            String k = kv[0];
                            String v = java.net.URLDecoder.decode(kv[1], StandardCharsets.UTF_8);
                            try {
                                if (k.equals("min")) {
                                    min = Double.parseDouble(v);
                                }
                                if (k.equals("max")) {
                                    max = Double.parseDouble(v);
                                }
                                if (k.equals("step")) {
                                    step = Double.parseDouble(v);
                                }
                                if (k.equals("hoodDeg")) {
                                    hoodDeg = Double.parseDouble(v);
                                }
                                if (k.equals("holdMs")) {
                                    holdMs = Integer.parseInt(v);
                                }
                            } catch (NumberFormatException nfe) {
                            }
                        }
                    }
                    var rc = frc.robot.RobotContainer.getInstance();
                    if (rc != null && !Double.isNaN(min) && !Double.isNaN(max) && !Double.isNaN(step)) {
                        rc.startAutoSweep(min, max, step, Double.isNaN(hoodDeg) ? 0.0 : hoodDeg, holdMs);
                        String resp = "{\"started\":true}\n";
                        byte[] bytes = resp.getBytes(StandardCharsets.UTF_8);
                        exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                        exchange.sendResponseHeaders(200, bytes.length);
                        try (OutputStream os = exchange.getResponseBody()) {
                            os.write(bytes);
                        }
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
                if (rc != null) {
                    rc.stopAutoSweep();
                }
                String resp = "{\"stopped\":true}\n";
                byte[] bytes = resp.getBytes(StandardCharsets.UTF_8);
                exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                exchange.sendResponseHeaders(200, bytes.length);
                try (OutputStream os = exchange.getResponseBody()) {
                    os.write(bytes);
                }
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
                try (OutputStream os = exchange.getResponseBody()) {
                    os.write(bytes);
                }
            });

            // ===== ENHANCED TUNING ENDPOINTS =====
            // Save sample with rating and notes
            server.createContext("/diag/" + sessionId + "/tuning/save-sample", exchange -> {
                if (!"POST".equals(exchange.getRequestMethod())) {
                    exchange.sendResponseHeaders(405, -1);
                    return;
                }

                try {
                    var q = exchange.getRequestURI().getQuery();
                    double velocity = frc.robot.utils.RTU.TelemetryPublisher.getShooterVelocityRps();
                    double hood = frc.robot.utils.RTU.TelemetryPublisher.getHoodPositionRotations();
                    double distance = frc.robot.utils.RTU.TelemetryPublisher.getDistanceToHubM();
                    int rating = 3; // default middle rating
                    String notes = "";

                    if (q != null) {
                        for (String part : q.split("&")) {
                            String[] kv = part.split("=");
                            if (kv.length != 2) {
                                continue;
                            }
                            String k = kv[0];
                            String v = java.net.URLDecoder.decode(kv[1], StandardCharsets.UTF_8);
                            try {
                                if (k.equals("rating")) {
                                    rating = Math.max(0, Math.min(5, Integer.parseInt(v)));
                                } else if (k.equals("notes")) {
                                    notes = v;
                                } else if (k.equals("velocity")) {
                                    velocity = Double.parseDouble(v);
                                } else if (k.equals("hood")) {
                                    hood = Double.parseDouble(v);
                                } else if (k.equals("distance")) {
                                    distance = Double.parseDouble(v);
                                }
                            } catch (NumberFormatException nfe) {
                            }
                        }
                    }

                    CollectedSample s = new CollectedSample(System.currentTimeMillis(), velocity, hood, distance, rating, notes);
                    synchronized (collectedSamples) {
                        collectedSamples.add(s);
                    }

                    String resp = String.format("{\"ok\":true,\"saved\":{\"v\":%.4f,\"h\":%.3f,\"d\":%.3f,\"r\":%d}}",
                            velocity, hood, distance, rating);
                    byte[] bytes = resp.getBytes(StandardCharsets.UTF_8);
                    exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                    exchange.sendResponseHeaders(200, bytes.length);
                    try (OutputStream os = exchange.getResponseBody()) {
                        os.write(bytes);
                    }
                } catch (Exception e) {
                    exchange.sendResponseHeaders(500, -1);
                }
            });

            // Prediction endpoint based on distance
            server.createContext("/diag/" + sessionId + "/tuning/predict", exchange -> {
                try {
                    var q = exchange.getRequestURI().getQuery();
                    double targetDistance = 2.0; // default

                    if (q != null) {
                        for (String part : q.split("&")) {
                            String[] kv = part.split("=");
                            if (kv.length == 2 && kv[0].equals("distance")) {
                                try {
                                    targetDistance = Double.parseDouble(java.net.URLDecoder.decode(kv[1], StandardCharsets.UTF_8));
                                } catch (NumberFormatException nfe) {
                                }
                            }
                        }
                    }

                    // Simple linear regression on existing data
                    var prediction = calculatePrediction(targetDistance);
                    String resp = String.format(
                            "{\"distance\":%.3f,\"predictedVelocity\":%.4f,\"predictedHood\":%.3f,\"confidence\":%.2f,\"sampleCount\":%d}",
                            targetDistance, prediction[0], prediction[1], prediction[2], prediction[3]);

                    byte[] bytes = resp.getBytes(StandardCharsets.UTF_8);
                    exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                    exchange.sendResponseHeaders(200, bytes.length);
                    try (OutputStream os = exchange.getResponseBody()) {
                        os.write(bytes);
                    }
                } catch (Exception e) {
                    exchange.sendResponseHeaders(500, -1);
                }
            });

            // Start auto-sweep cycle
            server.createContext("/diag/" + sessionId + "/tuning/cycle/start", exchange -> {
                try {
                    var q = exchange.getRequestURI().getQuery();
                    double baseVelocity = 30.0;
                    double baseHood = 15.0;
                    double distance = 2.0;
                    double velocityRange = 10.0;
                    double hoodRange = 5.0;

                    if (q != null) {
                        for (String part : q.split("&")) {
                            String[] kv = part.split("=");
                            if (kv.length != 2) {
                                continue;
                            }
                            String k = kv[0];
                            String v = java.net.URLDecoder.decode(kv[1], StandardCharsets.UTF_8);
                            try {
                                switch (k) {
                                    case "baseVelocity":
                                        baseVelocity = Double.parseDouble(v);
                                        break;
                                    case "baseHood":
                                        baseHood = Double.parseDouble(v);
                                        break;
                                    case "distance":
                                        distance = Double.parseDouble(v);
                                        break;
                                    case "velocityRange":
                                        velocityRange = Double.parseDouble(v);
                                        break;
                                    case "hoodRange":
                                        hoodRange = Double.parseDouble(v);
                                        break;
                                }
                            } catch (NumberFormatException nfe) {
                            }
                        }
                    }

                    synchronized (this) {
                        currentCycle = new SweepCycle();
                        currentCycle.targetDistance = distance;

                        // Generate 5 trials around the base values
                        for (int i = 0; i < 5; i++) {
                            double vOffset = (i - 2) * velocityRange / 4.0;
                            double hOffset = (i - 2) * hoodRange / 4.0;
                            currentCycle.addTrial(baseVelocity + vOffset, baseHood + hOffset, distance);
                        }
                    }

                    String resp = String.format("{\"started\":true,\"trialCount\":%d,\"baseVelocity\":%.4f,\"baseHood\":%.3f}",
                            5, baseVelocity, baseHood);
                    byte[] bytes = resp.getBytes(StandardCharsets.UTF_8);
                    exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                    exchange.sendResponseHeaders(200, bytes.length);
                    try (OutputStream os = exchange.getResponseBody()) {
                        os.write(bytes);
                    }
                } catch (Exception e) {
                    exchange.sendResponseHeaders(500, -1);
                }
            });

            // Get current cycle status and trials
            server.createContext("/diag/" + sessionId + "/tuning/cycle/status", exchange -> {
                StringBuilder resp = new StringBuilder();
                synchronized (this) {
                    if (currentCycle == null) {
                        resp.append("{\"active\":false}");
                    } else {
                        resp.append("{\"active\":true,\"completed\":").append(currentCycle.completed);
                        resp.append(",\"trialCount\":").append(currentCycle.trials.size());
                        resp.append(",\"trials\":[");
                        for (int i = 0; i < currentCycle.trials.size(); i++) {
                            if (i > 0) {
                                resp.append(",");
                            }
                            CollectedSample trial = currentCycle.trials.get(i);
                            resp.append(String.format("{\"index\":%d,\"velocity\":%.4f,\"hood\":%.3f,\"distance\":%.3f}",
                                    i, trial.velocityRps, trial.hoodDeg, trial.distanceM));
                        }
                        resp.append("]}");
                    }
                }

                byte[] bytes = resp.toString().getBytes(StandardCharsets.UTF_8);
                exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                exchange.sendResponseHeaders(200, bytes.length);
                try (OutputStream os = exchange.getResponseBody()) {
                    os.write(bytes);
                }
            });

            // Complete cycle with best trial selection
            server.createContext("/diag/" + sessionId + "/tuning/cycle/complete", exchange -> {
                if (!"POST".equals(exchange.getRequestMethod())) {
                    exchange.sendResponseHeaders(405, -1);
                    return;
                }

                try {
                    var q = exchange.getRequestURI().getQuery();
                    int bestTrial = 0;
                    boolean successful = false;

                    if (q != null) {
                        for (String part : q.split("&")) {
                            String[] kv = part.split("=");
                            if (kv.length != 2) {
                                continue;
                            }
                            String k = kv[0];
                            String v = java.net.URLDecoder.decode(kv[1], StandardCharsets.UTF_8);
                            try {
                                if (k.equals("bestTrial")) {
                                    bestTrial = Integer.parseInt(v);
                                } else if (k.equals("successful")) {
                                    successful = Boolean.parseBoolean(v);
                                }
                            } catch (NumberFormatException nfe) {
                            }
                        }
                    }

                    synchronized (this) {
                        if (currentCycle != null && bestTrial >= 0 && bestTrial < currentCycle.trials.size()) {
                            currentCycle.complete(bestTrial);

                            // Save the best trial with high rating if successful
                            CollectedSample best = currentCycle.trials.get(bestTrial);
                            int rating = successful ? 5 : 2;
                            CollectedSample ratedSample = new CollectedSample(
                                    System.currentTimeMillis(), best.velocityRps, best.hoodDeg,
                                    best.distanceM, rating, "Auto-cycle best trial");

                            synchronized (collectedSamples) {
                                collectedSamples.add(ratedSample);
                            }

                            currentCycle = null; // Clear the cycle
                        }
                    }

                    String resp = "{\"completed\":true}";
                    byte[] bytes = resp.getBytes(StandardCharsets.UTF_8);
                    exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                    exchange.sendResponseHeaders(200, bytes.length);
                    try (OutputStream os = exchange.getResponseBody()) {
                        os.write(bytes);
                    }
                } catch (Exception e) {
                    exchange.sendResponseHeaders(500, -1);
                }
            });
            server.setExecutor(null);
            server.start();
        } catch (IOException e) {
            System.err.println("[DiagnosticServer] Failed to start on port " + port + ": " + e.getMessage());
        }
    }

    /**
     * Update the results displayed on the dashboard. Thread-safe.
     */
    public synchronized void updateResults(List<TestResult> results) {
        this.latestResults = List.copyOf(results);
    }

    /**
     * Set a safety message to display on the dashboard. Thread-safe.
     */
    public synchronized void setSafetyMessage(String message) {
        this.safetyMessage = message;
    }

    /**
     * @return the full URL to the diagnostic dashboard.
     */
    public String getUrl() {

        return "http://localhost:" + port + "/diag/" + sessionId;
    }

    /**
     * @return the session ID for this run.
     */
    public String getSessionId() {
        return sessionId;
    }

    /**
     * Stop the server.
     */
    public void stop() {
        if (server != null) {
            server.stop(0);
        }
    }

    // ── HTML Generation ──────────────────────────────────────
    private synchronized String buildHtml() {
        var sb = new StringBuilder();
        sb.append("<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'>");
        // Fast 2-second refresh for responsive updates
        sb.append("<meta http-equiv='refresh' content='2'>");
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

        // Always show the enhanced shooter tuning interface
        // Enhanced Shooter Tuning Interface
        sb.append("<div class='card'>");
        sb.append("<h2>Advanced Shooter Tuning System</h2>");
        sb.append("<p>Comprehensive tuning tool with manual controls, prediction, and automated optimization.</p>");

        // Live telemetry display
        sb.append("<div class='telemetry-section'>");
        sb.append("<h3>Live Telemetry</h3>");
        sb.append("<div class='telemetry-grid'>");
        sb.append("<div class='telemetry-item'><label>Shooter RPS:</label><span id='tel_shooter' class='telemetry-value'>--</span></div>");
        sb.append("<div class='telemetry-item'><label>Hood Position:</label><span id='tel_hood' class='telemetry-value'>-- rot</span></div>");
        sb.append("<div class='telemetry-item'><label>Distance:</label><span id='tel_dist' class='telemetry-value'>-- m</span></div>");
        sb.append("</div></div>");

        // Manual Tuning Mode
        sb.append("<div class='tuning-mode' id='manual-mode'>");
        sb.append("<h3> Manual Tuning Mode</h3>");

        // Shooter velocity controls
        sb.append("<div class='control-group'>");
        sb.append("<label class='control-label'>Shooter Velocity (RPS):</label>");
        sb.append("<div class='slider-control'>");
        sb.append("<button onclick='adjustVelocity(-1)'>-</button>");
        sb.append("<input type='range' id='velocity-slider' min='0' max='100' value='30' step='0.1' oninput='updateVelocityDisplay()'>");
        sb.append("<button onclick='adjustVelocity(1)'>+</button>");
        sb.append("<input type='number' id='velocity-input' value='30' min='0' max='100' step='0.1' onchange='syncVelocitySlider()'>");
        sb.append("</div></div>");

        // Hood angle controls
        sb.append("<div class='control-group'>");
        sb.append("<label class='control-label'>Hood Position (rotations):</label>");
        sb.append("<div class='slider-control'>");
        sb.append("<button onclick='adjustHood(-0.5)'>-</button>");
        sb.append("<input type='range' id='hood-slider' min='0' max='30' value='15' step='0.1' oninput='updateHoodDisplay()'>");
        sb.append("<button onclick='adjustHood(0.5)'>+</button>");
        sb.append("<input type='number' id='hood-input' value='15' min='0' max='30' step='0.1' onchange='syncHoodSlider()'>");
        sb.append("</div></div>");

        // Action buttons
        sb.append("<div class='action-buttons'>");
        sb.append("<button id='btn-apply' class='btn-primary' onclick='applySettings()'>Apply Settings</button>");
        sb.append("<button id='btn-fire' class='btn-fire' onclick='fireShooter()'>🔥 FIRE</button>");
        sb.append("<div class='save-controls'>");
        sb.append("<select id='success-rating'>");
        sb.append("<option value='0'>0 - Miss</option><option value='1'>1 - Very Poor</option><option value='2'>2 - Poor</option>");
        sb.append("<option value='3' selected>3 - OK</option><option value='4'>4 - Good</option><option value='5'>5 - Perfect</option>");
        sb.append("</select>");
        sb.append("<input type='text' id='shot-notes' placeholder='Shot notes...' maxlength='100'>");
        sb.append("<button id='btn-save' class='btn-success' onclick='saveSample()'>Save Sample</button>");
        sb.append("</div></div>");
        sb.append("</div>");

        // Prediction Mode
        sb.append("<div class='tuning-mode' id='prediction-mode'>");
        sb.append("<h3>Prediction Mode</h3>");
        sb.append("<div class='prediction-controls'>");
        sb.append("<label>Target Distance (m):</label>");
        sb.append("<input type='number' id='target-distance' value='2.5' min='1' max='10' step='0.1'>");
        sb.append("<button onclick='getPrediction()'>Get Prediction</button>");
        sb.append("</div>");
        sb.append("<div id='prediction-result' class='prediction-result'></div>");
        sb.append("</div>");

        // Auto Sweep Mode
        sb.append("<div class='tuning-mode' id='auto-mode'>");
        sb.append("<h3>Auto Sweep Mode</h3>");
        sb.append("<div class='cycle-controls'>");
        sb.append("<div class='input-row'>");
        sb.append("<label>Base Velocity:</label><input type='number' id='base-velocity' value='30' step='1'>");
        sb.append("<label>Base Hood:</label><input type='number' id='base-hood' value='15' step='0.5'>");
        sb.append("</div>");
        sb.append("<div class='input-row'>");
        sb.append("<label>Velocity Range:</label><input type='number' id='velocity-range' value='10' step='1'>");
        sb.append("<label>Hood Range:</label><input type='number' id='hood-range' value='5' step='0.5'>");
        sb.append("<label>Distance:</label><input type='number' id='cycle-distance' value='2.5' step='0.1'>");
        sb.append("</div>");
        sb.append("<button onclick='startCycle()'>Start 5-Shot Cycle</button>");
        sb.append("</div>");
        sb.append("<div id='cycle-status' class='cycle-status'></div>");
        sb.append("<div id='cycle-trials' class='cycle-trials'></div>");
        sb.append("</div>");

        // Data & Statistics
        sb.append("<div class='data-section'>");
        sb.append("<h3>Saved Data & Statistics</h3>");
        sb.append("<div class='data-controls'>");
        sb.append("<button onclick='refreshDataList()'>Refresh Data</button>");
        sb.append("<a href='/diag/").append(sessionId).append("/collector/csv' target='_blank'><button>Download CSV</button></a>");
        sb.append("<span id='data-stats' class='data-stats'></span>");
        sb.append("</div>");
        sb.append("<div class='samples-table-container'>");
        sb.append("<table id='samples_tbl' class='samples-table'>");
        sb.append("<thead><tr><th>Time</th><th>Velocity</th><th>Hood</th><th>Distance</th><th>Rating</th><th>Notes</th></tr></thead>");
        sb.append("<tbody></tbody>");
        sb.append("</table>");
        sb.append("</div></div>");
        sb.append("</div>");

        // RTU Test Results Section (only show if there are results)
        if (latestResults.isEmpty()) {
            sb.append("<div class='card'>");
            sb.append("<h2>Root Test Diagnostics</h2>");
            sb.append("<p class='waiting'>No RTU test results yet. The shooter tuning system above is ready to use!</p>");
            sb.append("</div>");
        } else {
            // Show RTU results if available
            // Summary bar
            long passed = latestResults.stream().filter(TestResult::isPassed).count();
            long failed = latestResults.size() - passed;
            String summaryClass = failed == 0 ? "summary-pass" : "summary-fail";
            sb.append("<div class='card'>");
            sb.append("<h2>Root Test Diagnostics Results</h2>");
            sb.append("<div class='summary ").append(summaryClass).append("'>");
            sb.append("<span>Total: <b>").append(latestResults.size()).append("</b></span>");
            sb.append("<span>Passed: <b>").append(passed).append("</b></span>");
            sb.append("<span>Failed: <b>").append(failed).append("</b></span>");
            sb.append("</div>");

            // Enhanced JavaScript for Shooter Tuning System
            sb.append("<script>");
            sb.append("const base = '/diag/").append(sessionId).append("';\n");
            sb.append("let cycleActive = false;\n");
            sb.append("let currentTrials = [];\n");

            // Core telemetry polling
            sb.append("async function pollTelemetry(){\n");
            sb.append("  try{\n");
            sb.append("    const r=await fetch(base+'/telemetry');\n");
            sb.append("    if(r.ok){\n");
            sb.append("      const j=await r.json();\n");
            sb.append("      document.getElementById('tel_shooter').textContent=j.shooterRps.toFixed(3);\n");
            sb.append("      document.getElementById('tel_hood').textContent=j.hoodRot.toFixed(2)+' rot';\n");
            sb.append("      document.getElementById('tel_dist').textContent=j.distM.toFixed(2)+' m';\n");
            sb.append("    }\n");
            sb.append("  }catch(e){}\n");
            sb.append("  finally{setTimeout(pollTelemetry,1000);}\n");
            sb.append("}\n");

            // Manual control functions
            sb.append("function adjustVelocity(delta){\n");
            sb.append("  const input=document.getElementById('velocity-input');\n");
            sb.append("  const val=Math.max(0,Math.min(100,parseFloat(input.value)+delta));\n");
            sb.append("  input.value=val.toFixed(1);\n");
            sb.append("  syncVelocitySlider();\n");
            sb.append("}\n");

            sb.append("function adjustHood(delta){\n");
            sb.append("  const input=document.getElementById('hood-input');\n");
            sb.append("  const val=Math.max(0,Math.min(30,parseFloat(input.value)+delta));\n");
            sb.append("  input.value=val.toFixed(1);\n");
            sb.append("  syncHoodSlider();\n");
            sb.append("}\n");

            sb.append("function updateVelocityDisplay(){\n");
            sb.append("  const slider=document.getElementById('velocity-slider');\n");
            sb.append("  document.getElementById('velocity-input').value=parseFloat(slider.value).toFixed(1);\n");
            sb.append("}\n");

            sb.append("function updateHoodDisplay(){\n");
            sb.append("  const slider=document.getElementById('hood-slider');\n");
            sb.append("  document.getElementById('hood-input').value=parseFloat(slider.value).toFixed(1);\n");
            sb.append("}\n");

            sb.append("function syncVelocitySlider(){\n");
            sb.append("  const input=document.getElementById('velocity-input');\n");
            sb.append("  document.getElementById('velocity-slider').value=input.value;\n");
            sb.append("}\n");

            sb.append("function syncHoodSlider(){\n");
            sb.append("  const input=document.getElementById('hood-input');\n");
            sb.append("  document.getElementById('hood-slider').value=input.value;\n");
            sb.append("}\n");

            // Apply settings to robot
            sb.append("async function applySettings(){\n");
            sb.append("  const velocity=document.getElementById('velocity-input').value;\n");
            sb.append("  const hood=document.getElementById('hood-input').value;\n");
            sb.append("  try{\n");
            sb.append("    const q=`?velocity=${encodeURIComponent(velocity)}&hoodDeg=${encodeURIComponent(hood)}`;\n");
            sb.append("    const r=await fetch(base+'/collector/set'+q);\n");
            sb.append("    if(r.ok){\n");
            sb.append("      showStatus('Settings applied successfully','success');\n");
            sb.append("    }else{\n");
            sb.append("      showStatus('Failed to apply settings','error');\n");
            sb.append("    }\n");
            sb.append("  }catch(e){\n");
            sb.append("    showStatus('Error applying settings: '+e,'error');\n");
            sb.append("  }\n");
            sb.append("}\n");

            // Fire button (placeholder - robot should handle firing)
            sb.append("function fireShooter(){\n");
            sb.append("  showStatus('Fire command sent! (Robot controls actual firing)','info');\n");
            sb.append("  // Note: Actual firing is controlled by robot operator/autonomous systems\n");
            sb.append("}\n");

            // Save sample with rating
            sb.append("async function saveSample(){\n");
            sb.append("  const rating=document.getElementById('success-rating').value;\n");
            sb.append("  const notes=encodeURIComponent(document.getElementById('shot-notes').value);\n");
            sb.append("  try{\n");
            sb.append("    const q=`?rating=${rating}&notes=${notes}`;\n");
            sb.append("    const r=await fetch(base+'/tuning/save-sample'+q,{method:'POST'});\n");
            sb.append("    if(r.ok){\n");
            sb.append("      const result=await r.json();\n");
            sb.append("      showStatus(`Sample saved with rating ${rating}/5`,'success');\n");
            sb.append("      document.getElementById('shot-notes').value='';\n");
            sb.append("      refreshDataList();\n");
            sb.append("    }else{\n");
            sb.append("      showStatus('Failed to save sample','error');\n");
            sb.append("    }\n");
            sb.append("  }catch(e){\n");
            sb.append("    showStatus('Error saving sample: '+e,'error');\n");
            sb.append("  }\n");
            sb.append("}\n");

            // Prediction functionality
            sb.append("async function getPrediction(){\n");
            sb.append("  const distance=document.getElementById('target-distance').value;\n");
            sb.append("  try{\n");
            sb.append("    const r=await fetch(base+'/tuning/predict?distance='+encodeURIComponent(distance));\n");
            sb.append("    if(r.ok){\n");
            sb.append("      const pred=await r.json();\n");
            sb.append("      const resultDiv=document.getElementById('prediction-result');\n");
            sb.append("      resultDiv.innerHTML=`\n");
            sb.append("        <div class='prediction-display'>\n");
            sb.append("          <h4>🎯 Prediction for ${distance}m:</h4>\n");
            sb.append("          <div>Velocity: <strong>${pred.predictedVelocity.toFixed(2)} RPS</strong></div>\n");
            sb.append("          <div>Hood Angle: <strong>${pred.predictedHood.toFixed(2)}°</strong></div>\n");
            sb.append("          <div>Confidence: <strong>${(pred.confidence*100).toFixed(1)}%</strong> (${pred.sampleCount} samples)</div>\n");
            sb.append("          <button onclick='applyPrediction(${pred.predictedVelocity},${pred.predictedHood})'>Apply This Prediction</button>\n");
            sb.append("        </div>`;\n");
            sb.append("    }else{\n");
            sb.append("      showStatus('Failed to get prediction','error');\n");
            sb.append("    }\n");
            sb.append("  }catch(e){\n");
            sb.append("    showStatus('Error getting prediction: '+e,'error');\n");
            sb.append("  }\n");
            sb.append("}\n");

            sb.append("function applyPrediction(vel,hood){\n");
            sb.append("  document.getElementById('velocity-input').value=vel.toFixed(1);\n");
            sb.append("  document.getElementById('hood-input').value=hood.toFixed(1);\n");
            sb.append("  syncVelocitySlider();\n");
            sb.append("  syncHoodSlider();\n");
            sb.append("  applySettings();\n");
            sb.append("}\n");

            // Auto-cycle functionality
            sb.append("async function startCycle(){\n");
            sb.append("  const baseVel=document.getElementById('base-velocity').value;\n");
            sb.append("  const baseHood=document.getElementById('base-hood').value;\n");
            sb.append("  const velRange=document.getElementById('velocity-range').value;\n");
            sb.append("  const hoodRange=document.getElementById('hood-range').value;\n");
            sb.append("  const distance=document.getElementById('cycle-distance').value;\n");
            sb.append("  try{\n");
            sb.append("    const q=`?baseVelocity=${baseVel}&baseHood=${baseHood}&velocityRange=${velRange}&hoodRange=${hoodRange}&distance=${distance}`;\n");
            sb.append("    const r=await fetch(base+'/tuning/cycle/start'+q);\n");
            sb.append("    if(r.ok){\n");
            sb.append("      cycleActive=true;\n");
            sb.append("      showStatus('Cycle started! Ready for 5 trials.','success');\n");
            sb.append("      pollCycleStatus();\n");
            sb.append("    }else{\n");
            sb.append("      showStatus('Failed to start cycle','error');\n");
            sb.append("    }\n");
            sb.append("  }catch(e){\n");
            sb.append("    showStatus('Error starting cycle: '+e,'error');\n");
            sb.append("  }\n");
            sb.append("}\n");

            sb.append("async function pollCycleStatus(){\n");
            sb.append("  if(!cycleActive) return;\n");
            sb.append("  try{\n");
            sb.append("    const r=await fetch(base+'/tuning/cycle/status');\n");
            sb.append("    if(r.ok){\n");
            sb.append("      const status=await r.json();\n");
            sb.append("      if(status.active){\n");
            sb.append("        displayCycleTrials(status.trials);\n");
            sb.append("        if(!status.completed){\n");
            sb.append("          setTimeout(pollCycleStatus,2000);\n");
            sb.append("        }\n");
            sb.append("      }else{\n");
            sb.append("        cycleActive=false;\n");
            sb.append("      }\n");
            sb.append("    }\n");
            sb.append("  }catch(e){}\n");
            sb.append("}\n");

            sb.append("function displayCycleTrials(trials){\n");
            sb.append("  const trialsDiv=document.getElementById('cycle-trials');\n");
            sb.append("  let html='<h4>🔄 Trial Configuration:</h4><div class=\"trial-grid\">';\n");
            sb.append("  trials.forEach((trial,i)=>{\n");
            sb.append("    html+=`<div class=\"trial-item\">\n");
            sb.append("      <strong>Trial ${i+1}:</strong><br>\n");
            sb.append("      V: ${trial.velocity.toFixed(1)} RPS<br>\n");
            sb.append("      H: ${trial.hood.toFixed(1)}°<br>\n");
            sb.append("      <button onclick=\"applyTrial(${trial.velocity},${trial.hood})\">Use This</button>\n");
            sb.append("    </div>`;\n");
            sb.append("  });\n");
            sb.append("  html+='</div>';\n");
            sb.append("  html+='<div class=\"cycle-completion\"><h4>After testing all trials:</h4>';\n");
            sb.append("  html+='<label>Best trial: <select id=\"best-trial\">';\n");
            sb.append("  for(let i=0;i<trials.length;i++){\n");
            sb.append("    html+=`<option value=\"${i}\">Trial ${i+1}</option>`;\n");
            sb.append("  }\n");
            sb.append("  html+='</select></label>';\n");
            sb.append("  html+='<label><input type=\"checkbox\" id=\"cycle-successful\"> Cycle was successful</label>';\n");
            sb.append("  html+='<button onclick=\"completeCycle()\">Complete Cycle</button></div>';\n");
            sb.append("  trialsDiv.innerHTML=html;\n");
            sb.append("}\n");

            sb.append("function applyTrial(vel,hood){\n");
            sb.append("  document.getElementById('velocity-input').value=vel.toFixed(1);\n");
            sb.append("  document.getElementById('hood-input').value=hood.toFixed(1);\n");
            sb.append("  syncVelocitySlider();\n");
            sb.append("  syncHoodSlider();\n");
            sb.append("  applySettings();\n");
            sb.append("}\n");

            sb.append("async function completeCycle(){\n");
            sb.append("  const bestTrial=document.getElementById('best-trial').value;\n");
            sb.append("  const successful=document.getElementById('cycle-successful').checked;\n");
            sb.append("  try{\n");
            sb.append("    const q=`?bestTrial=${bestTrial}&successful=${successful}`;\n");
            sb.append("    const r=await fetch(base+'/tuning/cycle/complete'+q,{method:'POST'});\n");
            sb.append("    if(r.ok){\n");
            sb.append("      showStatus(`Cycle completed! Best trial: ${parseInt(bestTrial)+1}`,'success');\n");
            sb.append("      cycleActive=false;\n");
            sb.append("      document.getElementById('cycle-trials').innerHTML='';\n");
            sb.append("      refreshDataList();\n");
            sb.append("    }else{\n");
            sb.append("      showStatus('Failed to complete cycle','error');\n");
            sb.append("    }\n");
            sb.append("  }catch(e){\n");
            sb.append("    showStatus('Error completing cycle: '+e,'error');\n");
            sb.append("  }\n");
            sb.append("}\n");

            // Data management
            sb.append("async function refreshDataList(){\n");
            sb.append("  try{\n");
            sb.append("    const r=await fetch(base+'/collector/list');\n");
            sb.append("    if(!r.ok) return;\n");
            sb.append("    const samples=await r.json();\n");
            sb.append("    const tbody=document.querySelector('#samples_tbl tbody');\n");
            sb.append("    tbody.innerHTML='';\n");
            sb.append("    let ratedCount=0,totalRating=0;\n");
            sb.append("    samples.forEach(s=>{\n");
            sb.append("      if(s.r>=0){ratedCount++;totalRating+=s.r;}\n");
            sb.append("      const tr=document.createElement('tr');\n");
            sb.append("      const time=new Date(s.t).toLocaleTimeString();\n");
            sb.append("      const rating=s.r>=0?s.r+'/5':'–';\n");
            sb.append("      tr.innerHTML=`<td>${time}</td><td>${s.v.toFixed(2)}</td><td>${s.h.toFixed(1)}°</td><td>${s.d.toFixed(2)}m</td><td>${rating}</td><td>${s.notes||''}</td>`;\n");
            sb.append("      tbody.appendChild(tr);\n");
            sb.append("    });\n");
            sb.append("    const avgRating=ratedCount>0?(totalRating/ratedCount).toFixed(1):'–';\n");
            sb.append("    document.getElementById('data-stats').textContent=`${samples.length} samples, ${ratedCount} rated (avg: ${avgRating}/5)`;\n");
            sb.append("  }catch(e){}\n");
            sb.append("}\n");

            // Status display utility
            sb.append("function showStatus(message,type='info'){\n");
            sb.append("  console.log(`[${type.toUpperCase()}] ${message}`);\n");
            sb.append("  // Could add a toast notification system here\n");
            sb.append("}\n");

            sb.append("// Initialize on load\n");
            sb.append("window.addEventListener('load',()=>{\n");
            sb.append("  pollTelemetry();\n");
            sb.append("  refreshDataList();\n");
            sb.append("  syncVelocitySlider();\n");
            sb.append("  syncHoodSlider();\n");
            sb.append("});\n");
            sb.append("</script>");

            // RTU Test Results Section (only show if there are results)
            if (latestResults.isEmpty()) {
                sb.append("<div class='card'>");
                sb.append("<h2>🔧 Root Test Diagnostics</h2>");
                sb.append("<p class='waiting'>No RTU test results yet. The shooter tuning system above is ready to use!</p>");
                sb.append("</div>");
            } else {
                // Show RTU results if available
                // Summary bar  
                long passedRtu = latestResults.stream().filter(TestResult::isPassed).count();
                long failedRtu = latestResults.size() - passedRtu;
                String summaryClassRtu = failedRtu == 0 ? "summary-pass" : "summary-fail";
                sb.append("<div class='card'>");
                sb.append("<h2>🔧 Root Test Diagnostics Results</h2>");
                sb.append("<div class='summary ").append(summaryClassRtu).append("'>");
                sb.append("<span>Total: <b>").append(latestResults.size()).append("</b></span>");
                sb.append("<span>Passed: <b>").append(passedRtu).append("</b></span>");
                sb.append("<span>Failed: <b>").append(failedRtu).append("</b></span>");
                sb.append("</div>");

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
                                if (i > 0) {
                                    sb.append(",");
                                }
                                sb.append(String.format("%.1f", samples.get(i).timestampMs()));
                            }
                            sb.append("],datasets:[{label:'").append(esc(entry.getKey())).append("',");
                            sb.append("data:[");
                            for (int i = 0; i < samples.size(); i++) {
                                if (i > 0) {
                                    sb.append(",");
                                }
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
                    sb.append("</div>"); // close RTU results card
                }

                sb.append("</div></body></html>");
                return sb.toString();

            }

        }
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
            if (i > 0) {
                sb.append(",");
            }
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
                if (j > 0) {
                    sb.append(",");
                }
                Alert a = r.getAlerts().get(j);
                sb.append("{\"level\":\"").append(a.level().name()).append("\"");
                sb.append(",\"message\":\"").append(jsonEsc(a.message())).append("\"}");
            }
            sb.append("]");
            // Data profiles
            sb.append(",\"dataProfiles\":{");
            int pIdx = 0;
            for (var entry : r.getDataProfiles().entrySet()) {
                if (pIdx++ > 0) {
                    sb.append(",");
                }
                sb.append("\"").append(jsonEsc(entry.getKey())).append("\":[");
                for (int j = 0; j < entry.getValue().size(); j++) {
                    if (j > 0) {
                        sb.append(",");
                    }
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
    /**
     * Calculate predicted velocity and hood angle for a target distance using
     * linear regression on the collected samples with good ratings (3+).
     *
     * @param targetDistance the distance to predict for
     * @return [predictedVelocity, predictedHood, confidence, sampleCount]
     */
    private double[] calculatePrediction(double targetDistance) {
        java.util.List<CollectedSample> goodSamples;
        synchronized (collectedSamples) {
            goodSamples = collectedSamples.stream()
                    .filter(s -> s.successRating >= 3) // Only use samples rated 3 or better
                    .collect(java.util.stream.Collectors.toList());
        }

        if (goodSamples.size() < 2) {
            // Not enough data, return reasonable defaults
            return new double[]{30.0, 15.0, 0.0, goodSamples.size()};
        }

        // Simple linear regression: velocity = a * distance + b, hood = c * distance + d
        double sumX = 0, sumY1 = 0, sumY2 = 0, sumXX = 0, sumXY1 = 0, sumXY2 = 0;
        int n = goodSamples.size();

        for (CollectedSample s : goodSamples) {
            double x = s.distanceM;
            double y1 = s.velocityRps;
            double y2 = s.hoodDeg;

            sumX += x;
            sumY1 += y1;
            sumY2 += y2;
            sumXX += x * x;
            sumXY1 += x * y1;
            sumXY2 += x * y2;
        }

        double meanX = sumX / n;
        double meanY1 = sumY1 / n;
        double meanY2 = sumY2 / n;

        // Calculate slopes and intercepts
        double denominator = sumXX - n * meanX * meanX;
        if (Math.abs(denominator) < 0.001) {
            // Linear fit not possible, return average
            return new double[]{meanY1, meanY2, 0.5, n};
        }

        double slopeVel = (sumXY1 - n * meanX * meanY1) / denominator;
        double interceptVel = meanY1 - slopeVel * meanX;

        double slopeHood = (sumXY2 - n * meanX * meanY2) / denominator;
        double interceptHood = meanY2 - slopeHood * meanX;

        double predictedVel = slopeVel * targetDistance + interceptVel;
        double predictedHood = slopeHood * targetDistance + interceptHood;

        // Calculate confidence based on data spread and sample count
        double confidence = Math.min(0.95, Math.max(0.1, Math.min(1.0, n / 10.0)));

        return new double[]{predictedVel, predictedHood, confidence, n};
    }

    private static String esc(String s) {
        if (s == null) {
            return "";
        }
        return s.replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    private static String jsonEsc(String s) {
        if (s == null) {
            return "";
        }
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

        /* Enhanced Tuning Interface Styles */
        .telemetry-section { background: #0f172a; border-radius: 8px; padding: 16px; margin-bottom: 16px; }
        .telemetry-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 16px; }
        .telemetry-item { text-align: center; }
        .telemetry-item label { display: block; color: #94a3b8; font-size: 0.9rem; margin-bottom: 4px; }
        .telemetry-value { font-size: 1.2rem; font-weight: bold; color: #38bdf8; }

        .tuning-mode { background: #0f172a; border-radius: 8px; padding: 16px; margin-bottom: 16px; 
                       border-left: 4px solid #3b82f6; }
        .tuning-mode h3 { color: #f1f5f9; margin-bottom: 12px; }

        .control-group { margin-bottom: 16px; }
        .control-label { display: block; color: #cbd5e1; font-weight: 500; margin-bottom: 8px; }
        .slider-control { display: flex; align-items: center; gap: 8px; }
        .slider-control button { background: #374151; border: 1px solid #4b5563; color: #e5e7eb; 
                                  padding: 8px 12px; border-radius: 4px; cursor: pointer; font-size: 1rem; }
        .slider-control button:hover { background: #4b5563; }
        .slider-control input[type="range"] { flex: 1; }
        .slider-control input[type="number"] { width: 80px; background: #1f2937; border: 1px solid #4b5563; 
                                               color: #e5e7eb; padding: 6px 8px; border-radius: 4px; }

        .action-buttons { display: flex; flex-wrap: wrap; gap: 12px; align-items: center; }
        .btn-primary { background: #3b82f6; border: none; color: white; padding: 10px 20px; 
                       border-radius: 6px; cursor: pointer; font-weight: 500; }
        .btn-primary:hover { background: #2563eb; }
        .btn-fire { background: #dc2626; border: none; color: white; padding: 10px 20px; 
                    border-radius: 6px; cursor: pointer; font-weight: 500; font-size: 1.1rem; }
        .btn-fire:hover { background: #b91c1c; }
        .btn-success { background: #10b981; border: none; color: white; padding: 8px 16px; 
                       border-radius: 4px; cursor: pointer; font-weight: 500; }
        .btn-success:hover { background: #059669; }

        .save-controls { display: flex; gap: 8px; align-items: center; }
        .save-controls select, .save-controls input[type="text"] { background: #1f2937; border: 1px solid #4b5563; 
                                                                   color: #e5e7eb; padding: 6px 8px; border-radius: 4px; }

        .prediction-controls { display: flex; gap: 12px; align-items: center; margin-bottom: 12px; }
        .prediction-controls input { background: #1f2937; border: 1px solid #4b5563; color: #e5e7eb; 
                                     padding: 6px 8px; border-radius: 4px; width: 100px; }
        .prediction-controls button { background: #059669; border: none; color: white; padding: 8px 16px; 
                                      border-radius: 4px; cursor: pointer; }
        .prediction-result { margin-top: 12px; }
        .prediction-display { background: #1e293b; padding: 16px; border-radius: 8px; border-left: 4px solid #10b981; }
        .prediction-display h4 { color: #10b981; margin-bottom: 8px; }
        .prediction-display div { margin-bottom: 6px; color: #e2e8f0; }
        .prediction-display button { background: #3b82f6; border: none; color: white; padding: 6px 12px; 
                                      border-radius: 4px; cursor: pointer; margin-top: 8px; }

        .cycle-controls { background: #1e293b; padding: 12px; border-radius: 6px; margin-bottom: 12px; }
        .input-row { display: flex; gap: 12px; margin-bottom: 8px; align-items: center; }
        .input-row label { color: #cbd5e1; margin-right: 4px; min-width: 80px; }
        .input-row input { background: #374151; border: 1px solid #4b5563; color: #e5e7eb; 
                           padding: 4px 6px; border-radius: 4px; width: 80px; }
        .cycle-status { margin: 8px 0; color: #38bdf8; }
        .cycle-trials { margin-top: 12px; }
        .trial-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 12px; margin-bottom: 16px; }
        .trial-item { background: #374151; padding: 12px; border-radius: 6px; text-align: center; color: #e5e7eb; }
        .trial-item button { background: #10b981; border: none; color: white; padding: 4px 8px; 
                             border-radius: 4px; cursor: pointer; margin-top: 8px; }
        .cycle-completion { background: #1e293b; padding: 12px; border-radius: 6px; }
        .cycle-completion label { display: block; margin-bottom: 8px; color: #cbd5e1; }
        .cycle-completion select, .cycle-completion input { background: #374151; border: 1px solid #4b5563; 
                                                            color: #e5e7eb; padding: 4px 6px; border-radius: 4px; margin-left: 8px; }

        .data-section { background: #0f172a; border-radius: 8px; padding: 16px; border-left: 4px solid #f59e0b; }
        .data-controls { display: flex; gap: 12px; align-items: center; margin-bottom: 12px; }
        .data-controls button { background: #6b7280; border: none; color: white; padding: 6px 12px; 
                                border-radius: 4px; cursor: pointer; }
        .data-controls button:hover { background: #4b5563; }
        .data-stats { color: #94a3b8; margin-left: auto; }
        .samples-table-container { max-height: 300px; overflow-y: auto; border-radius: 6px; }
        .samples-table { width: 100%; border-collapse: collapse; background: #1e293b; }
        .samples-table th { background: #374151; color: #f1f5f9; padding: 8px 12px; text-align: left; font-weight: 600; }
        .samples-table td { padding: 6px 12px; border-bottom: 1px solid #374151; color: #e2e8f0; }
        .samples-table tr:hover { background: #2d3748; }
    """;
}
