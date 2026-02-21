package frc.sim.chassis;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.geometry.Translation2d;
import frc.sim.core.PhysicsWorld;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class ChassisSimulationTest {
    private PhysicsWorld world;
    private ChassisConfig config;

    @BeforeEach
    void setUp() {
        world = new PhysicsWorld();
        config = new ChassisConfig.Builder()
                .withModulePositions(
                        new Translation2d(0.267, 0.267),   // FL
                        new Translation2d(0.267, -0.267),  // FR
                        new Translation2d(-0.267, 0.267),  // BL
                        new Translation2d(-0.267, -0.267)) // BR
                .withRobotMass(50.0)
                .withRobotMOI(6.0)
                .withBumperSize(0.8, 0.8, 0.2)
                .build();
    }

    @Test
    void chassisMovesForwardUnderAppliedForce() {
        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(5, 4, Rotation2d.kZero));

        double startX = chassis.getPose2d().getX();

        // Apply 200N forward force for 1 second
        for (int i = 0; i < 50; i++) {
            chassis.applyForces(200.0, 0, 0);
            world.step(0.02);
        }

        double finalX = chassis.getPose2d().getX();
        assertTrue(finalX > startX + 0.5,
                "Chassis should move forward, got deltaX=" + (finalX - startX));
    }

    @Test
    void chassisTurnsUnderAppliedTorque() {
        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(5, 4, Rotation2d.kZero));

        double startYaw = chassis.getYawRad();

        // Apply 20 N*m torque for 2 seconds
        for (int i = 0; i < 100; i++) {
            chassis.applyForces(0, 0, 20.0);
            world.step(0.02);
        }

        double finalYaw = chassis.getYawRad();
        double yawChange = Math.abs(finalYaw - startYaw);
        assertTrue(yawChange > 0.5,
                "Chassis should rotate significantly over 2s, got yaw change=" + yawChange);
    }

    @Test
    void chassisStopsAtWall() {
        // Add a wall at x=8
        world.addStaticBox(0.2, 10, 1, 8, 4, 0.5);

        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(5, 4, Rotation2d.kZero));

        // Apply large forward force for 3 seconds
        for (int i = 0; i < 150; i++) {
            chassis.applyForces(500.0, 0, 0);
            world.step(0.02);
        }

        double finalX = chassis.getPose2d().getX();
        assertTrue(finalX < 8.0,
                "Chassis should be stopped by wall, got x=" + finalX);
    }

    @Test
    void kinematicPoseSetsPosition() {
        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(5, 4, Rotation2d.kZero));

        Pose2d targetPose = new Pose2d(8, 6, new Rotation2d(Math.PI / 3));
        chassis.setPose(targetPose);

        Pose2d result = chassis.getPose2d();
        assertEquals(8.0, result.getX(), 0.01);
        assertEquals(6.0, result.getY(), 0.01);
        assertEquals(Math.PI / 3, result.getRotation().getRadians(), 0.01);
    }

    @Test
    void kinematicVelocitySetsVelocity() {
        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(5, 4, Rotation2d.kZero));

        chassis.setVelocity(2.0, 1.0, 0.5, 0.02);
        world.step(0.02);

        // After one 20ms step at 2 m/s, chassis should have moved ~0.04m in X
        double deltaX = chassis.getPose2d().getX() - 5.0;
        assertTrue(deltaX > 0.01,
                "Chassis should move in X after setVelocity, got deltaX=" + deltaX);
    }

    @Test
    void pose3dReturnsValidPose() {
        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(5, 4, new Rotation2d(Math.PI / 4)));

        var pose = chassis.getPose3d();
        assertEquals(5.0, pose.getX(), 0.01);
        assertEquals(4.0, pose.getY(), 0.01);
        assertTrue(pose.getZ() > 0, "Chassis should be above ground");
    }
}
