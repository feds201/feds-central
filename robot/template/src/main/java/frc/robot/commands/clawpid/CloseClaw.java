package frc.robot.commands.clawpid;

import edu.wpi.first.wpilibj.Timer;
import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.constants.ClawConstants;
import frc.robot.subsystems.ClawSubsystemWithPID;

public class CloseClaw extends CommandBase {
    private final ClawSubsystemWithPID m_clawPID;
    private final Timer m_timer;

    public CloseClaw(ClawSubsystemWithPID claw) {
        m_clawPID = claw;
        m_timer = new Timer();

        addRequirements(m_clawPID);
    }

    @Override
    public void initialize() {
        m_timer.reset();
        m_timer.start();

    }

    @Override
    public void execute() {
        m_clawPID.closeClaw();
    }

    @Override
    public boolean isFinished() {
        return m_timer.hasElapsed(ClawConstants.kCloseSeconds);
    }

    @Override
    public void end(boolean interrupted) {
        m_clawPID.stopClaw();
    }

}
