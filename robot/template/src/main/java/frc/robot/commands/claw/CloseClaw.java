package frc.robot.commands.claw;

import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.subsystems.ClawSubsystem;
import frc.robot.subsystems.ClawSubsystemWithPID;

public class CloseClaw extends CommandBase {
    private final ClawSubsystemWithPID m_clawPID;


    public CloseClaw(ClawSubsystemWithPID claw) {
        m_clawPID = claw;

        addRequirements(m_clawPID);
    }

    @Override
    public void initialize() {
        m_clawPID.stopClaw();
    }

    @Override
    public boolean isFinished() {
        return true;
    }

}
