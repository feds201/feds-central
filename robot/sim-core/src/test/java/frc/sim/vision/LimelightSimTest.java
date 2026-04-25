package frc.sim.vision;

import edu.wpi.first.math.geometry.Rotation3d;
import edu.wpi.first.math.geometry.Translation3d;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Tests for LimelightSim application logic: angle computation (tx/ty/ta),
 * frustum inclusion, and FPS gating.
 *
 * <p>These tests call extracted package-private static helpers directly with
 * camera-frame {@link Translation3d} inputs. They do NOT use HAL,
 * NetworkTables, Timer, or ODE4J — keep it that way.
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

    // -- Angle computation tests -----------------------------------------------

    @Test
    void testPieceDirectlyAheadProducesTxZeroTyZero() {
        LimelightSim.DetectionResult result = LimelightSim.computeDetectionFromCameraFrame(
                new Translation3d(2.0, 0, 0), OBJECT_RADIUS);

        assertEquals(0.0, result.tx(), ANGLE_EPSILON,
                "tx should be ~0 for piece directly ahead");
        assertEquals(0.0, result.ty(), ANGLE_EPSILON,
                "ty should be ~0 for piece directly ahead");
    }

    @Test
    void testPieceToTheRightProducesPositiveTx() {
        // Negative Y = right in WPILib convention
        LimelightSim.DetectionResult result = LimelightSim.computeDetectionFromCameraFrame(
                new Translation3d(2.0, -1.0, 0), OBJECT_RADIUS);

        // tx = atan2(-(-1), 2) = atan2(1, 2) ≈ 26.57°
        double expectedTx = Math.toDegrees(Math.atan2(1.0, 2.0));
        assertEquals(expectedTx, result.tx(), ANGLE_EPSILON,
                "tx should be positive when piece is to the right");
        assertEquals(0.0, result.ty(), ANGLE_EPSILON,
                "ty should be ~0 when piece is at same height");
    }

    @Test
    void testPieceAboveCameraProducesPositiveTy() {
        LimelightSim.DetectionResult result = LimelightSim.computeDetectionFromCameraFrame(
                new Translation3d(2.0, 0, 1.0), OBJECT_RADIUS);

        double expectedTy = Math.toDegrees(Math.atan2(1.0, 2.0));
        assertEquals(0.0, result.tx(), ANGLE_EPSILON,
                "tx should be ~0 when piece is directly above");
        assertEquals(expectedTy, result.ty(), ANGLE_EPSILON,
                "ty should be positive when piece is above camera");
    }

    @Test
    void testTaFormulaAtKnownDistance() {
        LimelightSim.DetectionResult result = LimelightSim.computeDetectionFromCameraFrame(
                new Translation3d(2.0, 0, 0), OBJECT_RADIUS);

        double distSq = 4.0; // 2^2
        double expectedTa = Math.PI * OBJECT_RADIUS * OBJECT_RADIUS / distSq * AREA_SCALE;
        assertEquals(expectedTa, result.ta(), TA_EPSILON,
                "ta should follow pi * r^2 / dist^2 * 100");
    }

    // -- Frustum inclusion tests -----------------------------------------------

    private static final double NEAR = 0.3;
    private static final double FAR = 3.0;
    private static final double HFOV_HALF = Math.toRadians(31.65); // LL3 horizontal, halved
    private static final double VFOV_HALF = Math.toRadians(24.85); // LL3 vertical, halved

    @Test
    void testFrustumIncludesPieceDirectlyAhead() {
        assertTrue(LimelightSim.inFrustum(
                new Translation3d(1.0, 0, 0), NEAR, FAR, HFOV_HALF, VFOV_HALF));
    }

    @Test
    void testFrustumExcludesPieceBehindCamera() {
        assertFalse(LimelightSim.inFrustum(
                new Translation3d(-1.0, 0, 0), NEAR, FAR, HFOV_HALF, VFOV_HALF));
    }

    @Test
    void testFrustumExcludesPieceCloserThanNear() {
        assertFalse(LimelightSim.inFrustum(
                new Translation3d(0.1, 0, 0), NEAR, FAR, HFOV_HALF, VFOV_HALF));
    }

    @Test
    void testFrustumExcludesPieceFartherThanFar() {
        assertFalse(LimelightSim.inFrustum(
                new Translation3d(5.0, 0, 0), NEAR, FAR, HFOV_HALF, VFOV_HALF));
    }

    @Test
    void testFrustumExcludesPieceOutsideHorizontalFov() {
        // 2m forward, 5m to the left → angle ≈ 68° → way beyond HFov/2
        assertFalse(LimelightSim.inFrustum(
                new Translation3d(2.0, 5.0, 0), NEAR, FAR, HFOV_HALF, VFOV_HALF));
    }

    @Test
    void testFrustumExcludesPieceOutsideVerticalFov() {
        assertFalse(LimelightSim.inFrustum(
                new Translation3d(2.0, 0, 5.0), NEAR, FAR, HFOV_HALF, VFOV_HALF));
    }

    // -- World → camera-frame transform tests ----------------------------------

    @Test
    void testWorldToCameraFrameIdentityChassis() {
        // Chassis at origin facing +X, no camera offset. Piece at (2,0,0) world.
        Translation3d camDelta = LimelightSim.worldToCameraFrame(
                new Translation3d(2.0, 0, 0),
                0.0, 0.0, 1.0, 0.0,
                new Translation3d(), new Rotation3d());
        assertEquals(2.0, camDelta.getX(), 1e-9);
        assertEquals(0.0, camDelta.getY(), 1e-9);
        assertEquals(0.0, camDelta.getZ(), 1e-9);
    }

    @Test
    void testWorldToCameraFrameChassisRotated90() {
        // Chassis at origin facing +Y (90°). Piece at (0, 2, 0) world → chassis-local (2, 0, 0).
        double theta = Math.PI / 2.0;
        Translation3d camDelta = LimelightSim.worldToCameraFrame(
                new Translation3d(0, 2.0, 0),
                0.0, 0.0, Math.cos(theta), Math.sin(theta),
                new Translation3d(), new Rotation3d());
        assertEquals(2.0, camDelta.getX(), 1e-9);
        assertEquals(0.0, camDelta.getY(), 1e-9);
    }

    @Test
    void testWorldToCameraFrameChassisTranslated() {
        // Chassis at (1,1) facing +X. Piece at (3,1) → camDelta (2,0,0).
        Translation3d camDelta = LimelightSim.worldToCameraFrame(
                new Translation3d(3.0, 1.0, 0),
                1.0, 1.0, 1.0, 0.0,
                new Translation3d(), new Rotation3d());
        assertEquals(2.0, camDelta.getX(), 1e-9);
        assertEquals(0.0, camDelta.getY(), 1e-9);
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
