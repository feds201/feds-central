package frc.rtu;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;
import java.util.Map;

/**
 * Persists test results to a local SQLite database for historical analysis.
 */
public final class TestHistoryDatabase {

    private final String dbUrl;

    public TestHistoryDatabase(String dbPath) {
        this.dbUrl = "jdbc:sqlite:" + dbPath;
        init();
    }

    private void init() {
        try (Connection conn = DriverManager.getConnection(dbUrl);
             Statement stmt = conn.createStatement()) {
            
            // Results table
            stmt.execute("""
                CREATE TABLE IF NOT EXISTS results (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TEXT,
                    subsystem TEXT,
                    action TEXT,
                    description TEXT,
                    status TEXT,
                    duration_ms REAL,
                    error_msg TEXT
                )
                """);

            // Alerts table
            stmt.execute("""
                CREATE TABLE IF NOT EXISTS alerts (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    result_id INTEGER,
                    level TEXT,
                    message TEXT,
                    FOREIGN KEY(result_id) REFERENCES results(id)
                )
                """);

            // Data samples table (1D)
            stmt.execute("""
                CREATE TABLE IF NOT EXISTS samples (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    result_id INTEGER,
                    profile_name TEXT,
                    timestamp_ms REAL,
                    value REAL,
                    FOREIGN KEY(result_id) REFERENCES results(id)
                )
                """);

            // Multi-dimensional data samples table
            // values stored as comma-separated string for simplicity in SQLite 
            // (or could be separate table with sample_id FK, but distinct arrays are easier to query this way)
            stmt.execute("""
                CREATE TABLE IF NOT EXISTS samples_nd (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    result_id INTEGER,
                    profile_name TEXT,
                    timestamp_ms REAL,
                    values_array TEXT,
                    FOREIGN KEY(result_id) REFERENCES results(id)
                )
                """);

        } catch (SQLException e) {
            System.err.println("[RTU] SQLite init failed: " + e.getMessage());
        }
    }

    public synchronized void saveResults(List<TestResult> results) {
        try (Connection conn = DriverManager.getConnection(dbUrl)) {
            conn.setAutoCommit(false);
            
            String insertResult = "INSERT INTO results (timestamp, subsystem, action, description, status, duration_ms, error_msg) VALUES (?,?,?,?,?,?,?)";
            String insertAlert = "INSERT INTO alerts (result_id, level, message) VALUES (?,?,?)";
            String insertSample = "INSERT INTO samples (result_id, profile_name, timestamp_ms, value) VALUES (?,?,?,?)";
            String insertSampleNd = "INSERT INTO samples_nd (result_id, profile_name, timestamp_ms, values_array) VALUES (?,?,?,?)";

            try (PreparedStatement resStmt = conn.prepareStatement(insertResult, Statement.RETURN_GENERATED_KEYS);
                 PreparedStatement alertStmt = conn.prepareStatement(insertAlert);
                 PreparedStatement sampleStmt = conn.prepareStatement(insertSample);
                 PreparedStatement sampleNdStmt = conn.prepareStatement(insertSampleNd)) {

                for (TestResult r : results) {
                    resStmt.setString(1, r.getTimestamp().toString());
                    resStmt.setString(2, r.getSubsystemName());
                    resStmt.setString(3, r.getActionName());
                    resStmt.setString(4, r.getDescription());
                    resStmt.setString(5, r.getStatus().name());
                    resStmt.setDouble(6, r.getDurationMs());
                    resStmt.setString(7, r.getError() != null ? r.getError().toString() : null);
                    resStmt.executeUpdate();

                    long resultId;
                    try (var keys = resStmt.getGeneratedKeys()) {
                        if (keys.next()) {
                            resultId = keys.getLong(1);
                        } else continue;
                    }

                    for (TestResult.Alert alert : r.getAlerts()) {
                        alertStmt.setLong(1, resultId);
                        alertStmt.setString(2, alert.level().name());
                        alertStmt.setString(3, alert.message());
                        alertStmt.addBatch();
                    }
                    alertStmt.executeBatch();

                    for (Map.Entry<String, List<TestResult.DataSample>> profile : r.getDataProfiles().entrySet()) {
                        for (TestResult.DataSample sample : profile.getValue()) {
                            sampleStmt.setLong(1, resultId);
                            sampleStmt.setString(2, profile.getKey());
                            sampleStmt.setDouble(3, sample.timestampMs());
                            sampleStmt.setDouble(4, sample.value());
                            sampleStmt.addBatch();
                        }
                    }
                    sampleStmt.executeBatch();

                    for (Map.Entry<String, List<TestResult.DataSampleNd>> profile : r.getDataProfilesNd().entrySet()) {
                        for (TestResult.DataSampleNd sample : profile.getValue()) {
                            sampleNdStmt.setLong(1, resultId);
                            sampleNdStmt.setString(2, profile.getKey());
                            sampleNdStmt.setDouble(3, sample.timestampMs());
                            
                            // Serialize double[] to CSV string
                            StringBuilder sb = new StringBuilder();
                            for (double v : sample.values()) {
                                if (sb.length() > 0) sb.append(",");
                                sb.append(v);
                            }
                            sampleNdStmt.setString(4, sb.toString());
                            sampleNdStmt.addBatch();
                        }
                    }
                    sampleNdStmt.executeBatch();
                }
                conn.commit();
            }
        } catch (SQLException e) {
            System.err.println("[RTU] SQLite save failed: " + e.getMessage());
        }
    }
}
