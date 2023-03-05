package frc.robot.commands.sensor;

import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.subsystems.SwerveSubsystem;

public class MoveToTarget extends CommandBase{

    private final SwerveSubsystem s_swerve;
    private final boolean isTargetLow;

    public MoveToTarget(SwerveSubsystem Swerve_S, boolean isTargetLow){
        this.s_swerve = Swerve_S;
        this.isTargetLow = isTargetLow;


        addRequirements(this.s_swerve);

    }

    @Override
    public void initialize(){
        
    }

    @Override
    public void execute(){
        s_swerve.driveToTarget(isTargetLow);
    }

    @Override
    public boolean isFinished(){
        return s_swerve.finishedMoveToTarget(isTargetLow);
    }

    @Override
    public void end(boolean interrupted){
        
    }

}
