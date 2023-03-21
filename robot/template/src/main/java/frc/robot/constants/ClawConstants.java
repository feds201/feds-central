package frc.robot.constants;

import com.ctre.phoenix.motorcontrol.StatusFrameEnhanced;
import com.ctre.phoenix.motorcontrol.can.TalonFX;

public class ClawConstants {
    public static final int kClawMotorMain = 56;
    public static final int kClawMotorFollow = 60;

    public static final double kIntakeConePercent = -0.5;
    public static final double kOuttakeConePercent = 0.5;

    public static void configMotor(TalonFX motor) {
        motor.configFactoryDefault();
        // motor.configSelectedFeedbackSensor(TalonFXFeedbackDevice.IntegratedSensor, 0, 30);

        // motor.setSelectedSensorPosition(0);

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
        // motor.configForwardSoftLimitThreshold(1000);
        // motor.configReverseSoftLimitThreshold(-1000);
        // motor.configForwardSoftLimitEnable(true, 0);
        // motor.configReverseSoftLimitEnable(true, 0);
    }

}
