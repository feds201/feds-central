package frc.sim.integration;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.geometry.Translation2d;
import frc.sim.chassis.ChassisConfig;
import frc.sim.chassis.ChassisSimulation;
import frc.sim.core.FieldGeometry;
import frc.sim.core.PhysicsWorld;
import frc.sim.gamepiece.GamePiece;
import frc.sim.gamepiece.GamePieceConfig;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Wall collision integrity tests.
 *
 * Verifies that neither the robot chassis nor game pieces can pass through
 * solid walls. Uses thick static-box walls from
 * {@link FieldGeometry#addBoundaryWalls}.
 *
 * Covers:
 *   - Force-driven robot stops at walls
 *   - Balls at low, high, and very high speeds bounce off walls
 *   - Balls launched at all angles stay within field bounds
 */
class WallCollisionTest {

    private static final double DT = 0.02; // 50 Hz physics step
    private static final double FIELD_SIZE = 6.0; // 6m x 6m field
    private static final double WALL_HEIGHT = 0.5;
    private static final double WALL_THICKNESS = 0.1;

    // Robot chassis dimensions
    private static final double BUMPER_X = 0.8;
    private static final double BUMPER_Y = 0.8;
    private static final double BUMPER_Z = 0.25;
    private static final double ROBOT_MASS = 55.0;
    private static final double ROBOT_MOI = 6.0;
    private static final double MODULE_OFFSET = 0.2667;

    // Game piece (ball) dimensions
    private static final double BALL_RADIUS = 0.075;

    // Tolerance: any penetration beyond this is a failure.
    // 5 cm is generous — a real wall allows 0 cm.
    private static final double PENETRATION_TOLERANCE = 0.05;

    // --- Factory helpers ---

    private ChassisConfig createRobotConfig() {
        return new ChassisConfig.Builder()
                .withModulePositions(
                        new Translation2d(MODULE_OFFSET, MODULE_OFFSET),
                        new Translation2d(MODULE_OFFSET, -MODULE_OFFSET),
                        new Translation2d(-MODULE_OFFSET, MODULE_OFFSET),
                        new Translation2d(-MODULE_OFFSET, -MODULE_OFFSET))
                .withRobotMass(ROBOT_MASS)
                .withRobotMOI(ROBOT_MOI)
                .withBumperSize(BUMPER_X, BUMPER_Y, BUMPER_Z)
                .build();
    }

    private GamePieceConfig createBallConfig() {
        return new GamePieceConfig.Builder()
                .withName("ball")
                .withShape(GamePieceConfig.Shape.SPHERE)
                .withRadius(BALL_RADIUS)
                .withMass(0.2)
                .withBounce(0.3)
                .withFriction(0.5)
                .build();
    }

    /** 6m x 6m field enclosed by thick static-box walls. */
    private PhysicsWorld createWorldWithBoxWalls() {
        PhysicsWorld world = new PhysicsWorld();
        FieldGeometry field = new FieldGeometry(world);
        field.addBoundaryWalls(FIELD_SIZE, FIELD_SIZE, WALL_HEIGHT, WALL_THICKNESS);
        return world;
    }

    /** Maximum allowed robot-center X when approaching the east wall at X = FIELD_SIZE. */
    private double maxRobotX() {
        return FIELD_SIZE - BUMPER_X / 2.0 + PENETRATION_TOLERANCE;
    }

    /** Maximum allowed ball-center X when approaching the east wall. */
    private double maxBallX() {
        return FIELD_SIZE - BALL_RADIUS + PENETRATION_TOLERANCE;
    }

    /** Minimum allowed ball-center X when approaching the west wall at X = 0. */
    private double minBallX() {
        return BALL_RADIUS - PENETRATION_TOLERANCE;
    }

    /** Maximum allowed ball-center Y when approaching the north wall. */
    private double maxBallY() {
        return FIELD_SIZE - BALL_RADIUS + PENETRATION_TOLERANCE;
    }

    /** Minimum allowed ball-center Y when approaching the south wall. */
    private double minBallY() {
        return BALL_RADIUS - PENETRATION_TOLERANCE;
    }

    // =====================================================================
    //  ROBOT-TO-WALL COLLISION TESTS
    // =====================================================================

    /**
     * Force-driven robot stops at a box wall.
     *
     * When the chassis is driven by forces (applyForces), ODE4J creates
     * contact constraints that oppose the driving force. The robot should
     * decelerate and stop at the wall boundary.
     */
    @Test
    void robotForceStopsAtBoxWall() {
        PhysicsWorld world = createWorldWithBoxWalls();
        ChassisSimulation chassis = new ChassisSimulation(world, createRobotConfig(),
                new Pose2d(FIELD_SIZE - 1.0, FIELD_SIZE / 2, Rotation2d.kZero));

        // Settle onto ground
        for (int i = 0; i < 25; i++) {
            chassis.applyForces(0, 0, 0);
            world.step(DT);
        }

        // Drive hard into the east wall for 5 seconds (250 ticks)
        double maxX = Double.NEGATIVE_INFINITY;
        for (int i = 0; i < 250; i++) {
            chassis.applyForces(500.0, 0, 0);
            world.step(DT);
            double x = chassis.getPose2d().getX();
            if (x > maxX) maxX = x;
        }

        assertTrue(maxX <= maxRobotX(),
                String.format("Force-driven robot must stop at wall. "
                        + "maxX=%.4f, limit=%.4f, penetration=%.1fmm",
                        maxX, maxRobotX(), (maxX - maxRobotX()) * 1000));
    }

    // =====================================================================
    //  BALL-TO-WALL COLLISION TESTS
    // =====================================================================

    /**
     * Slow-rolling ball bounces off a box wall.
     *
     * At 2 m/s, the ball moves 4 cm per step — well under the wall
     * thickness (10 cm). ODE4J detects the contact and applies a bounce
     * impulse. The ball should stay cleanly inside the field.
     */
    @Test
    void ballSlowRollBouncesOffBoxWall() {
        PhysicsWorld world = createWorldWithBoxWalls();
        GamePiece ball = new GamePiece(world, createBallConfig(),
                FIELD_SIZE / 2, FIELD_SIZE / 2, BALL_RADIUS);
        ball.getBody().setAutoDisableFlag(false);
        ball.getBody().setLinearVel(2.0, 0, 0); // 2 m/s toward east wall

        double maxX = Double.NEGATIVE_INFINITY;
        for (int i = 0; i < 500; i++) {
            world.step(DT);
            double x = ball.getPosition3d().getX();
            if (x > maxX) maxX = x;
        }

        assertTrue(maxX <= maxBallX(),
                String.format("Slow ball should bounce off wall. "
                        + "maxX=%.4f, limit=%.4f",
                        maxX, maxBallX()));
    }

    /**
     * High-speed ball does not tunnel through a box wall.
     *
     * At 15 m/s with DT=0.02s, the ball moves 30 cm per step.
     * The wall is only 10 cm thick. Without sub-stepping, the ball
     * would skip past the wall. Adaptive sub-stepping in PhysicsWorld
     * prevents this by splitting the timestep into smaller increments.
     */
    @Test
    void ballHighSpeedDoesNotTunnelThroughBoxWall() {
        PhysicsWorld world = createWorldWithBoxWalls();
        GamePiece ball = new GamePiece(world, createBallConfig(),
                FIELD_SIZE - 0.5, FIELD_SIZE / 2, BALL_RADIUS);
        ball.getBody().setAutoDisableFlag(false);
        ball.getBody().setLinearVel(15.0, 0, 0); // 15 m/s

        double maxX = Double.NEGATIVE_INFINITY;
        for (int i = 0; i < 250; i++) {
            world.step(DT);
            double x = ball.getPosition3d().getX();
            if (x > maxX) maxX = x;
        }

        assertTrue(maxX <= maxBallX(),
                String.format("Fast ball should not tunnel through wall. "
                        + "maxX=%.4f, limit=%.4f. "
                        + "At 15 m/s the ball moves %.0f cm/step vs %.0f cm wall.",
                        maxX, maxBallX(), 15.0 * DT * 100, WALL_THICKNESS * 100));
    }

    /**
     * Very-high-speed ball does not tunnel through a box wall.
     *
     * At 30 m/s (typical shooter speed), the ball moves 60 cm per step.
     * This is 6x the wall thickness — adaptive sub-stepping must kick in.
     */
    @Test
    void ballVeryHighSpeedDoesNotTunnelThroughBoxWall() {
        PhysicsWorld world = createWorldWithBoxWalls();
        GamePiece ball = new GamePiece(world, createBallConfig(),
                FIELD_SIZE / 2, FIELD_SIZE / 2, BALL_RADIUS);
        ball.getBody().setAutoDisableFlag(false);
        ball.getBody().setLinearVel(30.0, 0, 0); // 30 m/s (67 mph)

        double maxX = Double.NEGATIVE_INFINITY;
        for (int i = 0; i < 250; i++) {
            world.step(DT);
            double x = ball.getPosition3d().getX();
            if (x > maxX) maxX = x;
        }

        assertTrue(maxX <= maxBallX(),
                String.format("Very fast ball should not tunnel through wall. "
                        + "maxX=%.4f, limit=%.4f. "
                        + "At 30 m/s the ball moves %.0f cm/step.",
                        maxX, maxBallX(), 30.0 * DT * 100));
    }

    /**
     * Comprehensive sweep: balls launched at 8 different angles must ALL
     * stay within field bounds. Tests every wall from every approach angle.
     */
    @Test
    void ballsLaunchedAtVariousAnglesStayInBounds() {
        GamePieceConfig ballConfig = createBallConfig();
        double speed = 15.0; // m/s
        int numAngles = 8;

        double overallMaxX = Double.NEGATIVE_INFINITY;
        double overallMaxY = Double.NEGATIVE_INFINITY;
        double overallMinX = Double.POSITIVE_INFINITY;
        double overallMinY = Double.POSITIVE_INFINITY;
        String worstViolation = "none";

        for (int a = 0; a < numAngles; a++) {
            // Fresh world per angle so balls don't interact
            PhysicsWorld world = createWorldWithBoxWalls();
            double angle = 2 * Math.PI * a / numAngles;
            double vx = speed * Math.cos(angle);
            double vy = speed * Math.sin(angle);

            GamePiece ball = new GamePiece(world, ballConfig,
                    FIELD_SIZE / 2, FIELD_SIZE / 2, BALL_RADIUS);
            ball.getBody().setAutoDisableFlag(false);
            ball.getBody().setLinearVel(vx, vy, 0);

            for (int i = 0; i < 250; i++) {
                world.step(DT);
                double x = ball.getPosition3d().getX();
                double y = ball.getPosition3d().getY();

                if (x > overallMaxX) {
                    overallMaxX = x;
                    worstViolation = String.format("angle=%.0f deg x=%.4f", Math.toDegrees(angle), x);
                }
                if (y > overallMaxY) {
                    overallMaxY = y;
                    worstViolation = String.format("angle=%.0f deg y=%.4f", Math.toDegrees(angle), y);
                }
                if (x < overallMinX) overallMinX = x;
                if (y < overallMinY) overallMinY = y;
            }
        }

        boolean inBounds = overallMaxX <= maxBallX()
                        && overallMaxY <= maxBallY()
                        && overallMinX >= minBallX()
                        && overallMinY >= minBallY();

        assertTrue(inBounds,
                String.format("Balls escaped field bounds! "
                        + "X in [%.4f, %.4f] Y in [%.4f, %.4f]. "
                        + "Limits: X in [%.4f, %.4f] Y in [%.4f, %.4f]. "
                        + "Worst: %s",
                        overallMinX, overallMaxX, overallMinY, overallMaxY,
                        minBallX(), maxBallX(), minBallY(), maxBallY(),
                        worstViolation));
    }
}
