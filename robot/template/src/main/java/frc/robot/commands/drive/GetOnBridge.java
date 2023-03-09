package frc.robot.commands.drive;

import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.kinematics.SwerveModuleState;
import edu.wpi.first.wpilibj2.command.ParallelDeadlineGroup;
import edu.wpi.first.wpilibj2.command.RunCommand;
import edu.wpi.first.wpilibj2.command.SequentialCommandGroup;
import edu.wpi.first.wpilibj2.command.WaitCommand;
import frc.robot.Constants.SwerveConstants;
import frc.robot.subsystems.SwerveSubsystem;

public class GetOnBridge extends SequentialCommandGroup {
  public GetOnBridge(SwerveSubsystem s_swerve) {
    addCommands(
        new ParallelDeadlineGroup(new WaitCommand(SwerveConstants.kChargingStationTime),
            new RunCommand(
                () -> {
                  // Robot.motionMode = MotionMode.NULL;
                  s_swerve.setModuleStates(
                      new SwerveModuleState[] {
                          new SwerveModuleState(-1.6, Rotation2d.fromDegrees(0)),
                          new SwerveModuleState(-1.6, Rotation2d.fromDegrees(0)),
                          new SwerveModuleState(-1.6, Rotation2d.fromDegrees(0)),
                          new SwerveModuleState(-1.6, Rotation2d.fromDegrees(0))
                      });
                })),
        new LockWheels(s_swerve),
        new WaitCommand(100));
  }
}
