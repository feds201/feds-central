package frc.robot.commands.drive;

import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.wpilibj2.command.CommandBase;
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
        double rollCommand = rollController.calculate(s_swerve.getGyroRoll(), 0);
        double pitchCommand = rollController.calculate(s_swerve.getGyroPitch(), 0);
        
        if (Math.abs(s_swerve.getGyroRoll()) < AutoConstants.Balance.kRollDeadband) {
            rollCommand = 0.0;
        }

        if (Math.abs(s_swerve.getGyroPitch()) < AutoConstants.Balance.kPitchDeadband) {
            pitchCommand = 0.0;
        }

        s_swerve.drive(
            new Translation2d(
                -rollCommand,
                -pitchCommand
            ).times(1.0),
            0.0,
            false, 
            true
        );
    }
    
}
