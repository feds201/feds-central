package frc.robot.subsystems;

import edu.wpi.first.wpilibj2.command.SubsystemBase;
import com.ctre.phoenix.motorcontrol.ControlMode;
import com.ctre.phoenix.motorcontrol.can.*;

public class IntakeSubsystem extends SubsystemBase{

    private final TalonFX intakeDeployMotor;
    private final TalonFX intakeWheelMotor;
   // private final int controllerInputChannel;

    public IntakeSubsystem(int intakeMotor, int intakeWheel){
        intakeDeployMotor = new TalonFX(intakeMotor);
        intakeWheelMotor = new TalonFX(intakeWheel);
        //controllerInputChannel = controllerChannel;

    }

    public double returnPosition(){
        return intakeDeployMotor.getSelectedSensorPosition();
    }
    
    public void deploy(double intakeSpeed, double wheelSpeed){
        intakeDeployMotor.set(ControlMode.PercentOutput, intakeSpeed);
        intakeWheelMotor.set(ControlMode.PercentOutput, wheelSpeed);
        
    }

    public void stationary(double wheelSpeed){
        intakeDeployMotor.set(ControlMode.PercentOutput,0);
        intakeWheelMotor.set(ControlMode.PercentOutput,wheelSpeed);
    }

    public void stop(){
        intakeDeployMotor.set(ControlMode.PercentOutput,0);
        intakeWheelMotor.set(ControlMode.PercentOutput,0);
    }
}
