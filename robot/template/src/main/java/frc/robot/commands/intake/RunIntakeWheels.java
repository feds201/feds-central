package frc.robot.commands.intake;

import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.subsystems.IntakeSubsystem;
import edu.wpi.first.wpilibj.Timer;

public class RunIntakeWheels extends CommandBase {
    private final IntakeSubsystem m_intake;
    private final Timer timer;

    public RunIntakeWheels(IntakeSubsystem intake) {
        this.m_intake = intake; 
        timer = new Timer();

        addRequirements(m_intake);
    } 

    @Override 
    public void initialize(){
        timer.reset();
        timer.start();
    }
    
    @Override
    public void execute() {
        m_intake.runIntakeWheelsIn();
    }

    @Override
    public boolean isFinished(){
        return timer.hasElapsed(2);
    }

    @Override
    public void end(boolean interrupted){
        m_intake.stopIntakeWheels();
    }
}
