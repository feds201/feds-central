package frc.sim.chassis;

import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.math.system.plant.DCMotor;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class SwerveModuleSimTest {
    // Use real Kraken X60 motor constants for analytical verification
    private static final double GEAR_RATIO = 8.14;
    private static final double WHEEL_RADIUS = 0.0476;
    private static final double NORMAL_FORCE = 55 * 9.81 / 4.0; // ~134.9N per wheel
    private static final double WHEEL_COF = 1.0;
    private static final double DT = 0.02;

    private SwerveModuleSim module;
    private DCMotor motor;

    @BeforeEach
    void setUp() {
        module = new SwerveModuleSim(
            new Translation2d(0.2667, 0.2667), GEAR_RATIO, WHEEL_RADIUS, false);
        motor = DCMotor.getKrakenX60(1);
    }

    // -----------------------------------------------------------------------
    // Helper: compute expected motor force analytically
    // -----------------------------------------------------------------------

    /**
     * Analytically compute the expected wheel force using the same DC motor model
     * as SwerveModuleSim:
     *   motorTorque = Kt * (V - backEmf) / R, clamped to stallTorque
     *   backEmf = (wheelAngVel * gearRatio) / Kv
     *   wheelForce = motorTorque * gearRatio / wheelRadius, clamped by friction
     */
    private double computeExpectedForce(double voltage, double wheelAngVel,
                                        double gearRatio, double wheelRadius,
                                        double normalForce, double cof) {
        double motorAngVel = wheelAngVel * gearRatio;
        double backEmf = motorAngVel / motor.KvRadPerSecPerVolt;
        double motorTorque = motor.KtNMPerAmp * (voltage - backEmf) / motor.rOhms;

        // Clamp motor torque to stall torque
        motorTorque = Math.max(-motor.stallTorqueNewtonMeters,
                Math.min(motor.stallTorqueNewtonMeters, motorTorque));

        // Wheel force after gearing
        double wheelForce = motorTorque * gearRatio / wheelRadius;

        // Friction limit
        double maxFriction = cof * normalForce;
        return Math.max(-maxFriction, Math.min(maxFriction, wheelForce));
    }

    // -----------------------------------------------------------------------
    // Test 1: Zero voltage produces zero force
    // -----------------------------------------------------------------------

    @Test
    void zeroVoltageProducesZeroForce() {
        // No voltage set (defaults to 0), no wheel velocity, steer at 0
        module.setDriveVoltage(0);
        module.setSteerAngle(0);
        module.setWheelAngularVelocity(0);

        double[] force = module.computeWheelForce(NORMAL_FORCE, WHEEL_COF, DT);

        assertEquals(0, force[0], 0.01,
                "fx should be zero with no voltage applied");
        assertEquals(0, force[1], 0.01,
                "fy should be zero with no voltage applied");
    }

    // -----------------------------------------------------------------------
    // Test 2: 6V forward drive produces positive fx, fy approximately 0,
    //         force within 5% of analytical prediction
    // -----------------------------------------------------------------------

    @Test
    void forwardDriveProducesCorrectForce() {
        double voltage = 6.0;
        module.setDriveVoltage(voltage);
        module.setSteerAngle(0); // pointing forward (+x in robot frame)
        module.setWheelAngularVelocity(0); // starting from rest

        double[] force = module.computeWheelForce(NORMAL_FORCE, WHEEL_COF, DT);

        double expectedForce = computeExpectedForce(voltage, 0, GEAR_RATIO, WHEEL_RADIUS,
                NORMAL_FORCE, WHEEL_COF);

        assertTrue(expectedForce > 0, "Expected force should be positive");
        assertTrue(force[0] > 0, "fx should be positive for forward drive");
        assertEquals(expectedForce, force[0], Math.abs(expectedForce) * 0.05,
                "fx should match analytical prediction within 5%");
        assertEquals(0, force[1], 0.01,
                "fy should be approximately zero when steering at 0 radians");
    }

    // -----------------------------------------------------------------------
    // Test 3: 6V at steer=PI/2 produces fx approximately 0, fy > 0
    // -----------------------------------------------------------------------

    @Test
    void steerAtHalfPiRotatesForceToY() {
        double voltage = 6.0;
        module.setDriveVoltage(voltage);
        module.setSteerAngle(Math.PI / 2); // pointing in +y direction
        module.setWheelAngularVelocity(0);

        double[] force = module.computeWheelForce(NORMAL_FORCE, WHEEL_COF, DT);

        double expectedMagnitude = computeExpectedForce(voltage, 0, GEAR_RATIO, WHEEL_RADIUS,
                NORMAL_FORCE, WHEEL_COF);

        // At steer=PI/2: fx = force*cos(PI/2) ≈ 0, fy = force*sin(PI/2) = force
        assertEquals(0, force[0], 0.01,
                "fx should be approximately zero when steering at PI/2");
        assertTrue(force[1] > 0,
                "fy should be positive when steering at PI/2");
        assertEquals(expectedMagnitude, force[1], Math.abs(expectedMagnitude) * 0.05,
                "fy should match the full force magnitude within 5%");
    }

    // -----------------------------------------------------------------------
    // Test 4: Back-EMF at free speed drives force to approximately zero
    // -----------------------------------------------------------------------

    @Test
    void backEmfAtFreeSpeedProducesNearZeroForce() {
        double voltage = 12.0;
        module.setDriveVoltage(voltage);
        module.setSteerAngle(0);

        // At free speed: V = backEmf, so motorTorque ≈ 0
        // freeSpeedRadPerSec = Kv * V (at the motor)
        // wheelAngVel = motorFreeSpeed / gearRatio
        double motorFreeSpeedRadPerSec = motor.KvRadPerSecPerVolt * voltage;
        double wheelFreeSpeedRadPerSec = motorFreeSpeedRadPerSec / GEAR_RATIO;
        module.setWheelAngularVelocity(wheelFreeSpeedRadPerSec);

        double[] force = module.computeWheelForce(NORMAL_FORCE, WHEEL_COF, DT);

        // At free speed, back-EMF equals applied voltage, so net torque is zero
        assertEquals(0, force[0], 0.01,
                "fx should be approximately zero at motor free speed");
        assertEquals(0, force[1], 0.01,
                "fy should be approximately zero at motor free speed");
    }

    // -----------------------------------------------------------------------
    // Test 5: Excessive voltage clamps force to stallTorque * gearRatio / wheelRadius
    // -----------------------------------------------------------------------

    @Test
    void excessiveVoltageClampedToStallTorque() {
        // Apply absurdly high voltage to ensure motor torque clamp engages
        double voltage = 100.0;
        module.setDriveVoltage(voltage);
        module.setSteerAngle(0);
        module.setWheelAngularVelocity(0);

        double[] force = module.computeWheelForce(NORMAL_FORCE, WHEEL_COF, DT);

        // The motor torque should be clamped to stallTorque, then geared up
        double maxMotorForce = motor.stallTorqueNewtonMeters * GEAR_RATIO / WHEEL_RADIUS;

        // Also apply friction limit (whichever is smaller constrains the output)
        double maxFriction = WHEEL_COF * NORMAL_FORCE;
        double expectedClampedForce = Math.min(maxMotorForce, maxFriction);

        assertEquals(expectedClampedForce, force[0], Math.abs(expectedClampedForce) * 0.05,
                "Force should be clamped to min(stall-geared force, friction limit)");
    }

    // -----------------------------------------------------------------------
    // Test 6: Low COF and low normal force caps force at COF * normalForce
    // -----------------------------------------------------------------------

    @Test
    void lowFrictionCapsForce() {
        double lowCOF = 0.05;
        double lowNormalForce = 50.0;
        double voltage = 6.0;

        module.setDriveVoltage(voltage);
        module.setSteerAngle(0);
        module.setWheelAngularVelocity(0);

        double[] force = module.computeWheelForce(lowNormalForce, lowCOF, DT);

        // The friction limit should be the binding constraint
        double maxFriction = lowCOF * lowNormalForce; // 0.05 * 50 = 2.5N
        assertEquals(2.5, maxFriction, 0.001, "Friction limit should be 2.5N");

        // The unclamped motor force at 6V from rest is much larger than 2.5N,
        // so friction should be the binding constraint
        double unclampedMotorForce = computeExpectedForce(voltage, 0, GEAR_RATIO, WHEEL_RADIUS,
                Double.MAX_VALUE, Double.MAX_VALUE);
        assertTrue(unclampedMotorForce > maxFriction,
                "Motor force (" + unclampedMotorForce + "N) should exceed friction limit (" +
                maxFriction + "N) for this test to be meaningful");

        assertEquals(maxFriction, force[0], maxFriction * 0.05,
                "fx should be capped at COF * normalForce = 2.5N");
        assertEquals(0, force[1], 0.01,
                "fy should be zero at steer angle 0");
    }

    // -----------------------------------------------------------------------
    // Test 7: Two modules with different gear ratios produce proportional forces
    // -----------------------------------------------------------------------

    @Test
    void doubleGearRatioProducesApproximatelyDoubleForce() {
        double voltage = 6.0;
        double gearRatioA = 4.0;
        double gearRatioB = 8.0; // 2x of A

        SwerveModuleSim moduleA = new SwerveModuleSim(
            new Translation2d(0.2667, 0.2667), gearRatioA, WHEEL_RADIUS, false);
        SwerveModuleSim moduleB = new SwerveModuleSim(
            new Translation2d(0.2667, 0.2667), gearRatioB, WHEEL_RADIUS, false);

        moduleA.setDriveVoltage(voltage);
        moduleA.setSteerAngle(0);
        moduleA.setWheelAngularVelocity(0);

        moduleB.setDriveVoltage(voltage);
        moduleB.setSteerAngle(0);
        moduleB.setWheelAngularVelocity(0);

        // Use high friction limit so friction doesn't cap either module
        double highNormalForce = 10000;
        double highCOF = 10.0;

        double[] forceA = moduleA.computeWheelForce(highNormalForce, highCOF, DT);
        double[] forceB = moduleB.computeWheelForce(highNormalForce, highCOF, DT);

        // wheelForce = motorTorque * gearRatio / wheelRadius
        // motorTorque = Kt * (V - backEmf) / R
        // At wheelAngVel=0, backEmf=0 for both, so motorTorque is identical.
        // Therefore forceB / forceA = gearRatioB / gearRatioA = 2.0
        double expectedForceA = computeExpectedForce(voltage, 0, gearRatioA, WHEEL_RADIUS,
                highNormalForce, highCOF);
        double expectedForceB = computeExpectedForce(voltage, 0, gearRatioB, WHEEL_RADIUS,
                highNormalForce, highCOF);

        assertEquals(expectedForceA, forceA[0], Math.abs(expectedForceA) * 0.05,
                "Module A force should match analytical value");
        assertEquals(expectedForceB, forceB[0], Math.abs(expectedForceB) * 0.05,
                "Module B force should match analytical value");

        double ratio = forceB[0] / forceA[0];
        assertEquals(2.0, ratio, 2.0 * 0.05,
                "2x gear ratio should produce approximately 2x force");
    }

    // -----------------------------------------------------------------------
    // Test 8: Rotor position accumulates correctly over 50 steps
    // -----------------------------------------------------------------------

    @Test
    void rotorPositionAccumulatesCorrectly() {
        module.setDriveVoltage(6.0);
        module.setSteerAngle(0);

        // Set a constant wheel angular velocity so position accumulation is predictable
        double wheelAngVel = 10.0; // rad/s at the wheel
        module.setWheelAngularVelocity(wheelAngVel);

        int steps = 50;
        for (int i = 0; i < steps; i++) {
            module.computeWheelForce(NORMAL_FORCE, WHEEL_COF, DT);
        }

        // Expected rotor position:
        //   Each tick adds: (wheelAngVel / (2*PI)) * gearRatio * dt rotor rotations
        //   Over 50 ticks: (10 / (2*PI)) * 8.14 * 0.02 * 50
        double expectedRotorRotations = (wheelAngVel / (2.0 * Math.PI)) * GEAR_RATIO * DT * steps;

        double actualRotorPosition = module.getDriveRotorPositionRot();
        assertEquals(expectedRotorRotations, actualRotorPosition,
                Math.abs(expectedRotorRotations) * 0.05,
                "Rotor position should accumulate correctly over 50 steps");

        // Also verify it's a reasonable magnitude
        assertTrue(actualRotorPosition > 0,
                "Rotor position should be positive for positive wheel angular velocity");
    }

    // -----------------------------------------------------------------------
    // Test 9: Inverted module negates force and rotor position
    // -----------------------------------------------------------------------

    @Test
    void invertedModuleNegatesForceAndRotorPosition() {
        double voltage = 6.0;
        double wheelAngVel = 5.0;

        // Normal (non-inverted) module
        SwerveModuleSim normalModule = new SwerveModuleSim(
            new Translation2d(0.2667, 0.2667), GEAR_RATIO, WHEEL_RADIUS, false);
        normalModule.setDriveVoltage(voltage);
        normalModule.setSteerAngle(0);
        normalModule.setWheelAngularVelocity(wheelAngVel);

        // Inverted module
        SwerveModuleSim invertedModule = new SwerveModuleSim(
            new Translation2d(0.2667, 0.2667), GEAR_RATIO, WHEEL_RADIUS, true);
        invertedModule.setDriveVoltage(voltage);
        invertedModule.setSteerAngle(0);
        invertedModule.setWheelAngularVelocity(wheelAngVel);

        // Run both for a few steps
        int steps = 10;
        double[] normalForce = null;
        double[] invertedForce = null;
        for (int i = 0; i < steps; i++) {
            normalForce = normalModule.computeWheelForce(NORMAL_FORCE, WHEEL_COF, DT);
            invertedForce = invertedModule.computeWheelForce(NORMAL_FORCE, WHEEL_COF, DT);
        }

        // Inverted module receives negated voltage internally via setDriveVoltage,
        // so the force direction should be opposite.
        // With the same wheelAngVel and opposite voltage:
        //   normal:   torque = Kt * (V - backEmf) / R
        //   inverted: torque = Kt * (-V - backEmf) / R
        assertEquals(-normalForce[0], invertedForce[0], Math.abs(normalForce[0]) * 0.05,
                "Inverted module should produce negated fx");
        assertEquals(-normalForce[1], invertedForce[1], 0.01,
                "Inverted module should produce negated fy");

        // Rotor position: getDriveRotorPositionRot() negates for inverted modules
        double normalPos = normalModule.getDriveRotorPositionRot();
        double invertedPos = invertedModule.getDriveRotorPositionRot();
        assertEquals(-normalPos, invertedPos, Math.abs(normalPos) * 0.05,
                "Inverted module should report negated rotor position");
    }

    // -----------------------------------------------------------------------
    // Brownout / force asymmetry tests
    // -----------------------------------------------------------------------

    private static final double MODULE_OFFSET = 0.2667;
    private static final Translation2d[] MODULE_POSITIONS = {
        new Translation2d(MODULE_OFFSET, MODULE_OFFSET),   // FL
        new Translation2d(MODULE_OFFSET, -MODULE_OFFSET),  // FR
        new Translation2d(-MODULE_OFFSET, MODULE_OFFSET),  // BL
        new Translation2d(-MODULE_OFFSET, -MODULE_OFFSET)  // BR
    };

    /** Compute net yaw torque from 4 swerve modules about robot center. */
    private double computeNetYawTorque(SwerveModuleSim[] modules, double normalForce, double cof) {
        double netTorque = 0;
        for (int i = 0; i < modules.length; i++) {
            double[] force = modules[i].computeWheelForce(normalForce, cof, DT);
            // 2D cross product: torque = pos.x * fy - pos.y * fx
            netTorque += MODULE_POSITIONS[i].getX() * force[1]
                       - MODULE_POSITIONS[i].getY() * force[0];
        }
        return netTorque;
    }

    // -----------------------------------------------------------------------
    // Test 10: Symmetric modules produce zero net yaw torque
    // -----------------------------------------------------------------------

    @Test
    void symmetricModulesProduceZeroNetTorque() {
        SwerveModuleSim[] modules = new SwerveModuleSim[4];
        for (int i = 0; i < 4; i++) {
            modules[i] = new SwerveModuleSim(MODULE_POSITIONS[i], GEAR_RATIO, WHEEL_RADIUS, false);
            modules[i].setDriveVoltage(12.0);
            modules[i].setSteerAngle(0);
            modules[i].setWheelAngularVelocity(20.0);
        }

        // High friction limit so motor torque is the binding constraint
        double netTorque = computeNetYawTorque(modules, 10000, 10.0);
        assertEquals(0, netTorque, 0.01,
                "Symmetric modules should produce zero net yaw torque");
    }

    // -----------------------------------------------------------------------
    // Test 11: Asymmetric voltage (brownout on one module) creates net torque
    //
    // This demonstrates WHY brownout causes parasitic rotation:
    // if modules see different supply voltage, forces become asymmetric.
    // -----------------------------------------------------------------------

    @Test
    void asymmetricBrownoutVoltageCreatesNetTorque() {
        SwerveModuleSim[] modules = new SwerveModuleSim[4];
        for (int i = 0; i < 4; i++) {
            modules[i] = new SwerveModuleSim(MODULE_POSITIONS[i], GEAR_RATIO, WHEEL_RADIUS, false);
            modules[i].setSteerAngle(0);
            modules[i].setWheelAngularVelocity(20.0);
        }

        // FL gets brownout voltage, others get normal
        modules[0].setDriveVoltage(8.0);
        modules[1].setDriveVoltage(12.0);
        modules[2].setDriveVoltage(12.0);
        modules[3].setDriveVoltage(12.0);

        double netTorque = computeNetYawTorque(modules, 10000, 10.0);
        assertTrue(Math.abs(netTorque) > 1.0,
                "Brownout on one module should create significant net torque, got "
                        + String.format("%.2f", netTorque) + " N*m");
    }

    // -----------------------------------------------------------------------
    // Test 12: Asymmetric wheel speeds (post-collision) create net torque
    //
    // After hitting a wall, some wheels are nearly stalled while others spin.
    // Under the same voltage, different back-EMF → different force → rotation.
    // -----------------------------------------------------------------------

    @Test
    void asymmetricWheelSpeedsCreateNetTorque() {
        SwerveModuleSim[] modules = new SwerveModuleSim[4];
        for (int i = 0; i < 4; i++) {
            modules[i] = new SwerveModuleSim(MODULE_POSITIONS[i], GEAR_RATIO, WHEEL_RADIUS, false);
            modules[i].setDriveVoltage(9.0); // brownout voltage for all
            modules[i].setSteerAngle(0);
        }

        // Left-side wheels nearly stalled (hit wall), right-side still spinning
        modules[0].setWheelAngularVelocity(2.0);   // FL — nearly stalled
        modules[1].setWheelAngularVelocity(40.0);  // FR — spinning
        modules[2].setWheelAngularVelocity(2.0);   // BL — nearly stalled
        modules[3].setWheelAngularVelocity(40.0);  // BR — spinning

        double netTorque = computeNetYawTorque(modules, 10000, 10.0);
        assertTrue(Math.abs(netTorque) > 1.0,
                "Asymmetric wheel speeds under brownout should create net torque, got "
                        + String.format("%.2f", netTorque) + " N*m");
    }
}
