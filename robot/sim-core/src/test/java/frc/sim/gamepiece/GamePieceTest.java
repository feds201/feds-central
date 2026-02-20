package frc.sim.gamepiece;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.geometry.Translation3d;
import frc.sim.core.PhysicsWorld;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class GamePieceTest {
    private PhysicsWorld world;
    private GamePieceConfig fuelConfig;

    @BeforeEach
    void setUp() {
        world = new PhysicsWorld();
        fuelConfig = new GamePieceConfig.Builder()
                .withName("fuel")
                .withShape(GamePieceConfig.Shape.SPHERE)
                .withRadius(0.075)
                .withMass(0.2)
                .withBounce(0.3)
                .withFriction(0.5)
                .build();
    }

    @Test
    void pieceSpawnsAtPosition() {
        GamePiece piece = new GamePiece(world, fuelConfig, 3.0, 4.0, 1.0);
        Translation3d pos = piece.getPosition3d();
        assertEquals(3.0, pos.getX(), 0.001);
        assertEquals(4.0, pos.getY(), 0.001);
        assertEquals(1.0, pos.getZ(), 0.001);
        assertEquals(GamePiece.State.ON_FIELD, piece.getState());
    }

    @Test
    void pieceFallsUnderGravity() {
        GamePiece piece = new GamePiece(world, fuelConfig, 5, 5, 2.0);
        piece.getBody().setAutoDisableFlag(false);

        for (int i = 0; i < 50; i++) {
            world.step(0.02);
        }

        double z = piece.getPosition3d().getZ();
        assertTrue(z < 0.3, "Piece should be near ground after 1s free fall, got z=" + z);
    }

    @Test
    void pieceBouncesOffGround() {
        GamePiece piece = new GamePiece(world, fuelConfig, 5, 5, 2.0);
        piece.getBody().setAutoDisableFlag(false);

        double maxZ = 0;
        boolean bounced = false;

        for (int i = 0; i < 100; i++) {
            world.step(0.02);
            double z = piece.getPosition3d().getZ();
            if (z < 0.2 && !bounced) {
                bounced = true;
                maxZ = 0;
            }
            if (bounced && z > maxZ) {
                maxZ = z;
            }
        }

        assertTrue(bounced, "Piece should reach near ground");
        assertTrue(maxZ > 0.1, "Piece should bounce, max height after bounce=" + maxZ);
    }

    @Test
    void pieceSleepsWhenStationary() {
        GamePiece piece = new GamePiece(world, fuelConfig, 5, 5, 0.1);

        // Step until auto-disable kicks in
        for (int i = 0; i < 200; i++) {
            world.step(0.02);
            piece.updateState();
        }

        assertEquals(GamePiece.State.AT_REST, piece.getState(),
                "Piece should be at rest after settling");
    }

    @Test
    void consumedPieceIsInactive() {
        GamePiece piece = new GamePiece(world, fuelConfig, 5, 5, 0.1);
        piece.consume();

        assertTrue(piece.isOffField());
        assertFalse(piece.isActive());
    }

    @Test
    void launchedPieceHasVelocity() {
        GamePiece piece = new GamePiece(world, fuelConfig, 0, 0, -100);
        piece.getBody().setAutoDisableFlag(false);

        piece.launch(new Translation3d(5, 5, 1), new Translation3d(3, 0, 5));

        world.step(0.02);

        Translation3d pos = piece.getPosition3d();
        assertTrue(pos.getX() > 5.0, "Piece should be moving in X");
        assertTrue(pos.getZ() > 1.0, "Piece should be moving upward initially");
    }

    @Test
    void managerTracksHeldCount() {
        GamePieceManager manager = new GamePieceManager(world);
        manager.setMaxCapacity(5);

        // Spawn and intake pieces
        GamePiece p1 = manager.spawnPiece(fuelConfig, 1, 1, 0.1);
        GamePiece p2 = manager.spawnPiece(fuelConfig, 2, 1, 0.1);

        assertTrue(manager.intakePiece(p1));
        assertEquals(1, manager.getHeldCount());

        assertTrue(manager.intakePiece(p2));
        assertEquals(2, manager.getHeldCount());
    }

    @Test
    void intakeRespectsMaxCapacity() {
        GamePieceManager manager = new GamePieceManager(world);
        manager.setMaxCapacity(2);

        GamePiece p1 = manager.spawnPiece(fuelConfig, 1, 1, 0.1);
        GamePiece p2 = manager.spawnPiece(fuelConfig, 2, 1, 0.1);
        GamePiece p3 = manager.spawnPiece(fuelConfig, 3, 1, 0.1);

        assertTrue(manager.intakePiece(p1));
        assertTrue(manager.intakePiece(p2));
        assertFalse(manager.intakePiece(p3), "Should reject when at capacity");
        assertEquals(2, manager.getHeldCount());
    }

    @Test
    void launchDecrementsCounter() {
        GamePieceManager manager = new GamePieceManager(world);
        manager.setHeldCount(3);

        GamePiece launched = manager.launchPiece(fuelConfig,
                new Translation3d(5, 5, 1), new Translation3d(3, 0, 5));

        assertNotNull(launched);
        assertEquals(2, manager.getHeldCount());
    }

    @Test
    void launchReturnsNullWhenEmpty() {
        GamePieceManager manager = new GamePieceManager(world);
        manager.setHeldCount(0);

        GamePiece launched = manager.launchPiece(fuelConfig,
                new Translation3d(5, 5, 1), new Translation3d(3, 0, 5));

        assertNull(launched);
    }

    @Test
    void intakeZoneConsumesWhenRollersOn() {
        GamePieceManager manager = new GamePieceManager(world);
        manager.setMaxCapacity(10);

        Pose2d robotPose = new Pose2d(5, 5, Rotation2d.kZero);

        // Intake zone at front of robot (x: 0.3 to 0.5, y: -0.2 to 0.2)
        IntakeZone zone = new IntakeZone(0.3, 0.5, -0.2, 0.2, 0.3,
                () -> true, // rollers ON
                () -> robotPose);

        // Spawn a piece right in the intake zone
        GamePiece piece = manager.spawnPiece(fuelConfig, 5.4, 5.0, 0.1);

        int consumed = zone.checkIntake(manager, manager.getPieces());
        assertEquals(1, consumed);
        assertEquals(1, manager.getHeldCount());
        assertTrue(piece.isOffField());
    }

    @Test
    void intakeZoneIgnoresWhenRollersOff() {
        GamePieceManager manager = new GamePieceManager(world);
        Pose2d robotPose = new Pose2d(5, 5, Rotation2d.kZero);

        IntakeZone zone = new IntakeZone(0.3, 0.5, -0.2, 0.2, 0.3,
                () -> false, // rollers OFF
                () -> robotPose);

        manager.spawnPiece(fuelConfig, 5.4, 5.0, 0.1);

        int consumed = zone.checkIntake(manager, manager.getPieces());
        assertEquals(0, consumed);
        assertEquals(0, manager.getHeldCount());
    }

    @Test
    void intakeZoneRespectsCapacity() {
        GamePieceManager manager = new GamePieceManager(world);
        manager.setMaxCapacity(1);
        manager.setHeldCount(1); // already full

        Pose2d robotPose = new Pose2d(5, 5, Rotation2d.kZero);
        IntakeZone zone = new IntakeZone(0.3, 0.5, -0.2, 0.2, 0.3,
                () -> true, () -> robotPose);

        GamePiece piece = manager.spawnPiece(fuelConfig, 5.4, 5.0, 0.1);
        int consumed = zone.checkIntake(manager, manager.getPieces());

        assertEquals(0, consumed);
        assertTrue(piece.isActive(), "Piece should still be on field");
    }

    @Test
    void launchParametersComputeCorrectVelocity() {
        LaunchParameters params = new LaunchParameters(
                10.0,               // 10 m/s
                Math.PI / 4,        // 45 degrees
                0.8,                // 0.8m launch height
                0                   // no turret offset
        );

        Pose2d robotPose = new Pose2d(5, 5, Rotation2d.kZero);
        Translation3d vel = params.getLaunchVelocity(robotPose, 0, 0);

        // At 45 degrees, horizontal and vertical components should be equal
        double expected = 10.0 * Math.cos(Math.PI / 4);
        assertEquals(expected, vel.getX(), 0.01, "Vx should be horizontal component");
        assertEquals(0, vel.getY(), 0.01, "Vy should be ~0 facing forward");
        assertEquals(expected, vel.getZ(), 0.01, "Vz should be vertical component");

        // Verify total speed magnitude is preserved
        double speed = Math.sqrt(vel.getX() * vel.getX() + vel.getY() * vel.getY() + vel.getZ() * vel.getZ());
        assertEquals(10.0, speed, 0.1, "Launch speed magnitude should be preserved");
    }

    @Test
    void launchParametersAccountForRobotVelocity() {
        LaunchParameters params = new LaunchParameters(10.0, 0, 0.8, 0);

        Pose2d robotPose = new Pose2d(5, 5, Rotation2d.kZero);
        Translation3d vel = params.getLaunchVelocity(robotPose, 2.0, 1.0);

        assertEquals(12.0, vel.getX(), 0.01, "Should add robot Vx");
        assertEquals(1.0, vel.getY(), 0.01, "Should add robot Vy");
    }
}
