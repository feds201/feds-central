package frc.sim.vision;

import edu.wpi.first.math.geometry.Rotation3d;
import edu.wpi.first.math.geometry.Translation3d;
import frc.sim.core.PhysicsWorld;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.ode4j.ode.*;

import java.util.LinkedHashSet;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;
import static org.ode4j.ode.OdeHelper.*;

/**
 * Tests for LimelightSim application logic: angle computation (tx/ty/ta),
 * closest-piece selection, and FPS gating.
 *
 * <p>These tests call extracted package-private methods directly with
 * synthetic ODE4J bodies at known positions. They do NOT use HAL,
 * NetworkTables, or Timer — keep it that way.
 *
 * <p><b>DO NOT modify sim-core's build.gradle to support these tests.</b>
 * The test infrastructure was carefully designed to avoid HAL/NT native
 * dependencies. If a test needs HAL or NT, refactor the production code
 * to extract testable logic instead.
 */
class LimelightSimTest {

    private static final double OBJECT_RADIUS = 0.075;
    private static final double ANGLE_EPSILON = 0.1;  // degrees
    private static final double TA_EPSILON = 0.01;

    // Matches the private constant in LimelightSim
    private static final double AREA_SCALE = 100.0;

    private PhysicsWorld physicsWorld;
    private DBody chassisBody;

    @BeforeEach
    void setUp() {
        physicsWorld = new PhysicsWorld();

        chassisBody = createBody(physicsWorld.getWorld());
        chassisBody.setPosition(0, 0, 0);
        chassisBody.setAutoDisableFlag(false);
        chassisBody.setGravityMode(false);

        DMass chassisMass = createMass();
        chassisMass.setBoxTotal(50.0, 0.8, 0.8, 0.2);
        chassisBody.setMass(chassisMass);
    }

    // -- Helpers ---------------------------------------------------------------

    /** Create a body at a known position (no geom needed — only used for coordinates). */
    private DBody createPieceAt(double x, double y, double z) {
        DBody body = createBody(physicsWorld.getWorld());
        body.setPosition(x, y, z);
        body.setAutoDisableFlag(false);
        body.setGravityMode(false);

        DMass mass = createMass();
        mass.setSphereTotal(0.2, OBJECT_RADIUS);
        body.setMass(mass);

        return body;
    }

    /** Identity camera: at chassis center, no rotation. */
    private static final Translation3d NO_OFFSET = new Translation3d();
    private static final Rotation3d NO_ROTATION = new Rotation3d();

    // -- Angle computation tests -----------------------------------------------

    @Test
    void testPieceDirectlyAheadProducesTxZeroTyZero() {
        DBody piece = createPieceAt(2.0, 0, 0);

        LimelightSim.DetectionResult result = LimelightSim.computeDetection(
                Set.of(piece), chassisBody, NO_OFFSET, NO_ROTATION, OBJECT_RADIUS);

        assertEquals(0.0, result.tx(), ANGLE_EPSILON,
                "tx should be ~0 for piece directly ahead");
        assertEquals(0.0, result.ty(), ANGLE_EPSILON,
                "ty should be ~0 for piece directly ahead");
    }

    @Test
    void testPieceToTheRightProducesPositiveTx() {
        // Negative Y = right in WPILib convention
        DBody piece = createPieceAt(2.0, -1.0, 0);

        LimelightSim.DetectionResult result = LimelightSim.computeDetection(
                Set.of(piece), chassisBody, NO_OFFSET, NO_ROTATION, OBJECT_RADIUS);

        // tx = atan2(-(-1), 2) = atan2(1, 2) ≈ 26.57°
        double expectedTx = Math.toDegrees(Math.atan2(1.0, 2.0));
        assertEquals(expectedTx, result.tx(), ANGLE_EPSILON,
                "tx should be positive when piece is to the right");
        assertEquals(0.0, result.ty(), ANGLE_EPSILON,
                "ty should be ~0 when piece is at same height");
    }

    @Test
    void testPieceAboveCameraProducesPositiveTy() {
        DBody piece = createPieceAt(2.0, 0, 1.0);

        LimelightSim.DetectionResult result = LimelightSim.computeDetection(
                Set.of(piece), chassisBody, NO_OFFSET, NO_ROTATION, OBJECT_RADIUS);

        // ty = atan2(1, 2) ≈ 26.57°
        double expectedTy = Math.toDegrees(Math.atan2(1.0, 2.0));
        assertEquals(0.0, result.tx(), ANGLE_EPSILON,
                "tx should be ~0 when piece is directly above");
        assertEquals(expectedTy, result.ty(), ANGLE_EPSILON,
                "ty should be positive when piece is above camera");
    }

    @Test
    void testTaFormulaAtKnownDistance() {
        DBody piece = createPieceAt(2.0, 0, 0);

        LimelightSim.DetectionResult result = LimelightSim.computeDetection(
                Set.of(piece), chassisBody, NO_OFFSET, NO_ROTATION, OBJECT_RADIUS);

        double distSq = 4.0; // 2^2
        double expectedTa = Math.PI * OBJECT_RADIUS * OBJECT_RADIUS / distSq * AREA_SCALE;
        assertEquals(expectedTa, result.ta(), TA_EPSILON,
                "ta should follow pi * r^2 / dist^2 * 100");
    }

    // -- Closest-piece selection tests -----------------------------------------

    @Test
    void testClosestPieceIsSelected() {
        // Close piece to the right, far piece to the left
        DBody closePiece = createPieceAt(1.0, -0.5, 0);
        DBody farPiece = createPieceAt(3.0, 0.5, 0);

        // Add far piece first so iteration order doesn't accidentally match distance order
        Set<DBody> contacts = new LinkedHashSet<>();
        contacts.add(farPiece);
        contacts.add(closePiece);

        LimelightSim.DetectionResult result = LimelightSim.computeDetection(
                contacts, chassisBody, NO_OFFSET, NO_ROTATION, OBJECT_RADIUS);

        // Close piece at negative Y → tx should be positive (right of crosshair).
        // Far piece at positive Y → tx would be negative if selected.
        assertTrue(result.tx() > 0,
                "Should select closest piece (to the right), got tx=" + result.tx());
    }

    // -- FPS gating tests ------------------------------------------------------

    @Test
    void testShouldPublishWhenEnoughTimeElapsed() {
        assertTrue(LimelightSim.shouldPublish(2.0, 0.0, 1.0),
                "Should publish when 2s elapsed and period is 1s");
    }

    @Test
    void testShouldNotPublishWithinPeriod() {
        assertFalse(LimelightSim.shouldPublish(1.5, 1.0, 1.0),
                "Should not publish when only 0.5s elapsed and period is 1s");
    }

    @Test
    void testShouldPublishAtExactBoundary() {
        assertTrue(LimelightSim.shouldPublish(2.0, 1.0, 1.0),
                "Should publish when elapsed equals period exactly");
    }
}
