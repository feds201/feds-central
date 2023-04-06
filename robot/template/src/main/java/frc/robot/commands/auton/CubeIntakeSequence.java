package frc.robot.commands.auton;

import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.kinematics.SwerveModuleState;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.ParallelCommandGroup;
import edu.wpi.first.wpilibj2.command.ParallelDeadlineGroup;
import edu.wpi.first.wpilibj2.command.SequentialCommandGroup;
import edu.wpi.first.wpilibj2.command.WaitCommand;
import frc.robot.commands.intake.RotateIntakeToPosition;
import frc.robot.commands.intake.RunIntakeWheelsInfinite;
import frc.robot.constants.IntakeConstants;
import frc.robot.subsystems.IntakeSubsystem;
import frc.robot.subsystems.WheelSubsystem;


public class CubeIntakeSequence extends SequentialCommandGroup{
    
    public CubeIntakeSequence(IntakeSubsystem s_intake, WheelSubsystem s_wheels){

        addRequirements(s_intake);
        addRequirements(s_wheels);

        addCommands(
                new ParallelDeadlineGroup(
                        new WaitCommand(2.5), 
                        new RotateIntakeToPosition(s_intake, IntakeConstants.kIntakeForwardSetpoint),
                        new RunIntakeWheelsInfinite(s_wheels)),
                new ParallelDeadlineGroup(
                        new WaitCommand(2),
                        new RotateIntakeToPosition(s_intake, IntakeConstants.kIntakeRetractSetpoint))
        );
    }
}
