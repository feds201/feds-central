package frc.robot.commands.orientator;

import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.subsystems.OrientatorSubsystem;

public class StopOrientator extends CommandBase {
    private final OrientatorSubsystem s_orientator; 
    public StopOrientator(OrientatorSubsystem orientator) {
        this.s_orientator = orientator;
        addRequirements(s_orientator);
    }
    
    @Override
    public void initialize() {
        s_orientator.stopOrientator();
    }

    @Override
    public boolean isFinished() {
        return true;
    }

    @Override
    public void end(boolean interrupted) {
        s_orientator.stopOrientator();
    }
}
