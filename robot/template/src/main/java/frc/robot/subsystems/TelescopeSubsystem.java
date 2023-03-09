package frc.robot.subsystems;

import com.ctre.phoenix.motorcontrol.ControlMode;
import com.ctre.phoenix.motorcontrol.NeutralMode;
import com.ctre.phoenix.motorcontrol.StatusFrameEnhanced;
import com.ctre.phoenix.motorcontrol.TalonFXControlMode;
import com.ctre.phoenix.motorcontrol.TalonFXInvertType;
import com.ctre.phoenix.motorcontrol.can.TalonFX;

import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.Constants.TelescopeConstants;

public class TelescopeSubsystem extends SubsystemBase{

    private final TalonFX armTelescopeMotor;
    
    public TelescopeSubsystem(){
        armTelescopeMotor = new TalonFX(TelescopeConstants.kTelescopeMotor);
        armTelescopeMotor.configFactoryDefault();
        armTelescopeMotor.setSelectedSensorPosition(0);

        armTelescopeMotor.configForwardSoftLimitThreshold(1_000_000);
        armTelescopeMotor.configReverseSoftLimitThreshold(-1);
        armTelescopeMotor.configForwardSoftLimitEnable(true, 0);
        armTelescopeMotor.configReverseSoftLimitEnable(true, 0);


        armTelescopeMotor.config_kP(0, TelescopeConstants.kP, 0); // TUNE THIS
        armTelescopeMotor.config_kI(0, TelescopeConstants.kI, 0);
        armTelescopeMotor.config_kD(0, TelescopeConstants.kD, 0);


        armTelescopeMotor.configMotionAcceleration(TelescopeConstants.cruiseVelocityAccel, 0);
        armTelescopeMotor.configMotionCruiseVelocity(TelescopeConstants.cruiseVelocityAccel, 0);

        armTelescopeMotor.selectProfileSlot(0, 0);

        armTelescopeMotor.setInverted(TalonFXInvertType.CounterClockwise);
        armTelescopeMotor.setNeutralMode(NeutralMode.Brake);
        armTelescopeMotor.configVoltageCompSaturation(12);
        armTelescopeMotor.enableVoltageCompensation(true);



        armTelescopeMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_1_General, 10);
		armTelescopeMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_2_Feedback0, 10);
		armTelescopeMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_3_Quadrature, 255);
		armTelescopeMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_4_AinTempVbat, 255);
		armTelescopeMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_8_PulseWidth, 255);
		armTelescopeMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_10_Targets, 255);
		armTelescopeMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_12_Feedback1, 255);
		armTelescopeMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_13_Base_PIDF0, 255);
		armTelescopeMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_14_Turn_PIDF1, 255);
		armTelescopeMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_Brushless_Current, 255);
    }

    public double getTelescopePosition(){
        return armTelescopeMotor.getSelectedSensorPosition();
    }

    // public void extendTelescope(){
    //     armTelescopeMotor.set(ControlMode.PercentOutput,TelescopeConstants.kTelescopeSpeed);
    // }

    // public void stop(){
    //     armTelescopeMotor.set(ControlMode.PercentOutput,0);
    //     armTelescopeMotor.setNeutralMode(NeutralMode.Brake);
    // }

    // public void retractTelescope(){
    //     armTelescopeMotor.set(ControlMode.PercentOutput, -TelescopeConstants.kTelescopeSpeed);
    // }

    public void setTelescopePosition(double position) {
        armTelescopeMotor.set(TalonFXControlMode.MotionMagic, position);
        
    }
    
    public void stopTelescopeMotion() {
        armTelescopeMotor.set(TalonFXControlMode.PercentOutput, 0);
    }

    public void manuallyMove(double scalar) {
        armTelescopeMotor.set(ControlMode.PercentOutput, TelescopeConstants.kManualSpeed * scalar);
    }
    
    public void periodic(){
        
    }
}