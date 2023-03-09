package frc.robot.subsystems;

import com.ctre.phoenix.motorcontrol.ControlMode;
import com.ctre.phoenix.motorcontrol.StatusFrameEnhanced;
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


        orientatorMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_1_General, 10);
		orientatorMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_2_Feedback0, 10);
		orientatorMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_3_Quadrature, 255);
		orientatorMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_4_AinTempVbat, 255);
		orientatorMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_8_PulseWidth, 255);
		orientatorMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_10_Targets, 255);
		orientatorMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_12_Feedback1, 255);
		orientatorMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_13_Base_PIDF0, 255);
		orientatorMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_14_Turn_PIDF1, 255);
		orientatorMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_Brushless_Current, 255);
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
