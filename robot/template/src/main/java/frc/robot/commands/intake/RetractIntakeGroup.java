package frc.robot.commands.intake;

import edu.wpi.first.wpilibj2.command.ParallelCommandGroup;
import edu.wpi.first.wpilibj2.command.SequentialCommandGroup;
import frc.robot.commands.orientator.StopOrientator;
import frc.robot.subsystems.IntakeSubsystem;
import frc.robot.subsystems.OrientatorSubsystem;

public class RetractIntakeGroup extends SequentialCommandGroup {
    private final IntakeSubsystem s_intake;
    private final OrientatorSubsystem s_orientator;

    public RetractIntakeGroup(IntakeSubsystem intake, OrientatorSubsystem orientator) {
        this.s_orientator = orientator;
        this.s_intake = intake;
        addCommands(
                new StopIntakeWheels(s_intake),
                new ParallelCommandGroup(
                        new StopOrientator(s_orientator),
                        new RetractIntake(s_intake)));
    }
}