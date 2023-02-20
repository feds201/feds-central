package frc.robot.commands.claw;

import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.subsystems.ClawSubsystem;

public class CloseClaw extends CommandBase {
    private final ClawSubsystem m_claw;


    public CloseClaw(ClawSubsystem claw) {
        m_claw = claw;

        addRequirements(m_claw);
    }

    @Override
    public void initialize() {
        m_claw.stopClaw();
    }

    @Override
    public boolean isFinished() {
        return true;
    }

}
