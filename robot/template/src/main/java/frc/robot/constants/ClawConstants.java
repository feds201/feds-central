package frc.robot.constants;

import com.ctre.phoenix.motorcontrol.StatusFrameEnhanced;
import com.ctre.phoenix.motorcontrol.TalonFXFeedbackDevice;
import com.ctre.phoenix.motorcontrol.can.TalonFX;

import frc.lib.math.Conversions;

public class ClawConstants {
    public static final int kClawMotor = 56;

    // set points
    public static final double kOpenClawPosition = -Conversions.degreesToFalcon(40, 25);
    public static final double kKickClawPosition = -Conversions.degreesToFalcon(5, 25);

    public static final double kHoldBallSpeed = -0.1; // tune these
    public static final double kHoldConeSpeed = -0.1;
    public static final double kExtendSpeed = 0.35;
    public static final double kClosePower  = 0.1;

    public static final double kCloseSeconds = 0.2;

    public static final int kPIDLoopIdx = 0;
    public static final boolean kSensorPhase = true;
    public static final double kP = 0.0;
    public static final double kI = 0;
    public static final double kD = 0.0;
    public static final double kF = 0.4;
    public static final int kIzone = 0;
    public static final double kPeakOutput = 0.40;
    public static final int kTimeoutMs = 30;


    public static void configMotor(TalonFX motor) {
        motor.configFactoryDefault();
        motor.configSelectedFeedbackSensor(TalonFXFeedbackDevice.IntegratedSensor, 0, 30);

        motor.setSelectedSensorPosition(0);

        motor.setStatusFramePeriod(StatusFrameEnhanced.Status_1_General, 255);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_2_Feedback0, 10);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_3_Quadrature, 255);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_4_AinTempVbat, 255);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_8_PulseWidth, 255);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_10_Targets, 255);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_12_Feedback1, 255);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_13_Base_PIDF0, 255);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_14_Turn_PIDF1, 255);
		motor.setStatusFramePeriod(StatusFrameEnhanced.Status_Brushless_Current, 255);

        motor.configVoltageCompSaturation(12);
        motor.enableVoltageCompensation(true);
        motor.configForwardSoftLimitThreshold(1000);
        motor.configReverseSoftLimitThreshold(-1000);
        motor.configForwardSoftLimitEnable(true, 0);
        motor.configReverseSoftLimitEnable(true, 0);
    }

    public static void configPIDMotor(TalonFX motor) {
        motor.configFactoryDefault();
        motor.configSelectedFeedbackSensor(TalonFXFeedbackDevice.IntegratedSensor, kPIDLoopIdx, kTimeoutMs);

        motor.setSensorPhase(kSensorPhase);

        motor.configNominalOutputForward(0, kTimeoutMs);
        motor.configNominalOutputReverse(0, kTimeoutMs);

        motor.configPeakOutputForward(kPeakOutput, kTimeoutMs);
        motor.configPeakOutputReverse(-kPeakOutput, kTimeoutMs);

        motor.configAllowableClosedloopError(0, kPIDLoopIdx, kTimeoutMs);

        motor.configVoltageCompSaturation(12);
        motor.enableVoltageCompensation(true);
        
        motor.configForwardSoftLimitThreshold(Conversions.degreesToFalcon(70, 25));
        motor.configReverseSoftLimitThreshold(-Conversions.degreesToFalcon(70, 25));
        motor.configForwardSoftLimitEnable(true, 0);
        motor.configReverseSoftLimitEnable(true, 0);

        motor.config_kF(kPIDLoopIdx, kF, kTimeoutMs);
        motor.config_kP(kPIDLoopIdx, kP, kTimeoutMs);
        motor.config_kI(kPIDLoopIdx, kI, kTimeoutMs);
        motor.config_kD(kPIDLoopIdx, kD, kTimeoutMs);

        motor.setSelectedSensorPosition(0);

        motor.configVoltageCompSaturation(12);
        motor.enableVoltageCompensation(true);
    }
}
