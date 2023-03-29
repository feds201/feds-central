package frc.robot.commands.drive;

import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.RobotContainer;
import frc.robot.constants.AutoConstants;
import frc.robot.subsystems.SwerveSubsystem;

public class BalanceWhileOn extends CommandBase {
    private PIDController pitchController, rollController;

    private final SwerveSubsystem s_swerve; 

    public BalanceWhileOn(SwerveSubsystem s_swerve) {
        this.s_swerve = s_swerve;
        addRequirements(s_swerve);

        pitchController = new PIDController(AutoConstants.Balance.kPitchP, AutoConstants.Balance.kPitchI, AutoConstants.Balance.kPitchD);
        rollController = new PIDController(AutoConstants.Balance.kRollP, AutoConstants.Balance.kRollI, AutoConstants.Balance.kRollD);
    }

    @Override
    public void execute() {
        double pitchCommand = rollController.calculate(RobotContainer.s_pigeon2.getRoll(), 0);
        double rollCommand = pitchController.calculate(RobotContainer.s_pigeon2.getPitch(), 0);
        
        if (Math.abs(RobotContainer.s_pigeon2.getRoll()) < AutoConstants.Balance.kRollDeadband) {
            rollCommand = 0.0;
        }

        if (Math.abs(RobotContainer.s_pigeon2.getPitch()) < AutoConstants.Balance.kPitchDeadband) {
            pitchCommand = 0.0;
        }

        s_swerve.drive(
            new Translation2d(
                rollCommand,
                pitchCommand
            ).times(1),
            0.0,
            false, 
            true
        );
    }
    
}
