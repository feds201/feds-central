package frc.robot.commands.intake;

import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.subsystems.IntakeSubsystem;

public class RotateIntakeToPosition extends CommandBase{

    private final IntakeSubsystem m_intake;
    private final double position;

    public RotateIntakeToPosition(IntakeSubsystem m_intake, double position){
        this.m_intake = m_intake;
        this.position = position;

        addRequirements(this.m_intake);
    }

    @Override
    public void initialize(){
        m_intake.setIntakePosition(position);
    }
    
}
