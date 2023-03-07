package frc.robot.commands.intake;

import edu.wpi.first.wpilibj2.command.ParallelCommandGroup;
import edu.wpi.first.wpilibj2.command.SequentialCommandGroup;
import frc.robot.commands.orientator.RunOrientator;
import frc.robot.subsystems.IntakeSubsystem;
import frc.robot.subsystems.OrientatorSubsystem;

public class DeployIntakeGroup extends SequentialCommandGroup {
    private final IntakeSubsystem s_intake;
    private final OrientatorSubsystem s_orientator;

    public DeployIntakeGroup(IntakeSubsystem intake, OrientatorSubsystem orientator) {
        this.s_orientator = orientator;
        this.s_intake = intake;
        addCommands(
                new DeployIntake(s_intake),
                new ParallelCommandGroup(
                        new RunIntakeWheels(s_intake),
                        new RunOrientator(s_orientator)));
    }
}