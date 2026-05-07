package frc.sim.vision;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Pose3d;
import edu.wpi.first.math.geometry.Rotation3d;
import edu.wpi.first.math.geometry.Transform3d;
import edu.wpi.first.math.geometry.Translation3d;
import edu.wpi.first.math.interpolation.TimeInterpolatableBuffer;
import edu.wpi.first.networktables.DoubleArrayEntry;
import edu.wpi.first.networktables.DoubleEntry;
import edu.wpi.first.networktables.NetworkTable;
import edu.wpi.first.networktables.NetworkTableInstance;
import edu.wpi.first.wpilibj.Timer;

import java.util.List;
import java.util.Optional;
import java.util.function.BooleanSupplier;
import java.util.function.Supplier;

/**
 * Simulates a single Limelight camera by writing data to NetworkTables
 * in the format expected by the YALL library's {@code PoseEstimate} parser
 * (AprilTag mode) or by {@code LimelightHelpers.getTV/getTX/getTY/getTA}
 * (game piece mode).
 *
 * <h3>Modes</h3>
 * <ul>
 *   <li>{@link Mode#APRIL_TAG} — publishes sim pose as botpose_wpiblue / botpose_orb_wpiblue.
 *       Uses a shared {@link TimeInterpolatableBuffer} for latency lookback.</li>
 *   <li>{@link Mode#GAME_PIECE} — gated by a {@link BooleanSupplier} (e.g. is the
 *       ball-tracking command scheduled). When inactive, does nothing. When active,
 *       performs a pure-Java frustum test against caller-supplied game-piece positions
 *       at the configured FPS, and publishes tv/tx/ty/ta to NT.</li>
 * </ul>
 */
public class LimelightSim {

    /** Operating mode for the simulated Limelight. */
    public enum Mode {
        APRIL_TAG,
        GAME_PIECE
    }

    /** Result of game piece detection: angles and apparent area. Package-private for testing. */
    record DetectionResult(double tx, double ty, double ta) {}

    // ── AprilTag mode constants ─────────────────────────────────────────────

    // Fake tag metadata — values are tuned for LimelightWrapper's stddev logic
    // to produce the tightest stddevs the pipeline allows with perfect sim data:
    //   4 tags  → triggers multi-tag reduction (×0.65) and avoids single-tag rejection
    //   0.5m dist → minimal distance scalar (1 + 0.25×0.2 = 1.05)
    //   0.02 amb → near-zero ambiguity (perfect sim pose has no solve error)
    //
    // Effective MT2 stddevs:  LL4 ~0.27m  |  LL3 ~0.34m
    // (floor is ~0.26m because base MT2_STDDEV=(0.5,0.5) × min scalar 0.52)
    private static final int FAKE_TAG_COUNT = 4;
    private static final double FAKE_TAG_SPAN = 60.0;     // degrees
    private static final double FAKE_AVG_DIST = 0.5;      // meters
    private static final double FAKE_AVG_AREA = 6.0;      // percent of image

    // Per-fiducial fake data (7 doubles each):
    // [id, txnc, tync, ta, distToCamera, distToRobot, ambiguity]
    private static final double[] FAKE_FIDUCIAL_1 = {1, 5.0, 3.0, 1.5, 0.5, 0.6, 0.02};
    private static final double[] FAKE_FIDUCIAL_2 = {2, -4.0, 2.0, 1.3, 0.5, 0.5, 0.02};
    private static final double[] FAKE_FIDUCIAL_3 = {3, 3.0, -2.0, 1.4, 0.5, 0.55, 0.02};
    private static final double[] FAKE_FIDUCIAL_4 = {4, -3.0, -3.0, 1.2, 0.5, 0.6, 0.02};

    /** Total array length: 11 base + 4 fiducials * 7 each = 39 */
    private static final int ARRAY_LENGTH = 11 + FAKE_TAG_COUNT * 7;

    // ── Shared fields ───────────────────────────────────────────────────────

    private final String name;
    private final DoubleEntry tvEntry;
    private final Mode mode;
    private final double publishPeriodSec;
    private double lastPublishTimeSec = 0.0;

    // ── Direction line fields (precomputed from mount transform) ────────────

    private final Transform3d mountTransform;
    private final Translation3d mountForward;

    // ── AprilTag mode fields ────────────────────────────────────────────────

    private final DoubleArrayEntry botposeMt1;
    private final DoubleArrayEntry botposeMt2;
    private final DoubleEntry hbEntry;
    private double heartbeat = 0.0;
    private final double latencyMs;

    // ── Game piece mode fields ──────────────────────────────────────────────

    private final DoubleEntry txEntry;
    private final DoubleEntry tyEntry;
    private final DoubleEntry taEntry;
    private final Translation3d cameraOffsetTranslation;
    private final Rotation3d inverseCameraRotation;
    private final double nearDist;
    private final double farDist;
    private final double objectRadius;
    private final double hFovHalfRad;
    private final double vFovHalfRad;
    private final BooleanSupplier activeSupplier;
    private boolean wasActive = false;

    // Scale factor to convert geometric solid angle to Limelight "ta" percentage.
    // ta = (pi * r^2 / dist^2) * areaScale. Tuned so a ball at ~1m reads ~1-3%.
    private static final double AREA_SCALE = 100.0;

    // ── Constructors ────────────────────────────────────────────────────────

    /**
     * Create a simulated Limelight in AprilTag mode.
     *
     * @param config camera configuration (name, type, mount transform)
     */
    public LimelightSim(CameraConfig config) {
        this.mode = Mode.APRIL_TAG;
        this.name = config.name();
        this.mountTransform = config.robotToCamera();
        this.mountForward = new Translation3d(1.0, 0, 0).rotateBy(config.robotToCamera().getRotation());

        NetworkTable table = NetworkTableInstance.getDefault().getTable(config.name());
        botposeMt1 = table.getDoubleArrayTopic("botpose_wpiblue").getEntry(new double[0]);
        botposeMt2 = table.getDoubleArrayTopic("botpose_orb_wpiblue").getEntry(new double[0]);
        hbEntry = table.getDoubleTopic("hb").getEntry(0.0);
        tvEntry = table.getDoubleTopic("tv").getEntry(0.0);

        publishPeriodSec = 1.0 / config.type().fps;
        latencyMs = config.type().latencyMs;

        // Game piece fields unused in this mode
        txEntry = null;
        tyEntry = null;
        taEntry = null;
        cameraOffsetTranslation = null;
        inverseCameraRotation = null;
        nearDist = 0;
        farDist = 0;
        objectRadius = 0;
        hFovHalfRad = 0;
        vFovHalfRad = 0;
        activeSupplier = null;
    }

    /**
     * Create a simulated Limelight in game piece detection mode.
     *
     * <p>No physics engine involvement — when {@code activeSupplier} returns true,
     * {@link #updateGamePiece(Pose2d, Supplier)} iterates caller-supplied piece
     * positions and publishes the closest one inside the camera frustum. When
     * {@code activeSupplier} returns false, {@link #updateGamePiece} is a no-op
     * (NT fields are zeroed once on the deactivation edge).
     *
     * @param config         camera configuration (name, type, mount transform)
     * @param nearDist       near plane distance in meters
     * @param farDist        far plane distance in meters
     * @param objectRadius   radius of the game piece (meters), used for ta calculation
     * @param detectionFps   detection rate (frames per second)
     * @param activeSupplier gate — when false, no work is done and NT is silent
     */
    public LimelightSim(CameraConfig config, double nearDist, double farDist,
                        double objectRadius, double detectionFps,
                        BooleanSupplier activeSupplier) {
        this.mode = Mode.GAME_PIECE;
        this.name = config.name();
        this.mountTransform = config.robotToCamera();
        this.mountForward = new Translation3d(1.0, 0, 0).rotateBy(config.robotToCamera().getRotation());
        this.cameraOffsetTranslation = config.robotToCamera().getTranslation();
        this.inverseCameraRotation = config.robotToCamera().getRotation().unaryMinus();
        this.nearDist = nearDist;
        this.farDist = farDist;
        this.objectRadius = objectRadius;
        this.hFovHalfRad = Math.toRadians(config.type().horizontalFovDegrees) / 2.0;
        this.vFovHalfRad = Math.toRadians(config.type().verticalFovDegrees) / 2.0;
        this.activeSupplier = activeSupplier;

        NetworkTable table = NetworkTableInstance.getDefault().getTable(config.name());
        tvEntry = table.getDoubleTopic("tv").getEntry(0.0);
        txEntry = table.getDoubleTopic("tx").getEntry(0.0);
        tyEntry = table.getDoubleTopic("ty").getEntry(0.0);
        taEntry = table.getDoubleTopic("ta").getEntry(0.0);

        publishPeriodSec = 1.0 / detectionFps;
        latencyMs = 0; // unused in game piece mode

        // AprilTag fields unused in this mode
        botposeMt1 = null;
        botposeMt2 = null;
        hbEntry = null;
    }

    // ── Public accessors ────────────────────────────────────────────────────

    /** Get the NT table name for this camera. */
    public String getName() {
        return name;
    }

    /**
     * Compute the camera direction line in field coordinates.
     *
     * @param robotPose the robot's current 3D pose in field coordinates
     * @return two-element array: [cameraPose, endPose] representing a 1m line
     */
    public Pose3d[] getDirectionLine(Pose3d robotPose) {
        Pose3d camPose = robotPose.transformBy(mountTransform);
        Rotation3d camRot = camPose.getRotation();
        Translation3d worldForward = mountForward.rotateBy(robotPose.getRotation());
        Pose3d endPose = new Pose3d(
                camPose.getX() + worldForward.getX(),
                camPose.getY() + worldForward.getY(),
                camPose.getZ() + worldForward.getZ(),
                camRot);
        return new Pose3d[]{camPose, endPose};
    }

    /**
     * Get the camera's world-frame Pose3d for telemetry visualization.
     *
     * @param robotPose the robot's current 3D pose
     * @return camera pose in world frame
     */
    public Pose3d getCameraPose3d(Pose3d robotPose) {
        return robotPose.transformBy(mountTransform);
    }

    // ── Update methods ──────────────────────────────────────────────────────

    /**
     * Update for AprilTag mode. Publishes pose to NT gated by camera FPS.
     *
     * @param poseHistory shared buffer of timestamped true poses
     * @param nowSec      current FPGA timestamp in seconds
     */
    public void update(TimeInterpolatableBuffer<Pose2d> poseHistory, double nowSec) {
        if (mode != Mode.APRIL_TAG) return;

        if (nowSec - lastPublishTimeSec < publishPeriodSec) {
            return;
        }
        lastPublishTimeSec = nowSec;

        // Heartbeat ticks at camera FPS regardless of whether we have a pose to publish —
        // real Limelights bump hb every frame whether or not tags are visible.
        heartbeat += 1.0;
        hbEntry.set(heartbeat);

        double lookbackSec = nowSec - latencyMs / 1000.0;
        Optional<Pose2d> maybePose = poseHistory.getSample(lookbackSec);
        if (maybePose.isEmpty()) {
            return;
        }

        publishAprilTag(maybePose.get());
    }

    /**
     * Update for game piece mode. Gated by {@code activeSupplier} and detection FPS.
     *
     * <p>When the activation gate is false, this is a no-op (the NT fields are
     * zeroed once on the transition from active → inactive so stale values don't
     * linger). When active and the FPS period has elapsed, iterates piece
     * positions, filters to those inside the camera frustum, selects the closest,
     * and publishes tv/tx/ty/ta.
     *
     * @param chassisPose              current robot pose (world frame)
     * @param piecePositionsSupplier   lazy supplier of active piece world positions;
     *                                 only called when a publish is actually due
     */
    public void updateGamePiece(Pose2d chassisPose,
                                Supplier<List<Translation3d>> piecePositionsSupplier) {
        if (mode != Mode.GAME_PIECE) return;

        boolean nowActive = activeSupplier.getAsBoolean();
        if (!nowActive) {
            if (wasActive) {
                tvEntry.set(0.0);
                txEntry.set(0.0);
                tyEntry.set(0.0);
                taEntry.set(0.0);
                wasActive = false;
            }
            return;
        }
        wasActive = true;

        double nowSec = Timer.getFPGATimestamp();
        if (!shouldPublish(nowSec, lastPublishTimeSec, publishPeriodSec)) return;
        lastPublishTimeSec = nowSec;

        List<Translation3d> pieces = piecePositionsSupplier.get();

        double yaw = chassisPose.getRotation().getRadians();
        double cos = Math.cos(yaw);
        double sin = Math.sin(yaw);
        double chassisX = chassisPose.getX();
        double chassisY = chassisPose.getY();

        Translation3d best = null;
        double bestDistSq = Double.MAX_VALUE;

        for (Translation3d world : pieces) {
            Translation3d camDelta = worldToCameraFrame(
                    world, chassisX, chassisY, cos, sin,
                    cameraOffsetTranslation, inverseCameraRotation);
            if (!inFrustum(camDelta, nearDist, farDist, hFovHalfRad, vFovHalfRad)) continue;

            double d = camDelta.getX() * camDelta.getX()
                    + camDelta.getY() * camDelta.getY()
                    + camDelta.getZ() * camDelta.getZ();
            if (d < bestDistSq) {
                bestDistSq = d;
                best = camDelta;
            }
        }

        if (best == null) {
            tvEntry.set(0.0);
            txEntry.set(0.0);
            tyEntry.set(0.0);
            taEntry.set(0.0);
            return;
        }

        DetectionResult r = computeDetectionFromCameraFrame(best, objectRadius);
        tvEntry.set(1.0);
        txEntry.set(r.tx());
        tyEntry.set(r.ty());
        taEntry.set(r.ta());
    }

    // ── Extracted logic (package-private for testing) ───────────────────────

    /**
     * Determine whether enough time has elapsed since the last publish.
     * Package-private for testing.
     */
    static boolean shouldPublish(double nowSec, double lastPublishTimeSec, double publishPeriodSec) {
        return nowSec - lastPublishTimeSec >= publishPeriodSec;
    }

    /**
     * Transform a world-frame point into the camera's local frame.
     * Package-private for testing.
     */
    static Translation3d worldToCameraFrame(Translation3d world,
                                            double chassisX, double chassisY,
                                            double cos, double sin,
                                            Translation3d cameraOffset,
                                            Rotation3d inverseCameraRotation) {
        double dx = world.getX() - chassisX;
        double dy = world.getY() - chassisY;
        double localX = dx * cos + dy * sin;
        double localY = -dx * sin + dy * cos;
        double localZ = world.getZ();
        double fx = localX - cameraOffset.getX();
        double fy = localY - cameraOffset.getY();
        double fz = localZ - cameraOffset.getZ();
        return new Translation3d(fx, fy, fz).rotateBy(inverseCameraRotation);
    }

    /**
     * Check whether a camera-frame point is inside the view frustum.
     * Package-private for testing.
     */
    static boolean inFrustum(Translation3d camDelta, double near, double far,
                             double hFovHalfRad, double vFovHalfRad) {
        double x = camDelta.getX();
        if (x < near || x > far) return false;
        double angleX = Math.atan2(-camDelta.getY(), x);
        if (Math.abs(angleX) > hFovHalfRad) return false;
        double angleY = Math.atan2(camDelta.getZ(), x);
        return Math.abs(angleY) <= vFovHalfRad;
    }

    /**
     * Compute tx/ty/ta from a camera-frame delta. Limelight convention:
     * tx positive = target right of crosshair, ty positive = target above.
     * Package-private for testing.
     */
    static DetectionResult computeDetectionFromCameraFrame(Translation3d camDelta, double objectRadius) {
        double tx = Math.toDegrees(Math.atan2(-camDelta.getY(), camDelta.getX()));
        double ty = Math.toDegrees(Math.atan2(camDelta.getZ(), camDelta.getX()));
        double distSq = camDelta.getX() * camDelta.getX()
                + camDelta.getY() * camDelta.getY()
                + camDelta.getZ() * camDelta.getZ();
        double ta = Math.PI * objectRadius * objectRadius / distSq * AREA_SCALE;
        return new DetectionResult(tx, ty, ta);
    }

    // ── AprilTag publishing (unchanged from original) ───────────────────────

    private void publishAprilTag(Pose2d pose) {
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
        // multi-tag solver), but we write the same perfect pose to both.
        botposeMt1.set(data);
        botposeMt2.set(data);
        tvEntry.set(1.0);
    }
}
