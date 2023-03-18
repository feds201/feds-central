package frc.robot.commands.claw;

import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.subsystems.ClawSubsystem;

public class StopClaw extends CommandBase {
    private final ClawSubsystem s_claw;
    public StopClaw(ClawSubsystem s_claw) {
        this.s_claw = s_claw;
        addRequirements(s_claw);
    } 

    @Override
    public void initialize() {
        s_claw.stopClaw();
    }

    @Override
    public boolean isFinished() {
        return true;
    }

    @Override
    public void end(boolean interrupted) {
        s_claw.stopClaw();
    }

}
