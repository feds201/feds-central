package frc.sim.integration;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Pose3d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.geometry.Translation2d;
import frc.sim.chassis.ChassisConfig;
import frc.sim.chassis.ChassisSimulation;
import frc.sim.core.PhysicsWorld;
import frc.sim.gamepiece.GamePiece;
import frc.sim.gamepiece.GamePieceConfig;
import frc.sim.gamepiece.GamePieceManager;
import frc.sim.gamepiece.IntakeZone;
import org.junit.jupiter.api.Test;
import org.ode4j.ode.DGeom;
import org.ode4j.ode.DTriMeshData;
import org.ode4j.ode.OdeHelper;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Integration tests that verify the wiring between sim-core components.
 * Each test creates a fresh PhysicsWorld and wires components manually,
 * avoiding any dependency on CTRE/WPILib JNI that would come from
 * robot-specific SimManager classes.
 *
 * sim-core doesn't depend on maple-sim, so tests use direct force
 * application instead of voltage-based motor simulation.
 */
class SimPipelineTest {

    private static final double MODULE_OFFSET = 0.2667;
    private static final double ROBOT_MASS = 55.0;
    private static final double ROBOT_MOI = 6.0;
    private static final double BUMPER_X = 0.8;
    private static final double BUMPER_Y = 0.8;
    private static final double BUMPER_Z = 0.25;
    private static final double DT = 0.02;

    private ChassisConfig createConfig() {
        return new ChassisConfig.Builder()
                .withModulePositions(
                        new Translation2d(MODULE_OFFSET, MODULE_OFFSET),   // FL
                        new Translation2d(MODULE_OFFSET, -MODULE_OFFSET),  // FR
                        new Translation2d(-MODULE_OFFSET, MODULE_OFFSET),  // BL
                        new Translation2d(-MODULE_OFFSET, -MODULE_OFFSET)) // BR
                .withRobotMass(ROBOT_MASS)
                .withRobotMOI(ROBOT_MOI)
                .withBumperSize(BUMPER_X, BUMPER_Y, BUMPER_Z)
                .build();
    }

    private GamePieceConfig createBallConfig() {
        return new GamePieceConfig.Builder()
                .withName("ball")
                .withShape(GamePieceConfig.Shape.SPHERE)
                .withRadius(0.075)
                .withMass(0.2)
                .withBounce(0.3)
                .withFriction(0.5)
                .build();
    }

    /** Run the sim loop: applyForces, step. */
    private void runTicks(ChassisSimulation chassis, PhysicsWorld world, int ticks,
                          double forceX, double forceY, double torqueZ) {
        for (int i = 0; i < ticks; i++) {
            chassis.applyForces(forceX, forceY, torqueZ);
            world.step(DT);
        }
    }

    // -----------------------------------------------------------------------
    // Test 1: Chassis moves under applied force (end-to-end)
    // -----------------------------------------------------------------------

    @Test
    void chassisMovesUnderForceEndToEnd() {
        PhysicsWorld world = new PhysicsWorld();
        ChassisConfig config = createConfig();
        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(2, 4, Rotation2d.kZero));

        // Apply 200N forward for 1 second (50 ticks)
        runTicks(chassis, world, 50, 200.0, 0, 0);

        double finalX = chassis.getPose2d().getX();
        assertTrue(finalX > 2.0,
                "Chassis should have moved forward from x=2, got x=" + finalX);

        // Kinematic check: x = 0.5 * a * t^2, a = F/m = 200/55 = 3.636 m/s^2
        // After 1s: x = 0.5 * 3.636 * 1 = 1.818m (theoretical, damping reduces this)
        double actualDistance = finalX - 2.0;
        assertTrue(actualDistance > 0.5,
                "Should have moved a meaningful distance, got " + actualDistance);
    }

    // -----------------------------------------------------------------------
    // Test 2: Chassis pushes game piece
    // -----------------------------------------------------------------------

    @Test
    void chassisPushesGamePiece() {
        PhysicsWorld world = new PhysicsWorld();
        ChassisConfig config = createConfig();
        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(2, 4, Rotation2d.kZero));

        // Spawn a ball just in front of the chassis
        GamePieceConfig ballConfig = createBallConfig();
        GamePiece ball = new GamePiece(world, ballConfig, 2.6, 4, 0.075);
        ball.getBody().setAutoDisableFlag(false);

        // Apply forward force for 2 seconds
        runTicks(chassis, world, 100, 200.0, 0, 0);

        double ballX = ball.getPosition3d().getX();
        assertTrue(ballX > 2.6,
                "Ball should have been pushed forward from x=2.6, got x=" + ballX);

        double chassisX = chassis.getPose2d().getX();
        assertTrue(chassisX > 2.0,
                "Chassis should also have moved forward from x=2, got x=" + chassisX);
    }

    // -----------------------------------------------------------------------
    // Test 3: Kinematic chassis pushes game piece
    // -----------------------------------------------------------------------

    @Test
    void kinematicChassisPushesGamePiece() {
        PhysicsWorld world = new PhysicsWorld();
        ChassisConfig config = createConfig();
        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(2, 4, Rotation2d.kZero));

        // Spawn a ball just in front of the chassis
        GamePieceConfig ballConfig = createBallConfig();
        GamePiece ball = new GamePiece(world, ballConfig, 2.6, 4, 0.075);
        ball.getBody().setAutoDisableFlag(false);

        double ballStartX = ball.getPosition3d().getX();

        // Drive chassis into the ball using velocity-only (no setPose before step)
        for (int i = 0; i < 100; i++) {
            chassis.setVelocity(2.0, 0, 0, DT);
            world.step(DT);
        }

        double ballFinalX = ball.getPosition3d().getX();
        assertTrue(ballFinalX > ballStartX + 0.5,
                "Kinematic chassis should push ball forward, got deltaX=" + (ballFinalX - ballStartX));
    }

    // -----------------------------------------------------------------------
    // Test 4: Kinematic chassis rides up elevated surface
    // -----------------------------------------------------------------------

    /**
     * Build a triangular-prism bump trimesh (same shape as field bumps).
     * Ridge runs along Y; ramps on both X sides.
     */
    private DGeom createBumpTrimesh(PhysicsWorld world,
                                     double ridgeX, double halfDepth,
                                     double y1, double y2, double peakZ) {
        float rx = (float) ridgeX;
        float x1 = (float) (ridgeX - halfDepth);
        float x2 = (float) (ridgeX + halfDepth);
        float fy1 = (float) y1, fy2 = (float) y2;
        float h = (float) peakZ;

        float[] verts = {
            x1, fy1, 0,    // 0  near-left base
            rx, fy1, h,    // 1  near ridge
            x2, fy1, 0,    // 2  near-right base
            x1, fy2, 0,    // 3  far-left base
            rx, fy2, h,    // 4  far ridge
            x2, fy2, 0,    // 5  far-right base
        };
        // Triangulated faces (CCW winding viewed from outside)
        int[] indices = {
            0, 2, 1,    // near end cap
            3, 4, 5,    // far end cap
            0, 3, 5,  0, 5, 2,    // bottom
            0, 1, 4,  0, 4, 3,    // left ramp  (-X side, going up)
            2, 5, 4,  2, 4, 1,    // right ramp (+X side, going up)
        };

        DTriMeshData meshData = OdeHelper.createTriMeshData();
        meshData.build(verts, indices);
        DGeom geom = OdeHelper.createTriMesh(world.getSpace(), meshData, null, null, null);
        geom.setPosition(0, 0, 0);
        return geom;
    }

    @Test
    void kinematicChassisDrivesOverBump() {
        PhysicsWorld world = new PhysicsWorld();
        ChassisConfig config = createConfig();

        // Create a bump: ridge at x=4, ramps ±0.5m wide, 0.165m tall, 2m along Y
        createBumpTrimesh(world, 4.0, 0.5, 3.0, 5.0, 0.165);

        // Place chassis before the bump
        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(2, 4, Rotation2d.kZero));

        // Let it settle on ground
        for (int i = 0; i < 50; i++) {
            chassis.setVelocity(0, 0, 0, DT);
            chassis.setPose(new Pose2d(2, 4, Rotation2d.kZero));
            world.step(DT);
        }
        double settledZ = chassis.getBody().getPosition().get2();

        // Drive chassis over the bump at 2 m/s using VELOCITY ONLY (no setPose).
        // setPose fights the contact solver — it resets X every tick, so the ramp
        // contact can never push the chassis backward along the surface normal.
        // Velocity-only lets ODE4J integrate position naturally including ramp deflection.
        double maxZ = settledZ;
        for (int i = 0; i < 200; i++) {
            chassis.setVelocity(2.0, 0, 0, DT);
            world.step(DT);

            double z = chassis.getBody().getPosition().get2();
            if (z > maxZ) maxZ = z;
        }

        // Chassis should have risen at least 5cm above settled height while crossing the bump
        assertTrue(maxZ > settledZ + 0.05,
                "Chassis should ride over the bump. maxZ=" + maxZ
                        + " settledZ=" + settledZ
                        + " expectedRise=0.165");
    }

    // -----------------------------------------------------------------------
    // Test 5: No parasitic yaw when driving straight on flat ground
    // -----------------------------------------------------------------------

    @Test
    void noParasiticYawOnFlatGround() {
        PhysicsWorld world = new PhysicsWorld();
        ChassisConfig config = createConfig();
        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(2, 4, Rotation2d.kZero));

        // Let it settle
        for (int i = 0; i < 50; i++) {
            chassis.setVelocity(0, 0, 0, DT);
            world.step(DT);
        }

        // Drive straight forward for 5 seconds (250 ticks)
        for (int i = 0; i < 250; i++) {
            chassis.setVelocity(2.0, 0, 0, DT);
            world.step(DT);
        }

        double finalYaw = Math.abs(chassis.getYawRad());
        assertTrue(finalYaw < Math.toRadians(1.0),
                "Driving straight should produce <1 degree of yaw drift, got "
                        + Math.toDegrees(finalYaw) + " degrees");
    }

    // -----------------------------------------------------------------------
    // Test 6: No parasitic yaw when driving along a wall
    // -----------------------------------------------------------------------

    @Test
    void noParasiticYawAlongWall() {
        PhysicsWorld world = new PhysicsWorld();
        ChassisConfig config = createConfig();

        // Wall parallel to X axis, close to the chassis's side
        world.addStaticBox(20, 0.1, 1, 10, 3.5, 0.5);

        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(2, 4, Rotation2d.kZero));

        // Let it settle
        for (int i = 0; i < 50; i++) {
            chassis.setVelocity(0, 0, 0, DT);
            world.step(DT);
        }

        // Drive straight forward along the wall for 5 seconds
        for (int i = 0; i < 250; i++) {
            chassis.setVelocity(2.0, 0, 0, DT);
            world.step(DT);
        }

        double finalYaw = Math.abs(chassis.getYawRad());
        assertTrue(finalYaw < Math.toRadians(2.0),
                "Driving along a wall should produce <2 degrees of yaw drift, got "
                        + Math.toDegrees(finalYaw) + " degrees");
    }

    // -----------------------------------------------------------------------
    // Test 7: No parasitic yaw when driving over a bump
    // -----------------------------------------------------------------------

    @Test
    void noParasiticYawOverBump() {
        PhysicsWorld world = new PhysicsWorld();
        ChassisConfig config = createConfig();

        // Bump centered at x=5, wide enough for the chassis
        createBumpTrimesh(world, 5.0, 0.5, 3.0, 5.0, 0.165);

        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(2, 4, Rotation2d.kZero));

        // Let it settle
        for (int i = 0; i < 50; i++) {
            chassis.setVelocity(0, 0, 0, DT);
            world.step(DT);
        }

        // Drive straight over the bump for 5 seconds
        for (int i = 0; i < 250; i++) {
            chassis.setVelocity(2.0, 0, 0, DT);
            world.step(DT);
        }

        double finalYaw = Math.abs(chassis.getYawRad());
        assertTrue(finalYaw < Math.toRadians(3.0),
                "Driving over a bump should produce <3 degrees of yaw drift, got "
                        + Math.toDegrees(finalYaw) + " degrees");
    }

    // -----------------------------------------------------------------------
    // Test 8: Intake zone with rotated robot
    // -----------------------------------------------------------------------

    @Test
    void intakeZoneWithRotatedRobot() {
        PhysicsWorld world = new PhysicsWorld();
        ChassisConfig config = createConfig();

        // Robot at (5, 5) facing +Y direction (90 degrees = pi/2)
        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(5, 5, new Rotation2d(Math.PI / 2)));

        GamePieceConfig ballConfig = createBallConfig();
        GamePieceManager manager = new GamePieceManager(world);
        manager.setMaxCapacity(10);
        manager.spawnPiece(ballConfig, 5, 5.4, 0.1);

        IntakeZone intakeZone = new IntakeZone(
                0.35, 0.5,
                -0.25, 0.25,
                0.2,
                () -> true,
                () -> chassis.getPose2d()
        );

        int consumed = intakeZone.checkIntake(manager, manager.getPieces());
        assertEquals(1, consumed,
                "Intake zone should have consumed 1 piece at the rotated robot's front");
        assertEquals(1, manager.getHeldCount(),
                "Manager held count should be 1 after consuming a piece");
    }

    // -----------------------------------------------------------------------
    // Test 9: Ramp physics — 3D pitch/roll from elevated surface
    // -----------------------------------------------------------------------

    @Test
    void rampPhysicsAffectsPitchRoll() {
        PhysicsWorld world = new PhysicsWorld();
        ChassisConfig config = createConfig();

        org.ode4j.ode.DGeom rampGeom = org.ode4j.ode.OdeHelper.createBox(
                world.getSpace(), 3.0, 2.0, 0.1);
        double rampAngle = Math.toRadians(15);
        org.ode4j.math.DMatrix3 rampRot = new org.ode4j.math.DMatrix3();
        rampRot.set00(Math.cos(rampAngle));  rampRot.set01(0); rampRot.set02(Math.sin(rampAngle));
        rampRot.set10(0);                    rampRot.set11(1); rampRot.set12(0);
        rampRot.set20(-Math.sin(rampAngle)); rampRot.set21(0); rampRot.set22(Math.cos(rampAngle));
        rampGeom.setRotation(rampRot);
        rampGeom.setPosition(5, 5, 0.4);

        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(5, 5, Rotation2d.kZero));
        chassis.getBody().setPosition(5, 5, 1.0);

        // Let gravity and contact forces settle the chassis onto the ramp
        for (int i = 0; i < 100; i++) {
            chassis.applyForces(0, 0, 0);
            world.step(DT);
        }

        Pose3d pose3d = chassis.getPose3d();
        double pitch = pose3d.getRotation().getY();
        double roll = pose3d.getRotation().getX();

        double tiltMagnitude = Math.sqrt(pitch * pitch + roll * roll);
        assertTrue(tiltMagnitude > Math.toRadians(1.0),
                String.format("Chassis on ramp should show non-zero pitch/roll. " +
                        "pitch=%.4f rad, roll=%.4f rad, magnitude=%.4f rad.",
                        pitch, roll, tiltMagnitude));
    }

    // -----------------------------------------------------------------------
    // Parasitic yaw helper — settle, drive, assert drift is within tolerance
    // -----------------------------------------------------------------------

    private void assertNoParasiticYaw(
            PhysicsWorld world, ChassisSimulation chassis,
            double worldVx, double worldVy,
            int driveTicks, double maxDriftDeg, String description) {
        // Settle on ground plane
        for (int i = 0; i < 50; i++) {
            chassis.setVelocity(0, 0, 0, DT);
            world.step(DT);
        }

        double startYaw = chassis.getYawRad();

        for (int i = 0; i < driveTicks; i++) {
            chassis.setVelocity(worldVx, worldVy, 0, DT);
            world.step(DT);
        }

        double yawDrift = Math.abs(chassis.getYawRad() - startYaw);
        if (yawDrift > Math.PI) yawDrift = 2 * Math.PI - yawDrift;

        assertTrue(yawDrift < Math.toRadians(maxDriftDeg),
                description + ": expected <" + maxDriftDeg + "° yaw drift, got "
                        + String.format("%.4f", Math.toDegrees(yawDrift)) + "°");
    }

    // -----------------------------------------------------------------------
    // Test 10: No parasitic yaw at 45-degree heading (non-axis-aligned)
    // -----------------------------------------------------------------------

    @Test
    void noParasiticYawAt45DegreeHeading() {
        PhysicsWorld world = new PhysicsWorld();
        ChassisConfig config = createConfig();
        double heading = Math.PI / 4;
        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(4, 4, new Rotation2d(heading)));

        double speed = 2.0;
        assertNoParasiticYaw(world, chassis,
                speed * Math.cos(heading), speed * Math.sin(heading),
                250, 1.0, "Driving at 45° heading");
    }

    // -----------------------------------------------------------------------
    // Test 11: No parasitic yaw when strafing sideways
    // -----------------------------------------------------------------------

    @Test
    void noParasiticYawWhenStrafing() {
        PhysicsWorld world = new PhysicsWorld();
        ChassisConfig config = createConfig();
        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(4, 4, Rotation2d.kZero));

        assertNoParasiticYaw(world, chassis,
                0, 2.0,
                250, 1.0, "Strafing in +Y");
    }

    // -----------------------------------------------------------------------
    // Test 12: No parasitic yaw at high speed (4 m/s)
    // -----------------------------------------------------------------------

    @Test
    void noParasiticYawAtHighSpeed() {
        PhysicsWorld world = new PhysicsWorld();
        ChassisConfig config = createConfig();
        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(4, 4, Rotation2d.kZero));

        assertNoParasiticYaw(world, chassis,
                4.0, 0,
                250, 1.0, "Driving at 4 m/s");
    }

    // -----------------------------------------------------------------------
    // Test 13: No parasitic yaw over 15 seconds (catches slow drift)
    // Same 1° tolerance over 3x duration = 3x tighter per-second budget.
    // -----------------------------------------------------------------------

    @Test
    void noParasiticYawLongDuration() {
        PhysicsWorld world = new PhysicsWorld();
        ChassisConfig config = createConfig();
        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(4, 4, Rotation2d.kZero));

        assertNoParasiticYaw(world, chassis,
                2.0, 0,
                750, 1.0, "Driving for 15 seconds");
    }

    // -----------------------------------------------------------------------
    // Test 14: No parasitic yaw with diagonal driving
    // -----------------------------------------------------------------------

    @Test
    void noParasiticYawDiagonalDriving() {
        PhysicsWorld world = new PhysicsWorld();
        ChassisConfig config = createConfig();
        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(4, 4, Rotation2d.kZero));

        double v = 2.0 / Math.sqrt(2);
        assertNoParasiticYaw(world, chassis,
                v, v,
                250, 1.0, "Diagonal driving (vx=vy)");
    }

    // -----------------------------------------------------------------------
    // Test 15: No parasitic yaw after bouncing off a wall
    // Drives into wall, then drives perpendicular — catches residual
    // angular velocity from asymmetric collision contacts.
    // -----------------------------------------------------------------------

    @Test
    void noParasiticYawAfterWallCollision() {
        PhysicsWorld world = new PhysicsWorld();
        ChassisConfig config = createConfig();

        world.addStaticBox(0.2, 10, 1, 6, 4, 0.5);

        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(4, 4, Rotation2d.kZero));

        // Settle
        for (int i = 0; i < 50; i++) {
            chassis.setVelocity(0, 0, 0, DT);
            world.step(DT);
        }

        // Drive into wall for 2 seconds
        for (int i = 0; i < 100; i++) {
            chassis.setVelocity(2.0, 0, 0, DT);
            world.step(DT);
        }

        // Now drive perpendicular (along wall) for 5 seconds
        double startYaw = chassis.getYawRad();
        for (int i = 0; i < 250; i++) {
            chassis.setVelocity(0, 2.0, 0, DT);
            world.step(DT);
        }

        double yawDrift = Math.abs(chassis.getYawRad() - startYaw);
        if (yawDrift > Math.PI) yawDrift = 2 * Math.PI - yawDrift;
        assertTrue(yawDrift < Math.toRadians(2.0),
                "Driving after wall collision should produce <2° yaw drift, got "
                        + String.format("%.4f", Math.toDegrees(yawDrift)) + "°");
    }

    // -----------------------------------------------------------------------
    // Test 16: No parasitic yaw with applyForces mode (flat ground)
    // Tests the dynamic force path, not the kinematic velocity path.
    // -----------------------------------------------------------------------

    @Test
    void noParasiticYawWithApplyForces() {
        PhysicsWorld world = new PhysicsWorld();
        ChassisConfig config = createConfig();
        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(4, 4, Rotation2d.kZero));

        for (int i = 0; i < 50; i++) {
            chassis.applyForces(0, 0, 0);
            world.step(DT);
        }

        double startYaw = chassis.getYawRad();

        for (int i = 0; i < 250; i++) {
            chassis.applyForces(200, 0, 0);
            world.step(DT);
        }

        double yawDrift = Math.abs(chassis.getYawRad() - startYaw);
        if (yawDrift > Math.PI) yawDrift = 2 * Math.PI - yawDrift;
        assertTrue(yawDrift < Math.toRadians(1.0),
                "applyForces with zero torque should produce <1° yaw drift, got "
                        + String.format("%.4f", Math.toDegrees(yawDrift)) + "°");
    }

    // -----------------------------------------------------------------------
    // Test 17: No parasitic yaw with applyForces at 45° heading
    // Non-axis-aligned chassis under dynamic forces — catches asymmetric
    // ODE contact point distribution on the ground plane.
    // -----------------------------------------------------------------------

    @Test
    void noParasiticYawWithApplyForcesAt45Degrees() {
        PhysicsWorld world = new PhysicsWorld();
        ChassisConfig config = createConfig();
        double heading = Math.PI / 4;
        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(4, 4, new Rotation2d(heading)));

        for (int i = 0; i < 50; i++) {
            chassis.applyForces(0, 0, 0);
            world.step(DT);
        }

        double startYaw = chassis.getYawRad();

        double fx = 200 * Math.cos(heading);
        double fy = 200 * Math.sin(heading);
        for (int i = 0; i < 250; i++) {
            chassis.applyForces(fx, fy, 0);
            world.step(DT);
        }

        double yawDrift = Math.abs(chassis.getYawRad() - startYaw);
        if (yawDrift > Math.PI) yawDrift = 2 * Math.PI - yawDrift;
        assertTrue(yawDrift < Math.toRadians(1.0),
                "applyForces at 45° heading should produce <1° yaw drift, got "
                        + String.format("%.4f", Math.toDegrees(yawDrift)) + "°");
    }
}
