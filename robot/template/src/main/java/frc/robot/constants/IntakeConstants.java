package frc.robot.constants;

import com.ctre.phoenix.motorcontrol.NeutralMode;
import com.ctre.phoenix.motorcontrol.StatusFrameEnhanced;
import com.ctre.phoenix.motorcontrol.can.TalonFX;

import frc.lib.math.Conversions;

public final class IntakeConstants {
    // Pheonix IDs
    public static final int kIntakeBlueLeftDeployMotor = 51;
    public static final int kIntakeBlueLeftWheelMotor = 61;
    public static final int kIntakeTriggerID = 2;

    // Speeds
    public static final double kIntakeDeploySpeed = 0.30;
    public static final double kIntakeRetractSpeed = -0.2;
    public static final double kIntakeWheelSpeed = -0.30;
    public static final double kIntakeWheelEjectTime = 0.5;

    public static final double kPeakIntakeVelocity = 0.55;
    public static final double kPercentOfPeakIntakeVelocity = 0.45;
    public static final double intakeVelocityAccelUp = kPeakIntakeVelocity*kPercentOfPeakIntakeVelocity;

    public static final double kDeployTime = 0.5;
    public static final double kRetractTime = 0.5;

    // Encoder Counts
    public static final double kIntakeEncoderOffsetDeployed = 2640;
    public static final double kIntakeEncoderOffsetRetracted = 0;
    public static final double kIntakeGearRatio = 25;
    public static final double kIntakePositionDeployed = 0;
    public static final double kIntakePositionStart = 0;
    public static final double kIntakePositionMid = 0;


    // PID (Feedback)
    public static final double kPUp   = 0.1;
    public static final double kIUp   = 0;
    public static final double kDUp   = 0;

    public static final double kPDown = 0.1;
    public static final double kIDown = 0;
    public static final double kDDown = 0;

    //Soft Limits
    public static final double kIntakeForwardSoftLimit = Conversions.degreesToFalcon(90, kIntakeGearRatio);
    public static final double kIntakeRetractSoftLimit = Conversions.degreesToFalcon(-10, kIntakeGearRatio);

    public static void configIntakeMotor(TalonFX motor){
        
        motor.configFactoryDefault();
       
        /* CONFIG MOTION MAGIC */
        motor.config_kP(0, kPUp, 0);
        motor.config_kI(0, kIUp, 0);
        motor.config_kD(0, kDUp, 0);
        motor.configMotionAcceleration(intakeVelocityAccelUp, 0);
        motor.configMotionCruiseVelocity(intakeVelocityAccelUp, 0);
        motor.selectProfileSlot(0, 0);
        
        /* THRESHOLDS */
        motor.configForwardSoftLimitThreshold(kIntakeForwardSoftLimit);
        motor.configReverseSoftLimitThreshold(kIntakeRetractSoftLimit);
        motor.configForwardSoftLimitEnable(true);
        motor.configReverseSoftLimitEnable(true);

        /* MOTOR TYPES */
        motor.setNeutralMode(NeutralMode.Brake);
        
        //VOLTAGE COMPENSATION
        motor.configVoltageCompSaturation(12);
        motor.enableVoltageCompensation(true);
        
        //SET STATUS FRAME PERIODS
        motor.setStatusFramePeriod(StatusFrameEnhanced.Status_2_Feedback0, 10);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_3_Quadrature, 255);
        motor.setStatusFramePeriod(StatusFrameEnhanced.Status_1_General, 255);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_4_AinTempVbat, 255);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_8_PulseWidth, 255);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_10_Targets, 255);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_12_Feedback1, 255);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_13_Base_PIDF0, 255);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_14_Turn_PIDF1, 255);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_Brushless_Current, 255);
    }
    
    public static void configWheelMotor(TalonFX motor){
        motor.configFactoryDefault();
       
        /* MOTOR TYPES */
        motor.setNeutralMode(NeutralMode.Brake);
        
        //VOLTAGE COMPENSATION
        motor.configVoltageCompSaturation(12);
        motor.enableVoltageCompensation(true);
        
        //SET STATUS FRAME PERIODS
        motor.setStatusFramePeriod(StatusFrameEnhanced.Status_2_Feedback0, 10);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_3_Quadrature, 255);
        motor.setStatusFramePeriod(StatusFrameEnhanced.Status_1_General, 255);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_4_AinTempVbat, 255);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_8_PulseWidth, 255);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_10_Targets, 255);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_12_Feedback1, 255);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_13_Base_PIDF0, 255);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_14_Turn_PIDF1, 255);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_Brushless_Current, 255);
    }
}