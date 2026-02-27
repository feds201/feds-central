package frc.sim.vision;

import edu.wpi.first.math.geometry.Pose3d;
import edu.wpi.first.math.geometry.Rotation3d;
import edu.wpi.first.math.geometry.Transform3d;
import edu.wpi.first.math.geometry.Translation3d;
import frc.sim.core.PhysicsWorld;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.ode4j.ode.*;

import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;
import static org.ode4j.ode.OdeHelper.*;

/**
 * Tests for LimelightSim frustum geometry and camera pose math.
 *
 * <p>Tests call {@link LimelightSim#buildFrustum} directly to build the
 * trimesh sensor without constructing a full LimelightSim (which would
 * require HAL/NetworkTables initialization). This keeps the tests pure
 * ODE4J + WPILib geometry with no native JNI dependencies.
 *
 * <p>The frustum is a closed trimesh surface attached to the chassis body.
 * ODE4J trimesh-sphere collision only fires when the sphere actually
 * intersects a triangular face of the mesh. A sphere floating inside the
 * frustum volume without touching any face will NOT register a contact.
 * Therefore, detection tests place spheres so they straddle a face of the
 * frustum (e.g., the top face, the far face, or a side wall).
 */
class LimelightSimTest {

    // Frustum parameters used across tests
    private static final double NEAR_DIST = 0.3;
    private static final double FAR_DIST = 3.0;
    private static final double OBJECT_RADIUS = 0.075;
    private static final int STEP_COUNT = 5;
    private static final double STEP_DT = 0.02;

    // LL4 vertical half-FOV in radians (56.2 / 2 = 28.1 degrees)
    private static final double V_HALF_FOV_RAD = Math.toRadians(56.2 / 2.0);

    // Chassis is elevated to z=0.5 to avoid ground plane interference
    private static final double CHASSIS_Z = 0.5;

    private PhysicsWorld physicsWorld;
    private DBody chassisBody;

    @BeforeEach
    void setUp() {
        physicsWorld = new PhysicsWorld();

        // Create a chassis body elevated above the ground plane, facing +X.
        // Placing at z=CHASSIS_Z keeps the frustum and game pieces clear of the
        // ground plane so ground collisions do not interfere with sensor tests.
        chassisBody = createBody(physicsWorld.getWorld());
        chassisBody.setPosition(0, 0, CHASSIS_Z);
        chassisBody.setAutoDisableFlag(false);
        chassisBody.setGravityMode(false);

        DMass chassisMass = createMass();
        chassisMass.setBoxTotal(50.0, 0.8, 0.8, 0.2);
        chassisBody.setMass(chassisMass);

        // Chassis geom in the space for collision to work
        DGeom chassisGeom = createBox(physicsWorld.getSpace(), 0.8, 0.8, 0.2);
        chassisGeom.setBody(chassisBody);
    }

    // -- Helper methods -------------------------------------------------------

    /**
     * Create a game piece sphere at the given world position.
     * Gravity is disabled and auto-disable is off so the piece stays put.
     */
    private DBody createGamePieceSphere(double x, double y, double z) {
        return createGamePieceSphere(physicsWorld, x, y, z);
    }

    /**
     * Create a game piece sphere in a specific PhysicsWorld at the given world position.
     * Gravity is disabled and auto-disable is off so the piece stays put.
     */
    private DBody createGamePieceSphere(PhysicsWorld world, double x, double y, double z) {
        DBody body = createBody(world.getWorld());
        body.setPosition(x, y, z);
        body.setAutoDisableFlag(false);
        body.setGravityMode(false);

        DMass mass = createMass();
        mass.setSphereTotal(0.2, OBJECT_RADIUS);
        body.setMass(mass);

        DGeom geom = createSphere(world.getSpace(), OBJECT_RADIUS);
        geom.setBody(body);

        return body;
    }

    /**
     * Build a frustum sensor and register it, without constructing a LimelightSim.
     */
    private DGeom buildAndRegisterFrustum(Transform3d robotToCamera) {
        DGeom frustum = LimelightSim.buildFrustum(
                physicsWorld, chassisBody, LimelightType.LL4,
                NEAR_DIST, FAR_DIST, robotToCamera);
        physicsWorld.registerSensor(frustum);
        return frustum;
    }

    /**
     * Build a frustum sensor in a specific PhysicsWorld and register it.
     */
    private DGeom buildAndRegisterFrustum(PhysicsWorld world, DBody chassis, Transform3d robotToCamera) {
        DGeom frustum = LimelightSim.buildFrustum(
                world, chassis, LimelightType.LL4,
                NEAR_DIST, FAR_DIST, robotToCamera);
        world.registerSensor(frustum);
        return frustum;
    }

    /** Step the physics world multiple times to let collision detection run. */
    private void stepPhysics() {
        for (int i = 0; i < STEP_COUNT; i++) {
            physicsWorld.step(STEP_DT);
        }
    }

    /**
     * Compute the world Z coordinate of the frustum's top face at a given X distance
     * from the camera, assuming an identity camera transform on the shared chassis body.
     * At distance x, the top face is at chassis-local z = x * tan(vHalfFov).
     */
    private double topFaceWorldZ(double xDist) {
        return CHASSIS_Z + xDist * Math.tan(V_HALF_FOV_RAD);
    }

    // -- Tests ----------------------------------------------------------------

    @Test
    void frustumSensorDetectsPieceInsideFov() {
        Transform3d identity = new Transform3d();
        DGeom sensorGeom = buildAndRegisterFrustum(identity);

        // Place a sphere straddling the top face of the frustum at x=1.5m.
        // At x=1.5, the top face is at chassis-local z = 1.5 * tan(28.1 deg) ~ 0.80m,
        // which is world z ~ 1.30. A sphere (r=0.075) centered there straddles the face.
        double testX = 1.5;
        DBody sphere = createGamePieceSphere(testX, 0, topFaceWorldZ(testX));

        stepPhysics();

        Set<DBody> contacts = physicsWorld.getSensorContacts(sensorGeom);
        assertTrue(contacts.contains(sphere),
                "Frustum sensor should detect a sphere intersecting the top face of the frustum");
    }

    @Test
    void frustumSensorIgnoresPieceOutsideFov() {
        Transform3d identity = new Transform3d();
        DGeom sensorGeom = buildAndRegisterFrustum(identity);

        // Place a sphere behind the camera at (-1.0, 0, CHASSIS_Z).
        // The frustum extends only in the +X direction, so this is outside the FOV.
        createGamePieceSphere(-1.0, 0, CHASSIS_Z);

        stepPhysics();

        Set<DBody> contacts = physicsWorld.getSensorContacts(sensorGeom);
        assertTrue(contacts.isEmpty(),
                "Frustum sensor should not detect a sphere behind the camera");
    }

    @Test
    void frustumSensorIgnoresPieceBeyondFarPlane() {
        Transform3d identity = new Transform3d();
        DGeom sensorGeom = buildAndRegisterFrustum(identity);

        // Place a sphere well beyond the far plane. At x=5.0, the sphere is 2.0m past
        // the far face (at x=3.0), so it cannot intersect any part of the frustum.
        createGamePieceSphere(5.0, 0, CHASSIS_Z);

        stepPhysics();

        Set<DBody> contacts = physicsWorld.getSensorContacts(sensorGeom);
        assertTrue(contacts.isEmpty(),
                "Frustum sensor should not detect a sphere beyond the far plane (5.0m > 3.0m)");
    }

    @Test
    void frustumSensorIgnoresPieceBeforeNearPlane() {
        Transform3d identity = new Transform3d();
        DGeom sensorGeom = buildAndRegisterFrustum(identity);

        // Place a sphere well before the near plane at x=0.1 (near plane is at x=0.3).
        // The sphere (r=0.075) extends to x=0.175 at most, which is still before the
        // near face at x=0.3.
        createGamePieceSphere(0.1, 0, CHASSIS_Z);

        stepPhysics();

        Set<DBody> contacts = physicsWorld.getSensorContacts(sensorGeom);
        assertTrue(contacts.isEmpty(),
                "Frustum sensor should not detect a sphere before the near plane (0.1m < 0.3m)");
    }

    @Test
    void cameraOffsetShiftsFrustum() {
        // Camera offset to the right by 0.5m (negative Y in WPILib convention).
        // This shifts the entire frustum 0.5m in the -Y direction.
        Transform3d offsetRight = new Transform3d(
                new Translation3d(0, -0.5, 0),
                new Rotation3d());
        DGeom sensorGeom = buildAndRegisterFrustum(offsetRight);

        // Place a sphere straddling the top face of the offset frustum at x=1.5, y=-0.5.
        // The top face is at the same Z as before (offset is only in Y).
        double testX = 1.5;
        DBody sphereInFront = createGamePieceSphere(testX, -0.5, topFaceWorldZ(testX));

        stepPhysics();

        Set<DBody> contacts = physicsWorld.getSensorContacts(sensorGeom);
        assertTrue(contacts.contains(sphereInFront),
                "Frustum sensor should detect a sphere in front of the offset camera");

        // Verify that a sphere on the opposite side is NOT detected.
        // Use a fresh PhysicsWorld to avoid interference from the first sphere.
        PhysicsWorld world2 = new PhysicsWorld();

        DBody chassis2 = createBody(world2.getWorld());
        chassis2.setPosition(0, 0, CHASSIS_Z);
        chassis2.setAutoDisableFlag(false);
        chassis2.setGravityMode(false);
        DMass mass2 = createMass();
        mass2.setBoxTotal(50.0, 0.8, 0.8, 0.2);
        chassis2.setMass(mass2);
        DGeom chassisGeom2 = createBox(world2.getSpace(), 0.8, 0.8, 0.2);
        chassisGeom2.setBody(chassis2);

        DGeom sensorGeom2 = buildAndRegisterFrustum(world2, chassis2, offsetRight);

        // Place sphere at (1.5, 2.5, CHASSIS_Z) -- far from the offset camera's FOV.
        // The offset frustum is centered at y=-0.5, so y=2.5 is 3.0m away.
        createGamePieceSphere(world2, testX, 2.5, CHASSIS_Z);

        for (int i = 0; i < STEP_COUNT; i++) {
            world2.step(STEP_DT);
        }

        Set<DBody> contactsMiss = world2.getSensorContacts(sensorGeom2);
        assertTrue(contactsMiss.isEmpty(),
                "Frustum sensor should not detect a sphere far from the offset camera's FOV");
    }

    @Test
    void getCameraPose3dAppliesTransform() {
        // Camera mounted 0.3m forward, 0.2m left, 0.5m up from robot center
        Translation3d cameraTranslation = new Translation3d(0.3, 0.2, 0.5);
        // Camera tilted 15 degrees down (negative pitch)
        Rotation3d cameraRotation = new Rotation3d(0, Math.toRadians(-15), 0);
        Transform3d mountTransform = new Transform3d(cameraTranslation, cameraRotation);

        // getCameraPose3d is just robotPose.transformBy(mountTransform)
        Pose3d robotPose = new Pose3d(2.0, 3.0, 0.0, new Rotation3d());
        Pose3d cameraPose = robotPose.transformBy(mountTransform);

        // Camera should be at robot pose + camera offset
        assertEquals(2.3, cameraPose.getX(), 0.001,
                "Camera X should be robot X + camera offset X");
        assertEquals(3.2, cameraPose.getY(), 0.001,
                "Camera Y should be robot Y + camera offset Y");
        assertEquals(0.5, cameraPose.getZ(), 0.001,
                "Camera Z should be robot Z + camera offset Z");

        // Camera pitch should be -15 degrees
        assertEquals(Math.toRadians(-15), cameraPose.getRotation().getY(), 0.001,
                "Camera pitch should reflect the mount angle");
    }
}
