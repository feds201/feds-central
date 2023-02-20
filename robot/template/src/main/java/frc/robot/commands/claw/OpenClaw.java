package frc.robot.commands.claw;

import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.subsystems.ClawSubsystem;

public class OpenClaw extends CommandBase {
    private final ClawSubsystem m_claw;


    public OpenClaw(ClawSubsystem claw) {
        m_claw = claw;

        addRequirements(m_claw);
    }


    @Override
    public void execute() {
        // TODO Auto-generated method stub
        m_claw.openClaw();
    }

}
