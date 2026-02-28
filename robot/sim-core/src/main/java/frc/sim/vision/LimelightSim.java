package frc.sim.vision;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Pose3d;
import edu.wpi.first.math.geometry.Quaternion;
import edu.wpi.first.math.geometry.Rotation3d;
import edu.wpi.first.math.geometry.Transform3d;
import edu.wpi.first.math.geometry.Translation3d;
import edu.wpi.first.math.interpolation.TimeInterpolatableBuffer;
import edu.wpi.first.networktables.DoubleArrayEntry;
import edu.wpi.first.networktables.DoubleEntry;
import edu.wpi.first.networktables.NetworkTable;
import edu.wpi.first.networktables.NetworkTableInstance;
import edu.wpi.first.wpilibj.Timer;
import frc.sim.core.PhysicsWorld;
import org.ode4j.math.DQuaternion;
import org.ode4j.math.DVector3;
import org.ode4j.math.DVector3C;
import org.ode4j.ode.*;

import java.util.Optional;
import java.util.Set;

import static org.ode4j.ode.OdeHelper.*;

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
 *   <li>{@link Mode#GAME_PIECE} — builds a trimesh frustum sensor attached to the chassis body,
 *       uses ODE4J collision to detect which game pieces are inside the frustum, and publishes
 *       tv/tx/ty/ta to NT. This lets {@code IntakeSubsystem.periodic()} detect pieces in sim.</li>
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
    private final double latencyMs;

    // ── Game piece mode fields ──────────────────────────────────────────────

    private final DoubleEntry txEntry;
    private final DoubleEntry tyEntry;
    private final DoubleEntry taEntry;
    private final DGeom sensorGeom;
    private final DBody chassisBody;
    private final PhysicsWorld physicsWorld;
    private final double objectRadius;
    private final Translation3d cameraOffsetTranslation;
    private final Rotation3d inverseCameraRotation;

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
        tvEntry = table.getDoubleTopic("tv").getEntry(0.0);

        publishPeriodSec = 1.0 / config.type().fps;
        latencyMs = config.type().latencyMs;

        // Game piece fields unused in this mode
        txEntry = null;
        tyEntry = null;
        taEntry = null;
        sensorGeom = null;
        chassisBody = null;
        physicsWorld = null;
        objectRadius = 0;
        cameraOffsetTranslation = null;
        inverseCameraRotation = null;
    }

    /**
     * Create a simulated Limelight in game piece detection mode.
     *
     * <p>Builds a trimesh frustum from the camera's FOV and attaches it to the
     * chassis body as an ODE4J sensor. Each update tick (gated by {@code detectionFps}),
     * the sensor's contacts are read and the closest game piece's position is
     * converted to camera-relative angles for NT publication.
     *
     * @param config       camera configuration (name, type, mount transform)
     * @param physicsWorld the ODE4J physics world
     * @param chassisBody  the robot chassis body to attach the frustum to
     * @param nearDist     near plane distance in meters
     * @param farDist      far plane distance in meters
     * @param objectRadius radius of the game piece (meters), used for ta calculation
     * @param detectionFps detection rate (frames per second)
     */
    public LimelightSim(CameraConfig config, PhysicsWorld physicsWorld,
                         DBody chassisBody, double nearDist, double farDist,
                         double objectRadius, double detectionFps) {
        this.mode = Mode.GAME_PIECE;
        this.name = config.name();
        this.mountTransform = config.robotToCamera();
        this.mountForward = new Translation3d(1.0, 0, 0).rotateBy(config.robotToCamera().getRotation());
        this.physicsWorld = physicsWorld;
        this.chassisBody = chassisBody;
        this.objectRadius = objectRadius;
        this.cameraOffsetTranslation = config.robotToCamera().getTranslation();
        this.inverseCameraRotation = config.robotToCamera().getRotation().unaryMinus();

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

        // Build the frustum trimesh and attach to chassis with camera offset
        sensorGeom = buildFrustum(physicsWorld, chassisBody, config.type(), nearDist, farDist,
                config.robotToCamera());
        physicsWorld.registerSensor(sensorGeom);
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

    /** Package-private accessor for the sensor trimesh geom (used by tests). */
    DGeom getSensorGeom() {
        return sensorGeom;
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

        double lookbackSec = nowSec - latencyMs / 1000.0;
        Optional<Pose2d> maybePose = poseHistory.getSample(lookbackSec);
        if (maybePose.isEmpty()) {
            return;
        }

        publishAprilTag(maybePose.get());
    }

    /**
     * Enable or disable the sensor geom based on FPS gating.
     * Must be called BEFORE {@code physicsWorld.step()} so the sensor
     * participates in collision detection on the tick it will be read.
     */
    public void prepareGamePiece() {
        if (mode != Mode.GAME_PIECE) return;

        double nowSec = Timer.getFPGATimestamp();
        if (shouldPublish(nowSec, lastPublishTimeSec, publishPeriodSec)) {
            sensorGeom.enable();
        } else {
            sensorGeom.disable();
        }
    }

    /**
     * Read sensor contacts and publish tv/tx/ty/ta to NT.
     * Must be called AFTER {@code physicsWorld.step()}.
     */
    public void updateGamePiece() {
        if (mode != Mode.GAME_PIECE) return;
        if (!sensorGeom.isEnabled()) return;

        lastPublishTimeSec = Timer.getFPGATimestamp();

        Set<DBody> contacts = physicsWorld.getSensorContacts(sensorGeom);
        if (contacts.isEmpty()) {
            tvEntry.set(0.0);
            txEntry.set(0.0);
            tyEntry.set(0.0);
            taEntry.set(0.0);
            return;
        }

        DetectionResult result = computeDetection(contacts, chassisBody,
                cameraOffsetTranslation, inverseCameraRotation, objectRadius);

        tvEntry.set(1.0);
        txEntry.set(result.tx());
        tyEntry.set(result.ty());
        taEntry.set(result.ta());
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
     * Select the closest contact body and compute tx/ty/ta angles.
     *
     * <p>Finds the body nearest to the camera (not chassis center), transforms its
     * position into camera-relative coordinates, and computes Limelight-convention
     * angles: tx positive = target right of crosshair, ty positive = target above.
     *
     * <p>Package-private for testing.
     *
     * @param contacts               non-empty set of detected bodies
     * @param chassisBody            the robot chassis body (for coordinate transforms)
     * @param cameraOffset           camera mount position relative to chassis
     * @param inverseCameraRotation  inverse of camera mount rotation
     * @param objectRadius           game piece radius (for ta calculation)
     * @return detection result with tx, ty (degrees) and ta (apparent area percentage)
     */
    static DetectionResult computeDetection(
            Set<DBody> contacts,
            DBody chassisBody,
            Translation3d cameraOffset,
            Rotation3d inverseCameraRotation,
            double objectRadius) {
        // Compute camera world position from chassis body + mount offset
        DVector3 camWorldPos = new DVector3();
        chassisBody.getRelPointPos(
                cameraOffset.getX(), cameraOffset.getY(), cameraOffset.getZ(),
                camWorldPos);

        // Find the closest contact body (distance from camera, not chassis center)
        DBody closest = null;
        double closestDistSq = Double.MAX_VALUE;
        for (DBody body : contacts) {
            DVector3C p = body.getPosition();
            double dx = p.get0() - camWorldPos.get0();
            double dy = p.get1() - camWorldPos.get1();
            double dz = p.get2() - camWorldPos.get2();
            double d = dx * dx + dy * dy + dz * dz;
            if (d < closestDistSq) {
                closestDistSq = d;
                closest = body;
            }
        }

        // Get game piece position in chassis body frame, then camera frame
        DVector3 bodyLocal = new DVector3();
        chassisBody.getPosRelPoint(closest.getPosition(), bodyLocal);

        double dx = bodyLocal.get0() - cameraOffset.getX();
        double dy = bodyLocal.get1() - cameraOffset.getY();
        double dz = bodyLocal.get2() - cameraOffset.getZ();
        Translation3d camDelta = new Translation3d(dx, dy, dz).rotateBy(inverseCameraRotation);

        double tx = Math.toDegrees(Math.atan2(-camDelta.getY(), camDelta.getX()));
        double ty = Math.toDegrees(Math.atan2(camDelta.getZ(), camDelta.getX()));
        double ta = Math.PI * objectRadius * objectRadius / closestDistSq * AREA_SCALE;

        return new DetectionResult(tx, ty, ta);
    }

    // ── Frustum construction ────────────────────────────────────────────────

    /**
     * Build a trimesh frustum geom attached to the chassis body.
     *
     * <p>The frustum represents the camera's field of view as a 3D volume.
     * It is oriented along the chassis's local +X axis (forward).
     *
     * <pre>
     * 8 vertices: 4 at near plane, 4 at far plane
     * 12 triangles: 2 per face x 6 faces
     * </pre>
     */
    static DGeom buildFrustum(PhysicsWorld physicsWorld, DBody chassisBody,
                                       LimelightType type, double nearDist, double farDist,
                                       Transform3d robotToCamera) {
        double hFovRad = Math.toRadians(type.horizontalFovDegrees);
        double vFovRad = Math.toRadians(type.verticalFovDegrees);

        double nearHalfW = nearDist * Math.tan(hFovRad / 2.0);
        double nearHalfH = nearDist * Math.tan(vFovRad / 2.0);
        double farHalfW = farDist * Math.tan(hFovRad / 2.0);
        double farHalfH = farDist * Math.tan(vFovRad / 2.0);

        // Vertices: X = forward, Y = left, Z = up (WPILib/ODE4J convention)
        // Near plane (indices 0-3)
        // Far plane (indices 4-7)
        float[] vertices = {
            // Near plane
            (float) nearDist, (float) nearHalfW,  (float) nearHalfH,   // 0: near top-left
            (float) nearDist, (float) -nearHalfW, (float) nearHalfH,   // 1: near top-right
            (float) nearDist, (float) -nearHalfW, (float) -nearHalfH,  // 2: near bottom-right
            (float) nearDist, (float) nearHalfW,  (float) -nearHalfH,  // 3: near bottom-left
            // Far plane
            (float) farDist,  (float) farHalfW,   (float) farHalfH,    // 4: far top-left
            (float) farDist,  (float) -farHalfW,  (float) farHalfH,    // 5: far top-right
            (float) farDist,  (float) -farHalfW,  (float) -farHalfH,   // 6: far bottom-right
            (float) farDist,  (float) farHalfW,   (float) -farHalfH,   // 7: far bottom-left
        };

        // 12 triangles (6 faces x 2), winding order for outward-facing normals
        int[] indices = {
            // Near face (facing -X)
            0, 2, 1,
            0, 3, 2,
            // Far face (facing +X)
            4, 5, 6,
            4, 6, 7,
            // Top face (facing +Z)
            0, 1, 5,
            0, 5, 4,
            // Bottom face (facing -Z)
            3, 6, 2,
            3, 7, 6,
            // Left face (facing +Y)
            0, 4, 7,
            0, 7, 3,
            // Right face (facing -Y)
            1, 2, 6,
            1, 6, 5,
        };

        DTriMeshData meshData = OdeHelper.createTriMeshData();
        meshData.build(vertices, indices);

        DGeom trimesh = OdeHelper.createTriMesh(physicsWorld.getSpace(), meshData, null, null, null);
        trimesh.setBody(chassisBody);

        // Apply camera mount offset (position and rotation relative to chassis body)
        Translation3d t = robotToCamera.getTranslation();
        trimesh.setOffsetPosition(t.getX(), t.getY(), t.getZ());
        Quaternion q = robotToCamera.getRotation().getQuaternion();
        trimesh.setOffsetQuaternion(new DQuaternion(q.getW(), q.getX(), q.getY(), q.getZ()));

        return trimesh;
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
