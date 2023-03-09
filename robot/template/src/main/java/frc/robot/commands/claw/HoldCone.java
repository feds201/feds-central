package frc.robot.commands.claw;

import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.subsystems.ClawSubsystem;
import frc.robot.subsystems.ClawSubsystemWithPID;

public class HoldCone extends CommandBase {
    private final ClawSubsystem m_claw;


    public HoldCone(ClawSubsystem claw) {
        m_claw = claw;

        addRequirements(m_claw);
    }


    @Override
    public void execute() {
        // TODO Auto-generated method stub
        m_claw.holdCone();
    }

}
