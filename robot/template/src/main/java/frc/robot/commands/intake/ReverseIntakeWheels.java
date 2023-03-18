package frc.robot.commands.intake;

import edu.wpi.first.wpilibj.Timer;
import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.constants.IntakeConstants;
import frc.robot.subsystems.IntakeSubsystem;

public class ReverseIntakeWheels extends CommandBase{
    private final IntakeSubsystem m_intake;
    private final Timer timer;

    public ReverseIntakeWheels(IntakeSubsystem m_intake){
        this.m_intake = m_intake;
        timer = new Timer();

        addRequirements(this.m_intake);
    }

    @Override
    public void initialize(){
        timer.reset();
        timer.start();
    }


    @Override
    public void execute(){
        m_intake.runIntakeWheelsOut();
    }

    @Override
    public boolean isFinished(){
        return timer.hasElapsed(IntakeConstants.kIntakeWheelEjectTime);
    }

    @Override
    public void end(boolean interrupted){
        m_intake.stopIntakeWheels();
    }
}
