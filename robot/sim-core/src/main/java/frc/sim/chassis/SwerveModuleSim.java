package frc.sim.chassis;

import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.math.system.plant.DCMotor;

/**
 * Simulates a single swerve module: reads motor voltages, computes wheel
 * forces using a DC motor model and tire friction limit.
 *
 * Motor model: V = I*R + Kv*omega → torque = Kt * I = Kt * (V - Kv*omega) / R
 * Wheel force = torque * gearRatio / wheelRadius, capped by friction.
 */
public class SwerveModuleSim {
    private final Translation2d position; // module position relative to robot center
    private final double driveGearRatio;
    private final double wheelRadius;
    private final boolean driveInverted;

    /** DC motor model (Kraken X60). Provides Kv, Kt, R, and stall torque constants. */
    private final DCMotor driveMotor = DCMotor.getKrakenX60(1);

    /** Current drive motor voltage (volts, after inversion). */
    private double driveVoltage = 0;
    /** Current steering angle (radians, 0 = forward, positive = counterclockwise). */
    private double steerAngleRad = 0;
    /** Current wheel angular velocity (rad/s at the wheel, not the motor). */
    private double wheelAngularVelocity = 0;

    /** Accumulated drive rotor position in rotations (what TalonFXSimState reads). */
    private double driveRotorPositionRot = 0;

    public SwerveModuleSim(Translation2d position, double driveGearRatio,
                           double wheelRadius, boolean driveInverted) {
        this.position = position;
        this.driveGearRatio = driveGearRatio;
        this.wheelRadius = wheelRadius;
        this.driveInverted = driveInverted;
    }

    /** Set the drive motor voltage (from TalonFXSimState). */
    public void setDriveVoltage(double voltage) {
        this.driveVoltage = driveInverted ? -voltage : voltage;
    }

    /** Set the current steering angle (from CANcoderSimState or steer motor). */
    public void setSteerAngle(double angleRad) {
        this.steerAngleRad = angleRad;
    }

    /**
     * Compute the force this module applies to the chassis.
     * Returns force vector in robot-relative frame.
     *
     * @param normalForce the normal force on this wheel (N), typically mass*g/4
     * @param wheelCOF coefficient of friction between wheel and ground
     * @param dt timestep
     * @return [fx, fy] force in robot frame (Newtons)
     */
    public double[] computeWheelForce(double normalForce, double wheelCOF, double dt) {
        // Motor torque: T = Kt * I = Kt * (V - V_bemf) / R
        // V_bemf = omega_motor / Kv  (Kv in rad/s per volt)
        double motorVelocityRadPerSec = wheelAngularVelocity * driveGearRatio;
        double backEmfVolts = motorVelocityRadPerSec / driveMotor.KvRadPerSecPerVolt;
        double motorTorque = driveMotor.KtNMPerAmp *
                (driveVoltage - backEmfVolts) / driveMotor.rOhms;

        // Clamp motor torque to stall torque
        motorTorque = Math.max(-driveMotor.stallTorqueNewtonMeters,
                Math.min(driveMotor.stallTorqueNewtonMeters, motorTorque));

        // Wheel torque after gearing
        double wheelTorque = motorTorque * driveGearRatio;

        // Force at wheel contact
        double motorForce = wheelTorque / wheelRadius;

        // Friction limit
        double maxFriction = wheelCOF * normalForce;
        double force = Math.max(-maxFriction, Math.min(maxFriction, motorForce));

        // Update rotor position tracking
        driveRotorPositionRot += (wheelAngularVelocity / (2.0 * Math.PI)) * driveGearRatio * dt;

        // Force vector in robot frame based on steer angle
        double fx = force * Math.cos(steerAngleRad);
        double fy = force * Math.sin(steerAngleRad);
        return new double[]{fx, fy};
    }

    /** Get module position relative to robot center. */
    public Translation2d getPosition() { return position; }

    /** Get the current steering angle. */
    public double getSteerAngle() { return steerAngleRad; }

    /** Get wheel linear velocity (m/s). */
    public double getWheelLinearVelocity() {
        return wheelAngularVelocity * wheelRadius;
    }

    /** Get drive rotor position in rotations (for TalonFXSimState.setRawRotorPosition). */
    public double getDriveRotorPositionRot() {
        return driveInverted ? -driveRotorPositionRot : driveRotorPositionRot;
    }

    /** Get drive rotor velocity in rotations/sec (for TalonFXSimState.setRotorVelocity). */
    public double getDriveRotorVelocityRPS() {
        double rps = (wheelAngularVelocity / (2.0 * Math.PI)) * driveGearRatio;
        return driveInverted ? -rps : rps;
    }

    /** Set wheel angular velocity externally (e.g., back-computed from chassis physics). */
    public void setWheelAngularVelocity(double omegaRadPerSec) {
        this.wheelAngularVelocity = omegaRadPerSec;
    }

    /** Reset accumulated position. */
    public void resetPosition() {
        driveRotorPositionRot = 0;
    }
}
