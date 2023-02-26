package frc.robot.commands.arm;

import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.subsystems.ArmSubsystem;

public class JointsSetPosition extends CommandBase {
    private ArmSubsystem m_ArmSubsystem;
    private int m_armPosition;


    public JointsSetPosition(int m_armPosition, ArmSubsystem armSubsystem){
        this.m_ArmSubsystem = armSubsystem;
        this.m_armPosition = m_armPosition;

        addRequirements(m_ArmSubsystem);
    }

    @Override
    public void execute() {
        m_ArmSubsystem.setPosition(m_armPosition).schedule();
    }
}
