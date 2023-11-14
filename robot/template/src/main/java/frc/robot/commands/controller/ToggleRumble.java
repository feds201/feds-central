package frc.robot.commands.controller;

import edu.wpi.first.wpilibj.GenericHID.RumbleType;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.SequentialCommandGroup;
import edu.wpi.first.wpilibj2.command.WaitCommand;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;

public class ToggleRumble extends SequentialCommandGroup {
    public ToggleRumble(CommandXboxController controller, double durationSecs) {
        addCommands(
            new InstantCommand(() -> controller.getHID().setRumble(RumbleType.kBothRumble, 1)),
            new WaitCommand(0.5),
            new InstantCommand(() -> controller.getHID().setRumble(RumbleType.kBothRumble, 0))
        );
    } 
}
