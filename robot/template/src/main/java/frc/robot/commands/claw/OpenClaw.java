package frc.robot.commands.claw;

import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.subsystems.ClawSubsystemWithPID;

public class OpenClaw extends CommandBase {
    // private final ClawSubsystem m_claw;
    private final ClawSubsystemWithPID m_clawPID;


    // public OpenClaw(ClawSubsystem claw) {
    //     m_claw = claw;

    //     addRequirements(m_claw);
    // }

    public OpenClaw(ClawSubsystemWithPID claw) {
        m_clawPID = claw;

        addRequirements(m_clawPID);
    }

    @Override
    public void execute() {
        // TODO Auto-generated method stub
        m_clawPID.openClaw();
    }

}
