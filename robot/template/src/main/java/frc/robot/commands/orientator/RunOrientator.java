package frc.robot.commands.orientator;

import frc.robot.subsystems.OrientatorSubsystem;
import edu.wpi.first.wpilibj2.command.CommandBase;

public class RunOrientator extends CommandBase{
    private final OrientatorSubsystem s_orientator;

    public RunOrientator(OrientatorSubsystem s_orientator){
        this.s_orientator = s_orientator;

        addRequirements(this.s_orientator);
    }

    @Override
    public void execute(){
        s_orientator.rotateOrientatorIn();
    }


    @Override
    public void end(boolean interrupted){
        s_orientator.stopOrientator();
    }
}
