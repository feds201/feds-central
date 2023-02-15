package frc.robot.subsystems;

import com.ctre.phoenix.motorcontrol.ControlMode;
import com.ctre.phoenix.motorcontrol.can.TalonFX;

import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.Constants;
import frc.robot.Constants.ArmConstants;
import frc.robot.Constants.IntakeConstants;

public class ArmSubsystem extends SubsystemBase{
    
    private final TalonFX rotateMotor1;
    private final TalonFX rotateMotor2;
    private final TalonFX armPulley;
    

    public ArmSubsystem(){
        rotateMotor1 = new TalonFX(ArmConstants.kArmMotor1);
        rotateMotor2 = new TalonFX(ArmConstants.kArmMotor2);
        armPulley = new TalonFX(ArmConstants.kArmPulley);
        rotateMotor2.follow(rotateMotor1);
    }

    public void rotateArm(double rotateSpeed){
        rotateMotor1.set(ControlMode.PercentOutput,rotateSpeed);
    } 

    public void extendArm(double extendSpeed){
        armPulley.set(ControlMode.PercentOutput,extendSpeed);
    }

    public void stop(){
        rotateMotor1.set(ControlMode.PercentOutput,0);
        armPulley.set(ControlMode.PercentOutput,0);

    }

    
}
