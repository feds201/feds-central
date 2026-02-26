package frc.sim.gamepiece;

import edu.wpi.first.math.geometry.Translation2d;
import frc.sim.core.PhysicsWorld;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.ode4j.math.DVector3C;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Regression test for the "neutral zone explosion" bug.
 *
 * When the robot approaches a dense cluster of fuel balls that were
 * spawned disabled, they all enable at once and violently push each
 * other apart. This test reproduces the exact spawn pattern from
 * RebuiltField.spawnStartingFuel() to verify balls remain calm
 * when enabled.
 */
class NeutralZoneExplosionTest {

    private PhysicsWorld world;
    private GamePieceManager manager;
    private GamePieceConfig fuel;

    // Match RebuiltField exactly
    private static final double RADIUS = 0.075;
    private static final double DIAMETER = RADIUS * 2;        // 0.15m
    private static final double SPACING = DIAMETER + 0.005;   // 0.155m

    @BeforeEach
    void setUp() {
        world = new PhysicsWorld();
        manager = new GamePieceManager(world);
        fuel = new GamePieceConfig.Builder()
                .withName("Fuel")
                .withShape(GamePieceConfig.Shape.SPHERE)
                .withRadius(RADIUS)
                .withMass(0.2)
                .withBounce(0.15)
                .withFriction(0.5)
                .build();
    }

    /**
     * Spawn a grid of balls exactly like the neutral zone in RebuiltField,
     * using the same spacing and jitter parameters.
     */
    // Max jitter: half the gap so two neighbors can never overlap
    private static final double MAX_JITTER = (SPACING - DIAMETER) / 2.0; // 0.0025m

    private List<GamePiece> spawnNeutralZoneCluster(Random rand, int count) {
        double centerX = 8.0;
        double centerY = 4.0;
        double zoneX = 1.83;
        double zoneY = 5.23;
        double dividerHalfWidth = 0.0508 / 2.0;

        int cols = (int) (zoneX / SPACING);
        int rows = (int) (zoneY / SPACING);

        double zoneStartX = centerX - zoneX / 2.0;
        double zoneStartY = centerY - zoneY / 2.0;

        List<GamePiece> spawned = new ArrayList<>();
        int spawnedCount = 0;

        for (int row = 0; row < rows && spawnedCount < count; row++) {
            for (int col = 0; col < cols && spawnedCount < count; col++) {
                double baseX = zoneStartX + col * SPACING + RADIUS;
                double baseY = zoneStartY + row * SPACING + RADIUS;

                // Jitter clamped to safe max (matches fixed RebuiltField)
                double x = baseX + (rand.nextDouble() * 2 - 1) * MAX_JITTER;
                double y = baseY + (rand.nextDouble() * 2 - 1) * MAX_JITTER;

                if (Math.abs(x - centerX) < dividerHalfWidth + RADIUS) {
                    continue;
                }

                GamePiece piece = manager.spawnPiece(fuel, x, y, RADIUS + 0.001);
                spawned.add(piece);
                spawnedCount++;
            }
        }
        return spawned;
    }

    /**
     * Count how many ball pairs are overlapping (center distance < diameter).
     */
    private int countOverlaps(List<GamePiece> pieces) {
        int overlaps = 0;
        for (int i = 0; i < pieces.size(); i++) {
            DVector3C posA = pieces.get(i).getBody().getPosition();
            for (int j = i + 1; j < pieces.size(); j++) {
                DVector3C posB = pieces.get(j).getBody().getPosition();
                double dx = posA.get0() - posB.get0();
                double dy = posA.get1() - posB.get1();
                double dist = Math.sqrt(dx * dx + dy * dy);
                if (dist < DIAMETER) {
                    overlaps++;
                }
            }
        }
        return overlaps;
    }

    /**
     * Measure the maximum speed among all active pieces.
     */
    private double maxSpeed(List<GamePiece> pieces) {
        double max = 0;
        for (GamePiece piece : pieces) {
            if (!piece.isActive() || !piece.getBody().isEnabled()) continue;
            DVector3C vel = piece.getBody().getLinearVel();
            double speed = Math.sqrt(
                    vel.get0() * vel.get0() +
                    vel.get1() * vel.get1() +
                    vel.get2() * vel.get2());
            if (speed > max) max = speed;
        }
        return max;
    }

    // -----------------------------------------------------------------------
    // Test: Verify the jitter creates overlaps at spawn time
    // -----------------------------------------------------------------------

    @Test
    void neutralZoneSpawnHasNoOverlaps() {
        Random rand = new Random(42);
        List<GamePiece> pieces = spawnNeutralZoneCluster(rand, 360);

        int overlaps = countOverlaps(pieces);

        System.out.println("Overlapping pairs at spawn: " + overlaps + " / " + pieces.size() + " balls");
        assertEquals(0, overlaps,
                "Jitter-clamped spawn should produce zero overlapping ball pairs. " +
                "Got " + overlaps + " overlaps — jitter may exceed safe limit.");
    }

    // -----------------------------------------------------------------------
    // Test: Balls should NOT explode when enabled after being disabled
    // -----------------------------------------------------------------------

    @Test
    void ballsShouldNotExplodeWhenEnabled() {
        Random rand = new Random(42);
        List<GamePiece> pieces = spawnNeutralZoneCluster(rand, 200);

        // Disable all (mimics RebuiltSimManager initialization)
        manager.disableAll();

        // Simulate robot approaching: enable all pieces at once
        for (GamePiece piece : pieces) {
            piece.getBody().enable();
            piece.getBody().setAutoDisableFlag(false); // keep enabled to measure
        }

        // Step physics a few times
        for (int i = 0; i < 5; i++) {
            world.step(0.02);
        }

        double maxV = maxSpeed(pieces);
        System.out.println("Max ball speed after 5 steps: " + maxV + " m/s");

        // Balls sitting on the ground should not be moving faster than
        // a gentle settling speed. Anything above ~0.5 m/s indicates
        // explosive correction from overlap penetration.
        assertTrue(maxV < 0.5,
                "Balls exploded! Max speed = " + maxV + " m/s after enabling. " +
                "Expected calm settling (< 0.5 m/s). " +
                "Likely cause: overlapping spawn positions + sudden enable.");
    }

    // -----------------------------------------------------------------------
    // Test: Proximity-based wake should not cause explosion
    // -----------------------------------------------------------------------

    @Test
    void proximityWakeDoesNotCauseExplosion() {
        Random rand = new Random(42);
        List<GamePiece> pieces = spawnNeutralZoneCluster(rand, 200);

        // Disable all
        manager.disableAll();

        // Simulate the robot approaching from one side — use updateProximity
        // with the same parameters as RebuiltSimManager (1.5m wake, 3.0m sleep)
        Translation2d robotPos = new Translation2d(8.0, 4.0); // center of zone

        // Wake pieces near robot
        manager.updateProximity(robotPos, 1.5, 3.0);

        // Count how many got enabled
        int enabledCount = 0;
        for (GamePiece piece : pieces) {
            if (piece.getBody().isEnabled()) {
                piece.getBody().setAutoDisableFlag(false);
                enabledCount++;
            }
        }
        System.out.println("Pieces enabled by proximity: " + enabledCount);

        // Step physics
        for (int i = 0; i < 10; i++) {
            world.step(0.02);
        }

        double maxV = maxSpeed(pieces);
        System.out.println("Max ball speed after proximity wake + 10 steps: " + maxV + " m/s");

        assertTrue(maxV < 0.5,
                "Balls exploded after proximity wake! Max speed = " + maxV + " m/s. " +
                "Expected calm settling (< 0.5 m/s).");
    }

    // -----------------------------------------------------------------------
    // Test: Balls with NO jitter should settle calmly (control case)
    // -----------------------------------------------------------------------

    // -----------------------------------------------------------------------
    // Test: Full-scale neutral zone (360 balls) — measure peak speed + displacement
    // -----------------------------------------------------------------------

    @Test
    void fullScaleNeutralZoneExplosion() {
        Random rand = new Random(42);
        List<GamePiece> pieces = spawnNeutralZoneCluster(rand, 360);

        int overlaps = countOverlaps(pieces);
        System.out.println("Full-scale overlapping pairs: " + overlaps + " / " + pieces.size() + " balls");

        // Record spawn positions
        double[][] spawnPositions = new double[pieces.size()][2];
        for (int i = 0; i < pieces.size(); i++) {
            DVector3C pos = pieces.get(i).getBody().getPosition();
            spawnPositions[i][0] = pos.get0();
            spawnPositions[i][1] = pos.get1();
        }

        // Disable all, then re-enable (simulating the approach)
        manager.disableAll();
        for (GamePiece piece : pieces) {
            piece.getBody().enable();
            piece.getBody().setAutoDisableFlag(false);
        }

        // Step for 1 second (50 ticks) and track peak speed + max displacement
        double peakSpeed = 0;
        for (int i = 0; i < 50; i++) {
            world.step(0.02);
            double speed = maxSpeed(pieces);
            if (speed > peakSpeed) peakSpeed = speed;
        }

        // Measure max displacement from spawn position
        double maxDisplacement = 0;
        for (int i = 0; i < pieces.size(); i++) {
            DVector3C pos = pieces.get(i).getBody().getPosition();
            double dx = pos.get0() - spawnPositions[i][0];
            double dy = pos.get1() - spawnPositions[i][1];
            double displacement = Math.sqrt(dx * dx + dy * dy);
            if (displacement > maxDisplacement) maxDisplacement = displacement;
        }

        System.out.println("Full-scale peak speed over 1s: " + peakSpeed + " m/s");
        System.out.println("Full-scale max displacement from spawn: " + maxDisplacement + " m");
        System.out.println("  (ball diameter is " + DIAMETER + " m for reference)");

        // Balls should not have moved more than ~1 ball diameter from spawn
        assertTrue(maxDisplacement < DIAMETER,
                "Balls displaced too far! Max displacement = " + maxDisplacement +
                " m (> 1 ball diameter = " + DIAMETER + " m). " +
                "This is the visual 'explosion' effect.");
    }

    // -----------------------------------------------------------------------
    // Test: Balls with NO jitter should settle calmly (control case)
    // -----------------------------------------------------------------------

    @Test
    void ballsWithNoJitterSettleCalm() {
        // Spawn balls on perfect grid — no jitter, no overlaps
        double centerX = 8.0;
        double centerY = 4.0;
        double zoneX = 1.83;
        double zoneY = 5.23;

        int cols = (int) (zoneX / SPACING);
        int rows = (int) (zoneY / SPACING);
        double zoneStartX = centerX - zoneX / 2.0;
        double zoneStartY = centerY - zoneY / 2.0;

        List<GamePiece> pieces = new ArrayList<>();
        int count = 0;
        for (int row = 0; row < rows && count < 200; row++) {
            for (int col = 0; col < cols && count < 200; col++) {
                double x = zoneStartX + col * SPACING + RADIUS;
                double y = zoneStartY + row * SPACING + RADIUS;
                GamePiece piece = manager.spawnPiece(fuel, x, y, RADIUS + 0.001);
                pieces.add(piece);
                count++;
            }
        }

        int overlaps = countOverlaps(pieces);
        assertEquals(0, overlaps, "Perfect grid should have zero overlaps");

        // Disable, then re-enable
        manager.disableAll();
        for (GamePiece piece : pieces) {
            piece.getBody().enable();
            piece.getBody().setAutoDisableFlag(false);
        }

        for (int i = 0; i < 5; i++) {
            world.step(0.02);
        }

        double maxV = maxSpeed(pieces);
        System.out.println("Max speed with no jitter: " + maxV + " m/s");

        assertTrue(maxV < 0.5,
                "Even with no jitter, balls shouldn't explode. Max speed = " + maxV + " m/s");
    }
}
