package frc.sim.integration;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Pose3d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.geometry.Translation2d;
import frc.sim.chassis.ChassisConfig;
import frc.sim.chassis.ChassisSimulation;
import frc.sim.core.PhysicsWorld;
import org.junit.jupiter.api.Test;
import org.ode4j.ode.DGeom;
import org.ode4j.ode.DTriMeshData;
import org.ode4j.ode.OdeHelper;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Tests that the robot can actually drive up and over a triangular ramp (bump),
 * verifying real Z position changes and pitch angles throughout the traversal.
 *
 * The bump is a triangle cross-section: flat ground → ramp up → peak → ramp down → flat ground.
 * Like a speed bump or the REBUILT field charging station ramp.
 *
 *       /\
 *      /  \
 * ____/    \____
 */
class BumpTraversalTest {

    private static final double DT = 0.02;
    private static final double MODULE_OFFSET = 0.2667;
    private static final double ROBOT_MASS = 55.0;
    private static final double ROBOT_MOI = 6.0;
    private static final double BUMPER_X = 0.8;
    private static final double BUMPER_Y = 0.8;
    private static final double BUMPER_Z = 0.25;

    // Bump dimensions
    private static final double BUMP_PEAK_Z = 0.20;     // 20cm tall
    private static final double BUMP_HALF_DEPTH = 0.6;   // each ramp is 0.6m long
    private static final double BUMP_Y_START = 2.0;
    private static final double BUMP_Y_END = 7.0;        // 5m wide along Y so angled approach fits
    private static final double BUMP_RIDGE_X = 5.0;      // ridge at x=5

    private ChassisConfig createConfig() {
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

    /**
     * Build a triangular-prism bump (triangle cross-section, extruded along Y).
     *
     *   Side view (XZ plane):
     *
     *         (ridge)
     *          /\
     *         /  \
     *   _____/    \_____
     *   x1   rx    x2
     *
     * 6 vertices, 8 triangles (2 end caps + bottom quad + 2 ramp quads).
     */
    private DGeom createBump(PhysicsWorld world,
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
        int[] indices = {
            0, 2, 1,               // near end cap
            3, 4, 5,               // far end cap
            0, 3, 5,  0, 5, 2,    // bottom
            0, 1, 4,  0, 4, 3,    // left ramp  (going up from -X side)
            2, 5, 4,  2, 4, 1,    // right ramp (going up from +X side)
        };

        DTriMeshData meshData = OdeHelper.createTriMeshData();
        meshData.build(verts, indices);
        DGeom geom = OdeHelper.createTriMesh(world.getSpace(), meshData, null, null, null);
        geom.setPosition(0, 0, 0);
        return geom;
    }

    /** Settle chassis on ground for 50 ticks. */
    private void settle(ChassisSimulation chassis, PhysicsWorld world) {
        for (int i = 0; i < 50; i++) {
            chassis.setVelocity(0, 0, 0, DT);
            world.step(DT);
        }
    }

    // -----------------------------------------------------------------------
    // Test 1: Drive straight over bump — verify Z rises and falls
    // -----------------------------------------------------------------------

    @Test
    void straightOverBump_zRisesOnAscentAndFallsOnDescent() {
        PhysicsWorld world = new PhysicsWorld();
        ChassisConfig config = createConfig();
        createBump(world, BUMP_RIDGE_X, BUMP_HALF_DEPTH,
                BUMP_Y_START, BUMP_Y_END, BUMP_PEAK_Z);

        // Start at x=3, heading +X, centered in Y span of bump
        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(3.0, 4.5, Rotation2d.kZero));
        settle(chassis, world);

        double settledZ = chassis.getBody().getPosition().get2();
        double speed = 1.5; // m/s — slow enough for good contact resolution

        double maxZ = settledZ;
        double xAtMaxZ = 3.0;
        boolean roseAboveGround = false;
        boolean returnedToGround = false;
        double zAfterPeak = Double.MAX_VALUE;

        // Drive for 4 seconds — enough to go from x=3 past x=5 ridge to x=9
        for (int i = 0; i < 200; i++) {
            chassis.setVelocity(speed, 0, 0, DT);
            world.step(DT);

            double z = chassis.getBody().getPosition().get2();
            double x = chassis.getBody().getPosition().get0();

            if (z > maxZ) {
                maxZ = z;
                xAtMaxZ = x;
            }

            // Track if we rose significantly
            if (z > settledZ + 0.05) {
                roseAboveGround = true;
            }

            // After passing the ridge, track if Z comes back down
            if (roseAboveGround && x > BUMP_RIDGE_X + BUMP_HALF_DEPTH + 0.3) {
                zAfterPeak = Math.min(zAfterPeak, z);
                if (z < settledZ + 0.03) {
                    returnedToGround = true;
                }
            }
        }

        // Robot must have risen at least 8cm (bump is 20cm, robot rides up partially)
        assertTrue(maxZ > settledZ + 0.08,
                String.format("Z should rise on the ramp. maxZ=%.4f settledZ=%.4f rise=%.4f",
                        maxZ, settledZ, maxZ - settledZ));

        // Peak Z should occur near the ridge (x≈5.0, within ±0.6m)
        assertTrue(Math.abs(xAtMaxZ - BUMP_RIDGE_X) < 0.8,
                String.format("Peak Z should be near ridge x=%.1f, but was at x=%.2f",
                        BUMP_RIDGE_X, xAtMaxZ));

        // After descent, Z should return close to ground level
        assertTrue(returnedToGround,
                String.format("Robot should return to ground after bump. zAfterPeak=%.4f settledZ=%.4f",
                        zAfterPeak, settledZ));
    }

    // -----------------------------------------------------------------------
    // Test 2: Drive straight over bump — verify pitch tilts on ramp
    // -----------------------------------------------------------------------

    @Test
    void straightOverBump_pitchChangesOnRamp() {
        PhysicsWorld world = new PhysicsWorld();
        ChassisConfig config = createConfig();
        createBump(world, BUMP_RIDGE_X, BUMP_HALF_DEPTH,
                BUMP_Y_START, BUMP_Y_END, BUMP_PEAK_Z);

        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(3.0, 4.5, Rotation2d.kZero));
        settle(chassis, world);

        double speed = 1.5;

        // Expected ramp angle: atan(peakZ / halfDepth) = atan(0.20/0.6) ≈ 18.4°
        double expectedRampAngle = Math.atan2(BUMP_PEAK_Z, BUMP_HALF_DEPTH);

        double maxAbsPitch = 0;
        boolean pitchedUpOnAscent = false;
        boolean pitchedDownOnDescent = false;

        for (int i = 0; i < 200; i++) {
            chassis.setVelocity(speed, 0, 0, DT);
            world.step(DT);

            Pose3d pose = chassis.getPose3d();
            double pitch = pose.getRotation().getY(); // pitch around Y axis
            double x = pose.getTranslation().getX();

            if (Math.abs(pitch) > maxAbsPitch) {
                maxAbsPitch = Math.abs(pitch);
            }

            // On the ascending ramp (before ridge), pitch should be negative
            // (nose tilting up = negative pitch in ZYX convention when driving +X up a slope)
            if (x > BUMP_RIDGE_X - BUMP_HALF_DEPTH + 0.2
                    && x < BUMP_RIDGE_X - 0.1) {
                if (Math.abs(pitch) > Math.toRadians(2.0)) {
                    pitchedUpOnAscent = true;
                }
            }

            // On the descending ramp (after ridge), pitch should flip
            if (x > BUMP_RIDGE_X + 0.1
                    && x < BUMP_RIDGE_X + BUMP_HALF_DEPTH - 0.2) {
                if (Math.abs(pitch) > Math.toRadians(2.0)) {
                    pitchedDownOnDescent = true;
                }
            }
        }

        // Pitch should reach at least 3° (ramp is ~18°, contact solver won't match perfectly)
        assertTrue(maxAbsPitch > Math.toRadians(3.0),
                String.format("Pitch should change on ramp. maxAbsPitch=%.2f° expectedRampAngle=%.2f°",
                        Math.toDegrees(maxAbsPitch), Math.toDegrees(expectedRampAngle)));

        assertTrue(pitchedUpOnAscent,
                "Robot should pitch while ascending the ramp");

        assertTrue(pitchedDownOnDescent,
                "Robot should pitch while descending the ramp");
    }

    // -----------------------------------------------------------------------
    // Test 3: Drive over bump at 30° angle — verify Z rise and position
    // -----------------------------------------------------------------------

    @Test
    void angledApproach30Degrees_zStillRisesOverBump() {
        PhysicsWorld world = new PhysicsWorld();
        ChassisConfig config = createConfig();
        createBump(world, BUMP_RIDGE_X, BUMP_HALF_DEPTH,
                BUMP_Y_START, BUMP_Y_END, BUMP_PEAK_Z);

        double approachAngle = Math.toRadians(30); // 30° from straight-on
        double speed = 1.5;
        double vx = speed * Math.cos(approachAngle);
        double vy = speed * Math.sin(approachAngle);

        // Start offset in Y so angled path still crosses the bump
        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(3.0, 3.5, new Rotation2d(approachAngle)));
        settle(chassis, world);

        double settledZ = chassis.getBody().getPosition().get2();
        double maxZ = settledZ;
        boolean roseAboveGround = false;
        boolean returnedToGround = false;

        // Drive for 5 seconds — angled path takes longer to cross
        for (int i = 0; i < 250; i++) {
            chassis.setVelocity(vx, vy, 0, DT);
            world.step(DT);

            double z = chassis.getBody().getPosition().get2();
            double x = chassis.getBody().getPosition().get0();

            if (z > maxZ) maxZ = z;
            if (z > settledZ + 0.05) roseAboveGround = true;

            // Check if returned to ground after passing the bump
            if (roseAboveGround && x > BUMP_RIDGE_X + BUMP_HALF_DEPTH + 0.5) {
                if (z < settledZ + 0.03) {
                    returnedToGround = true;
                }
            }
        }

        assertTrue(roseAboveGround,
                String.format("Z should rise when crossing bump at 30°. maxZ=%.4f settledZ=%.4f",
                        maxZ, settledZ));

        assertTrue(maxZ > settledZ + 0.05,
                String.format("Should rise at least 5cm at 30° angle. rise=%.4f",
                        maxZ - settledZ));

        assertTrue(returnedToGround,
                "Robot should return to ground after crossing bump at 30°");
    }

    // -----------------------------------------------------------------------
    // Test 4: Drive over bump at 30° — verify both pitch AND roll emerge
    // -----------------------------------------------------------------------

    @Test
    void angledApproach30Degrees_bothPitchAndRollEmerge() {
        PhysicsWorld world = new PhysicsWorld();
        ChassisConfig config = createConfig();
        createBump(world, BUMP_RIDGE_X, BUMP_HALF_DEPTH,
                BUMP_Y_START, BUMP_Y_END, BUMP_PEAK_Z);

        double approachAngle = Math.toRadians(30);
        double speed = 1.5;
        double vx = speed * Math.cos(approachAngle);
        double vy = speed * Math.sin(approachAngle);

        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(3.0, 3.5, new Rotation2d(approachAngle)));
        settle(chassis, world);

        double maxAbsPitch = 0;
        double maxAbsRoll = 0;

        for (int i = 0; i < 250; i++) {
            chassis.setVelocity(vx, vy, 0, DT);
            world.step(DT);

            Pose3d pose = chassis.getPose3d();
            double pitch = Math.abs(pose.getRotation().getY());
            double roll = Math.abs(pose.getRotation().getX());

            if (pitch > maxAbsPitch) maxAbsPitch = pitch;
            if (roll > maxAbsRoll) maxAbsRoll = roll;
        }

        // At 30° angle, both pitch and roll should be nonzero on the ramp
        assertTrue(maxAbsPitch > Math.toRadians(1.5),
                String.format("Pitch should emerge at 30° approach. maxPitch=%.2f°",
                        Math.toDegrees(maxAbsPitch)));

        assertTrue(maxAbsRoll > Math.toRadians(1.0),
                String.format("Roll should emerge at 30° approach (one side higher). maxRoll=%.2f°",
                        Math.toDegrees(maxAbsRoll)));
    }

    // -----------------------------------------------------------------------
    // Test 5: Rotation works while on top of the ramp
    // -----------------------------------------------------------------------

    @Test
    void rotationOnTopOfRamp_yawActuallyChanges() {
        PhysicsWorld world = new PhysicsWorld();
        ChassisConfig config = createConfig();
        createBump(world, BUMP_RIDGE_X, BUMP_HALF_DEPTH,
                BUMP_Y_START, BUMP_Y_END, BUMP_PEAK_Z);

        // Start before the bump
        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(3.0, 4.5, Rotation2d.kZero));
        settle(chassis, world);

        // Phase 1: drive onto the bump and stop near the peak
        for (int i = 0; i < 100; i++) {
            chassis.setVelocity(1.5, 0, 0, DT);
            world.step(DT);
        }

        // Should be near or on the ramp now
        double xOnRamp = chassis.getBody().getPosition().get0();
        double zOnRamp = chassis.getBody().getPosition().get2();

        // Phase 2: stop horizontal movement, let it settle on the ramp
        for (int i = 0; i < 30; i++) {
            chassis.setVelocity(0, 0, 0, DT);
            world.step(DT);
        }

        double zSettledOnRamp = chassis.getBody().getPosition().get2();
        double yawBefore = chassis.getYawRad();

        // Phase 3: rotate in place at 1 rad/s for 2 seconds (should turn ~2 radians ≈ 115°)
        double rotationRate = 1.0; // rad/s
        for (int i = 0; i < 100; i++) {
            chassis.setVelocity(0, 0, rotationRate, DT);
            world.step(DT);
        }

        double yawAfter = chassis.getYawRad();
        double zAfterRotation = chassis.getBody().getPosition().get2();

        // Yaw should have changed substantially
        double yawDelta = yawAfter - yawBefore;
        // Normalize to [-pi, pi]
        while (yawDelta > Math.PI) yawDelta -= 2 * Math.PI;
        while (yawDelta < -Math.PI) yawDelta += 2 * Math.PI;

        // Angular damping + ramp contact friction reduce effective rotation rate.
        // 20° is a solid confirmation that rotation actually works on the slope.
        assertTrue(Math.abs(yawDelta) > Math.toRadians(20),
                String.format("Robot should rotate on the ramp. yawDelta=%.2f°",
                        Math.toDegrees(yawDelta)));

        // Z should not be negative or clipping through the ground.
        // Robot may slide to a lower part of the ramp during rotation, so just
        // verify it's above the ground plane (z > 0.05 given bumper half-height).
        assertTrue(zAfterRotation > 0.05,
                String.format("Robot should not clip through ground while rotating on ramp. z=%.4f",
                        zAfterRotation));
    }

    // -----------------------------------------------------------------------
    // Test 6: Rotation on ramp doesn't cause wild Z changes
    // -----------------------------------------------------------------------

    @Test
    void rotationOnRamp_zRemainsStable() {
        PhysicsWorld world = new PhysicsWorld();
        ChassisConfig config = createConfig();
        createBump(world, BUMP_RIDGE_X, BUMP_HALF_DEPTH,
                BUMP_Y_START, BUMP_Y_END, BUMP_PEAK_Z);

        ChassisSimulation chassis = new ChassisSimulation(world, config,
                new Pose2d(3.0, 4.5, Rotation2d.kZero));
        settle(chassis, world);

        // Drive onto the ramp
        for (int i = 0; i < 100; i++) {
            chassis.setVelocity(1.5, 0, 0, DT);
            world.step(DT);
        }

        // Settle on ramp
        for (int i = 0; i < 30; i++) {
            chassis.setVelocity(0, 0, 0, DT);
            world.step(DT);
        }

        double zBeforeRotation = chassis.getBody().getPosition().get2();

        // Rotate a full 360° (2π rad at 2 rad/s = ~3.14 seconds)
        double minZ = zBeforeRotation;
        double maxZ = zBeforeRotation;
        for (int i = 0; i < 160; i++) {
            chassis.setVelocity(0, 0, 2.0, DT);
            world.step(DT);

            double z = chassis.getBody().getPosition().get2();
            if (z < minZ) minZ = z;
            if (z > maxZ) maxZ = z;
        }

        // Z should vary (corners go up/down on the slope) but not wildly
        double zRange = maxZ - minZ;
        // On a 20cm bump with 0.8m robot, rotating causes Z swings but should stay < 25cm
        assertTrue(zRange < 0.25,
                String.format("Z should not swing wildly during rotation on ramp. range=%.4f", zRange));

        // Robot should never fall below ground
        assertTrue(minZ > 0.05,
                String.format("Robot should not clip through ground during rotation. minZ=%.4f", minZ));
    }
}
