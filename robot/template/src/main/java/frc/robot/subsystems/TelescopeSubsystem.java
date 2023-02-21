package frc.robot.subsystems;

import com.ctre.phoenix.motorcontrol.ControlMode;
import com.ctre.phoenix.motorcontrol.NeutralMode;
import com.ctre.phoenix.motorcontrol.can.TalonFX;

import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.Constants.TelescopeConstants;

public class TelescopeSubsystem extends SubsystemBase{

    private final TalonFX armTelescopeMotor;
    
     
    
    public TelescopeSubsystem(){
        armTelescopeMotor = new TalonFX(TelescopeConstants.kTelescopeMotor);        
    }

    public double getTelescopePosition(){
        return armTelescopeMotor.getSelectedSensorPosition();
    }

    public void extendTelescope(){
        armTelescopeMotor.set(ControlMode.PercentOutput,TelescopeConstants.kTelescopeSpeed);
    }

    public void stop(){
        armTelescopeMotor.set(ControlMode.PercentOutput,0);
        armTelescopeMotor.setNeutralMode(NeutralMode.Brake);
    }

    public void retractTelescope(){
        armTelescopeMotor.set(ControlMode.PercentOutput, -TelescopeConstants.kTelescopeSpeed);
    }

    public void periodic(){
        
    }
}
