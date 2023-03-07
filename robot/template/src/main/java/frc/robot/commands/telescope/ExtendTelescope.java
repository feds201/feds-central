package frc.robot.commands.telescope;

import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.Constants.TelescopeConstants;
import frc.robot.subsystems.TelescopeSubsystem;

public class ExtendTelescope extends CommandBase{

    private final TelescopeSubsystem s_telescope;

    public ExtendTelescope(TelescopeSubsystem s_telescope){
        this.s_telescope = s_telescope;

        addRequirements(this.s_telescope);
    }
    
    @Override
    public void initialize(){
    }

    @Override
    public void execute(){
        s_telescope.setTelescopePosition(TelescopeConstants.kTelescopeExtended);
    }

    @Override
    public boolean isFinished(){
        return Math.abs(s_telescope.getTelescopePosition() - TelescopeConstants.kTelescopeExtended) < TelescopeConstants.kTelescopeThreshold;
    }

    @Override
    public void end(boolean interrupted){
        s_telescope.stopTelescopeMotion();
    }
}
