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
 * <p>The fake metadata values (2 tags, 2m distance, 0.1 ambiguity) are
 * chosen so {@code LimelightWrapper}'s stddev calculations produce low
 * values instead of returning 1e6 (which would cause the estimator to
 * ignore the measurement entirely).
 *
 * <p>Publishing is gated by the camera's FPS (from {@link LimelightType}).
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

    // Fake tag metadata — values are tuned for LimelightWrapper's stddev logic:
    //   2 tags  → avoids the "1 tag + far distance = reject" cutoff
    //   2m dist → moderate distance scalar (not too close, not too far)
    //   0.1 amb → well under the 0.3 ambiguity rejection threshold
    private static final int FAKE_TAG_COUNT = 2;
    private static final double FAKE_TAG_SPAN = 30.0;   // degrees
    private static final double FAKE_AVG_DIST = 2.0;    // meters
    private static final double FAKE_AVG_AREA = 1.5;    // percent of image

    // Total simulated latency (capture + pipeline), in milliseconds.
    // Real Limelight latency ≈ capture (~11ms) + pipeline (varies by resolution/pipeline).
    // 25ms is a reasonable estimate for an AprilTag pipeline on LL3/LL4.
    // Source: https://docs.limelightvision.io/docs/docs-limelight/software-change-log
    //         https://www.chiefdelphi.com/t/determining-limelight-latency/411597
    //
    // TODO: Add gaussian variation to simulate real-world jitter. Something like:
    //   latencyMs = MEAN_LATENCY_MS + random.nextGaussian() * LATENCY_STDDEV_MS
    //   latencyMs = Math.max(latencyMs, MIN_LATENCY_MS)
    //   with mean=25, stddev=5, min=15.
    private static final double FAKE_LATENCY_MS = 25.0;
    private static final double FAKE_LATENCY_SEC = FAKE_LATENCY_MS / 1000.0;

    // Per-fiducial fake data (7 doubles each)
    // [id, txnc, tync, ta, distToCamera, distToRobot, ambiguity]
    private static final double[] FAKE_FIDUCIAL_1 = {1, 5.0, 3.0, 0.8, 2.0, 2.1, 0.1};
    private static final double[] FAKE_FIDUCIAL_2 = {2, -4.0, 2.0, 0.7, 2.0, 2.0, 0.1};

    /** Total array length: 11 base + 2 fiducials * 7 each = 25 */
    private static final int ARRAY_LENGTH = 11 + FAKE_TAG_COUNT * 7;

    private final DoubleArrayEntry botposeMt1;
    private final DoubleArrayEntry botposeMt2;
    private final DoubleEntry tvEntry;

    /** Seconds between publishes, derived from camera FPS. */
    private final double publishPeriodSec;

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

        publishPeriodSec = 1.0 / config.type().fps();
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
        Optional<Pose2d> maybePose = poseHistory.getSample(nowSec - FAKE_LATENCY_SEC);
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
        data[6] = FAKE_LATENCY_MS;
        data[7] = FAKE_TAG_COUNT;
        data[8] = FAKE_TAG_SPAN;
        data[9] = FAKE_AVG_DIST;
        data[10] = FAKE_AVG_AREA;

        // Raw fiducials (indices 11-24) — must be present and match tagCount,
        // otherwise the YALL LimeLight parser returns an empty rawFiducials array and
        // LimelightWrapper's stddev loop sees 0 tags → returns 1e6 → pose ignored.
        System.arraycopy(FAKE_FIDUCIAL_1, 0, data, 11, 7);
        System.arraycopy(FAKE_FIDUCIAL_2, 0, data, 18, 7);

        // Write identical data to both MT1 and MT2 — in V0 there's no
        // difference. Real limelights compute these differently (MT1 = per-tag
        // PnP, MT2 = MegaTag2 multi-tag solver).
        botposeMt1.set(data);
        botposeMt2.set(data);
        tvEntry.set(1.0);
    }
}
