package frc.robot.commands.telescope;

import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.Constants.TelescopeConstants;
import frc.robot.subsystems.TelescopeSubsystem;

public class ExtendTelescope extends CommandBase{

    private final TelescopeSubsystem s_telescope;
    private double m_target;

    public ExtendTelescope(TelescopeSubsystem s_telescope, double target){
        this.s_telescope = s_telescope;
        this.m_target = target;

        addRequirements(this.s_telescope);
    }
    
    @Override
    public void initialize(){
    }

    @Override
    public void execute(){
        s_telescope.setTelescopePosition(this.m_target);
    }

    @Override
    public boolean isFinished(){
        return Math.abs(s_telescope.getTelescopePosition() - this.m_target) < TelescopeConstants.kTelescopeThreshold;
    }

    @Override
    public void end(boolean interrupted){
        s_telescope.stopTelescopeMotion();
    }
}
