package frc.robot.commands.auton;

import edu.wpi.first.wpilibj2.command.ParallelCommandGroup;
import edu.wpi.first.wpilibj2.command.SequentialCommandGroup;
import edu.wpi.first.wpilibj2.command.WaitCommand;
import frc.robot.constants.ArmConstants;
import frc.robot.commands.telescope.RetractTelescope;
import frc.robot.subsystems.ArmSubsystem;
import frc.robot.subsystems.ClawSubsystemWithPID;
import frc.robot.subsystems.TelescopeSubsystem;

public class retractArmAuton extends SequentialCommandGroup{
    public retractArmAuton(ClawSubsystemWithPID s_claw, TelescopeSubsystem s_telescope, ArmSubsystem s_arm){

        addCommands(new ParallelCommandGroup(new ParallelCommandGroup(
            new RetractTelescope(s_telescope),
            new SequentialCommandGroup(new WaitCommand(2.5),
                    s_arm.setPosition(ArmConstants.kArmHome)))));
    }
}
