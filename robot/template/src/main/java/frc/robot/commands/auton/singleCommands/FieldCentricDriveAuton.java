package frc.robot.commands.auton.singleCommands;

import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.subsystems.DriveSubsystem;

public class FieldCentricDriveAuton extends CommandBase {
    private final DriveSubsystem m_drive;
    private final double m_fieldAngle;
    private final double m_linearSpeed;
    private final double m_rotationalSpeed;

    public FieldCentricDriveAuton(DriveSubsystem drive, double fieldAngle, double linearSpeed, double rotationalSpeed) {
        m_drive = drive;
        m_fieldAngle = fieldAngle;
        m_linearSpeed = linearSpeed;
        m_rotationalSpeed = rotationalSpeed;

        addRequirements(m_drive);
    }

    // Michael's code runs at 1 time per 0.02 secs while this runs (by default) at 1
    // time per 0.05 secs.
    // if this is not accurate enough for us, then we can try to change it
    // somewhere.
    @Override
    public void execute() {
        double changedAngle = m_fieldAngle - m_drive.getPoseAngle();
        m_drive.setTargetVelocity(changedAngle, m_linearSpeed, m_rotationalSpeed);
    }

    @Override
    public void end(boolean interrupted) {
        this.m_drive.setTargetVelocity(0, 0, 0);
    }
}
