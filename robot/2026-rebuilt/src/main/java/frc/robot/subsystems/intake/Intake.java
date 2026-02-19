package frc.robot.subsystems.intake;

import edu.wpi.first.networktables.NetworkTableInstance;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.SubsystemBase;

/**
 * Minimal intake subsystem stub for simulation validation.
 * Students: implement real motor control, beam breaks, etc.
 *
 * For now this just tracks whether rollers are spinning.
 */
public class Intake extends SubsystemBase {
    private boolean rollersActive = false;

    public Intake() {}

    @Override
    public void periodic() {
        var nt = NetworkTableInstance.getDefault();
        nt.getEntry("Intake/RollersActive").setBoolean(rollersActive);
    }

    /** Start spinning the intake rollers (begins consuming nearby game pieces in sim). */
    public void startRollers() { rollersActive = true; }
    /** Stop the intake rollers. */
    public void stopRollers() { rollersActive = false; }

    /** Check if the intake rollers are currently active. Used by sim to gate intake zone checks. */
    public boolean isRollersActive() { return rollersActive; }

    /** Command to run intake while held. */
    public Command intakeCommand() {
        return startEnd(this::startRollers, this::stopRollers);
    }
}
