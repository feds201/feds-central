package frc.robot.commands.auton;

import edu.wpi.first.wpilibj2.command.SequentialCommandGroup;
import frc.robot.commands.drive.GetOnBridge;
import frc.robot.subsystems.ArmSubsystem;
import frc.robot.subsystems.ClawSubsystemWithPID;
import frc.robot.subsystems.SwerveSubsystem;
import frc.robot.subsystems.TelescopeSubsystem;

public class placeConeAndCharge  extends SequentialCommandGroup {
    public placeConeAndCharge(SwerveSubsystem s_Swerve, ClawSubsystemWithPID s_claw, TelescopeSubsystem s_telescope, ArmSubsystem s_arm) {
        addRequirements(s_Swerve, s_arm, s_claw, s_telescope); 
        addCommands(
            new placeConeAuton(s_Swerve, s_claw, s_telescope, s_arm),
            new GetOnBridge(s_Swerve)
        );
    }
    
}
