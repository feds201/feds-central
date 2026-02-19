package frc.robot.subsystems.shooter;

import edu.wpi.first.networktables.NetworkTableInstance;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.SubsystemBase;

/**
 * Minimal shooter subsystem stub for simulation validation.
 * Students: implement real motor control, PID, sensors, etc.
 *
 * For now this just tracks hood angle and shooting state so the
 * simulation can launch balls.
 */
public class Shooter extends SubsystemBase {
    /** Default hood angle (placeholder — 45° is a reasonable starting point for testing). */
    private double hoodAngleRad = Math.toRadians(45);
    private boolean isShooting = false;

    /** Flywheel surface speed (placeholder, m/s). Maps directly to launch velocity in sim.
     *  On the real robot this will come from flywheel RPM × wheel radius. */
    private static final double FLYWHEEL_SPEED_MPS = 20.0;

    /** Hood adjustment rate when button is held (placeholder, rad/s = 30°/s). */
    private static final double HOOD_ADJUST_RATE = Math.toRadians(30);

    /** Minimum hood angle — prevents aiming below ~10° (placeholder, radians). */
    private static final double HOOD_MIN = Math.toRadians(10);
    /** Maximum hood angle — prevents aiming above ~80° (placeholder, radians). */
    private static final double HOOD_MAX = Math.toRadians(80);

    public Shooter() {}

    @Override
    public void periodic() {
        // Publish state for dashboard / sim
        var nt = NetworkTableInstance.getDefault();
        nt.getEntry("Shooter/HoodAngleDeg").setDouble(Math.toDegrees(hoodAngleRad));
        nt.getEntry("Shooter/IsShooting").setBoolean(isShooting);
    }

    /** Adjust hood angle up (increase). */
    public void adjustHoodUp(double dt) {
        hoodAngleRad = Math.min(HOOD_MAX, hoodAngleRad + HOOD_ADJUST_RATE * dt);
    }

    /** Adjust hood angle down (decrease). */
    public void adjustHoodDown(double dt) {
        hoodAngleRad = Math.max(HOOD_MIN, hoodAngleRad - HOOD_ADJUST_RATE * dt);
    }

    /** Start shooting (spin flywheel + feed balls). */
    public void startShooting() {
        isShooting = true;
    }

    /** Stop shooting. */
    public void stopShooting() {
        isShooting = false;
    }

    // --- Commands ---

    public Command hoodUpCommand() {
        return run(() -> adjustHoodUp(0.02)).finallyDo(() -> {});
    }

    public Command hoodDownCommand() {
        return run(() -> adjustHoodDown(0.02)).finallyDo(() -> {});
    }

    public Command shootCommand() {
        return startEnd(this::startShooting, this::stopShooting);
    }

    // --- Sim accessors ---

    /** Get the current hood angle in radians (0 = horizontal, π/2 = vertical). */
    public double getHoodAngleRad() { return hoodAngleRad; }
    /** Check if the shooter is actively firing. */
    public boolean isShooting() { return isShooting; }
    /** Get the flywheel launch velocity in m/s. */
    public double getLaunchVelocity() { return FLYWHEEL_SPEED_MPS; }
}
