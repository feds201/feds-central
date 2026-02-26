package frc.sim.vision;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.interpolation.TimeInterpolatableBuffer;
import edu.wpi.first.networktables.DoubleArrayEntry;
import edu.wpi.first.networktables.DoubleEntry;
import edu.wpi.first.networktables.NetworkTable;
import edu.wpi.first.networktables.NetworkTableInstance;

import java.util.Optional;

/**
 * Simulates a single Limelight camera by writing pose data to NetworkTables
 * in the format expected by the YALL library's {@code PoseEstimate} parser.
 *
 * <p><b>V0 — exact pose:</b> writes the sim's true pose directly with
 * hardcoded fake AprilTag metadata. This is a temporary stepping stone to
 * verify the full vision pipeline works in sim (NT → YALL PoseEstimate →
 * LimelightWrapper stddevs → Kalman filter). Future versions will compute
 * real tag visibility from camera FOV and field layout, and add noise
 * based on distance/angle/camera type.
 *
 * <p>The fake metadata values are chosen so {@code LimelightWrapper}'s stddev 
 * calculations produce low values instead of returning 1e6 (which would cause
 * the estimator to ignore the measurement entirely).
 *
 * <p>Publishing is gated by the camera's FPS (from {@link CameraConfig}).
 * When it's time to publish, the pose is sampled from a shared
 * {@link TimeInterpolatableBuffer} at {@code now - latency}, so the
 * published measurement is realistically stale.
 *
 * <p>TODO: Replace exact pose with a realistic noisy estimate. Plan:
 * use the field's AprilTag layout + camera FOV to determine which tags
 * are visible from the current robot pose, then add gaussian noise
 * scaled by tag count and distance (fewer/farther tags → more noise).
 * This would exercise the Kalman filter's stddev weighting in sim.
 */
public class LimelightSim {

    // Fake tag metadata — values are tuned for LimelightWrapper's stddev logic
    // to produce the tightest stddevs the pipeline allows with perfect sim data:
    //   4 tags  → triggers multi-tag reduction (×0.65) and avoids single-tag rejection
    //   0.5m dist → minimal distance scalar (1 + 0.25×0.2 = 1.05)
    //   0.02 amb → near-zero ambiguity (perfect sim pose has no solve error)
    //
    // Effective MT2 stddevs:  LL4 ~0.27m  |  LL3 ~0.34m
    // (floor is ~0.26m because base MT2_STDDEV=(0.5,0.5) × min scalar 0.52)
    private static final int FAKE_TAG_COUNT = 4;
    private static final double FAKE_TAG_SPAN = 60.0;   // degrees
    private static final double FAKE_AVG_DIST = 0.5;    // meters
    private static final double FAKE_AVG_AREA = 6.0;    // percent of image

    // Per-fiducial fake data (7 doubles each)
    // [id, txnc, tync, ta, distToCamera, distToRobot, ambiguity]
    private static final double[] FAKE_FIDUCIAL_1 = {1, 5.0, 3.0, 1.5, 0.5, 0.6, 0.02};
    private static final double[] FAKE_FIDUCIAL_2 = {2, -4.0, 2.0, 1.3, 0.5, 0.5, 0.02};
    private static final double[] FAKE_FIDUCIAL_3 = {3, 3.0, -2.0, 1.4, 0.5, 0.55, 0.02};
    private static final double[] FAKE_FIDUCIAL_4 = {4, -3.0, -3.0, 1.2, 0.5, 0.6, 0.02};

    /** Total array length: 11 base + 4 fiducials * 7 each = 39 */
    private static final int ARRAY_LENGTH = 11 + FAKE_TAG_COUNT * 7;

    private final DoubleArrayEntry botposeMt1;
    private final DoubleArrayEntry botposeMt2;
    private final DoubleEntry tvEntry;

    /** Seconds between publishes, derived from camera FPS. */
    private final double publishPeriodSec;

    /** Latency in ms, from the camera's hardware type. */
    private final double latencyMs;

    /** Timestamp of last NT publish (seconds, FPGA clock). */
    private double lastPublishTimeSec = 0.0;

    /**
     * Create a simulated Limelight and set up its NT entries.
     *
     * @param config camera configuration (name, type, mount transform)
     */
    public LimelightSim(CameraConfig config) {
        // Write to the same NT table name that the real Limelight would use.
        // LimeLight PoseEstimator reads from these exact topic names.
        NetworkTable table = NetworkTableInstance.getDefault().getTable(config.name());
        botposeMt1 = table.getDoubleArrayTopic("botpose_wpiblue").getEntry(new double[0]);
        botposeMt2 = table.getDoubleArrayTopic("botpose_orb_wpiblue").getEntry(new double[0]);
        tvEntry = table.getDoubleTopic("tv").getEntry(0.0);

        publishPeriodSec = 1.0 / config.type().fps;
        latencyMs = config.type().latencyMs;
    }

    /**
     * Potentially publish a pose update to NT, gated by this camera's FPS.
     *
     * <p>If enough time has passed since the last publish, samples the pose
     * history buffer at {@code now - latency} to get a realistically stale
     * pose and writes it to NT.
     *
     * @param poseHistory shared buffer of timestamped true poses
     * @param nowSec      current FPGA timestamp in seconds
     */
    public void update(TimeInterpolatableBuffer<Pose2d> poseHistory, double nowSec) {
        if (nowSec - lastPublishTimeSec < publishPeriodSec) {
            return; // not time to publish yet
        }
        lastPublishTimeSec = nowSec;

        // Look back in the pose history by the simulated latency amount.
        // This makes the published measurement realistically stale — the pose
        // estimator will see a pose from FAKE_LATENCY_MS ago, matching the
        // latency value we report in the array metadata.
        double lookbackSec = nowSec - latencyMs / 1000.0;
        Optional<Pose2d> maybePose = poseHistory.getSample(lookbackSec);
        if (maybePose.isEmpty()) {
            return; // buffer not populated yet (first few ticks)
        }

        publish(maybePose.get());
    }

    /**
     * Write a pose to NT in Limelight format.
     */
    private void publish(Pose2d pose) {
        double[] data = new double[ARRAY_LENGTH];

        // Pose (indices 0-5)
        data[0] = pose.getX();
        data[1] = pose.getY();
        data[2] = 0.0;  // z
        data[3] = 0.0;  // roll (degrees)
        data[4] = 0.0;  // pitch (degrees)
        data[5] = pose.getRotation().getDegrees();  // yaw (degrees)

        // Metadata (indices 6-10)
        data[6] = latencyMs;
        data[7] = FAKE_TAG_COUNT;
        data[8] = FAKE_TAG_SPAN;
        data[9] = FAKE_AVG_DIST;
        data[10] = FAKE_AVG_AREA;

        // Raw fiducials (indices 11-38) — must be present and match tagCount,
        // otherwise the YALL LimeLight parser returns an empty rawFiducials array and
        // LimelightWrapper's stddev loop sees 0 tags → returns 1e6 → pose ignored.
        System.arraycopy(FAKE_FIDUCIAL_1, 0, data, 11, 7);
        System.arraycopy(FAKE_FIDUCIAL_2, 0, data, 18, 7);
        System.arraycopy(FAKE_FIDUCIAL_3, 0, data, 25, 7);
        System.arraycopy(FAKE_FIDUCIAL_4, 0, data, 32, 7);

        // Publish to both MT1 and MT2, matching real Limelight behavior.
        // Real LLs compute these differently (MT1 = per-tag PnP, MT2 = MegaTag2
        // multi-tag solver), but V0 writes the same perfect pose to both.
        botposeMt1.set(data);
        botposeMt2.set(data);
        tvEntry.set(1.0);
    }
}
