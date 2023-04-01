package frc.robot.commands.drive;

import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.RobotContainer;
import frc.robot.constants.AutoConstants;
import frc.robot.constants.SwerveConstants;
import frc.robot.subsystems.SwerveSubsystem;

public class BalanceWhileOn extends CommandBase {
    private PIDController rollController;

    private final SwerveSubsystem s_swerve;

    public BalanceWhileOn(SwerveSubsystem s_swerve) {
        this.s_swerve = s_swerve;
        addRequirements(s_swerve);

        rollController = new PIDController(AutoConstants.Balance.kRollP, AutoConstants.Balance.kRollI,
                AutoConstants.Balance.kRollD);
    }

    @Override
    public void execute() {
        SmartDashboard.putNumber("THE ACTUAL ROLL", RobotContainer.s_pigeon2.getRoll());
        SmartDashboard.putNumber("THE OFFSETTED ROLL", RobotContainer.s_pigeon2.getRoll() + SwerveConstants.kRollOffset);

        double rollCommand = rollController.calculate(RobotContainer.s_pigeon2.getRoll() + SwerveConstants.kRollOffset, 0);

        SmartDashboard.putNumber("ROLL COMMAND", rollCommand);

        if (Math.abs(RobotContainer.s_pigeon2.getRoll()) < AutoConstants.Balance.kRollDeadband) {
            rollCommand = 0.0;
        }

        Translation2d commandedToRobot = new Translation2d(
                rollCommand,
                Rotation2d.fromDegrees(0)).times(0.2);

        SmartDashboard.putNumber("COMMANDED X", commandedToRobot.getX());
        SmartDashboard.putNumber("COMMANDED Y", commandedToRobot.getY());
        
        s_swerve.drive(
                commandedToRobot,
                0.0,
                false,
                true);
    }
}
