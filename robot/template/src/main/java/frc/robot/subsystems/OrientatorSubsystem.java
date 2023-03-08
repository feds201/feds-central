package frc.robot.subsystems;

import com.ctre.phoenix.motorcontrol.ControlMode;
import com.ctre.phoenix.motorcontrol.can.TalonFX;

import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.Constants.OrientatorConstants;
import frc.robot.utils.ConeDetection;

public class OrientatorSubsystem extends SubsystemBase {
    private final TalonFX orientatorMotor;
    
    public OrientatorSubsystem(){
        orientatorMotor = new TalonFX(OrientatorConstants.kOrientatorMotorID);
        orientatorMotor.configVoltageCompSaturation(12);
        orientatorMotor.enableVoltageCompensation(true);
    }

    public void rotateOrientatorIn(){
        orientatorMotor.set(ControlMode.PercentOutput, OrientatorConstants.kOrientatorSpeed);
    }

    public void rotateOrientatorOut(){
        orientatorMotor.set(ControlMode.PercentOutput, -OrientatorConstants.kOrientatorSpeed);
    }

    public void stopOrientator(){
        orientatorMotor.set(ControlMode.PercentOutput, 0);
    }

}
