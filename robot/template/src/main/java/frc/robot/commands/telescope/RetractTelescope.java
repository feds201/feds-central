package frc.robot.commands.telescope;

import edu.wpi.first.wpilibj.Timer;
import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.Constants.TelescopeConstants;
import frc.robot.subsystems.TelescopeSubsystem;

public class RetractTelescope extends CommandBase{

    private final TelescopeSubsystem s_telescope;

    public RetractTelescope(TelescopeSubsystem s_telescope){
        this.s_telescope = s_telescope;

        addRequirements(this.s_telescope);
    }
    
    @Override
    public void initialize(){
    }

    @Override
    public void execute(){
        s_telescope.setTelescopePosition(0);
    }

    @Override
    public boolean isFinished(){
        return Math.abs(s_telescope.getTelescopePosition() - 0) < TelescopeConstants.kTelescopeThreshold;
    }

    @Override
    public void end(boolean interrupted){
        s_telescope.stopTelescopeMotion();
    }
}
