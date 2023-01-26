package frc.robot;

import edu.wpi.first.wpilibj.XboxController;
import edu.wpi.first.wpilibj2.command.Command;
import frc.robot.commands.FieldRelativeDriveControlCommand;
import frc.robot.commands.SwerveDriveControlCommand;
import frc.robot.subsystems.DriveSubsystem;

public class RobotContainer {
    private final DriveSubsystem m_robotDrive = new DriveSubsystem();
   
    XboxController m_driveController = new XboxController(Constants.kDriveControllerPort);
    public RobotContainer() {
        m_robotDrive.setDefaultCommand(
            // new SwerveDriveControlCommand(m_robotDrive, () -> m_driveController.getLeftY(), () -> m_driveController.getLeftX(), () -> m_driveController.getRightX())
            new FieldRelativeDriveControlCommand(m_robotDrive, () -> m_driveController.getLeftY(), () -> m_driveController.getLeftX(), () -> m_driveController.getRightX(), () -> m_robotDrive.getPoseAngle())
        );
    }

    public Command getAutonomousCommand() {
        return null; // TODO: make this!
    }
}
