package frc.robot.constants;

import com.ctre.phoenix.motorcontrol.NeutralMode;
import com.ctre.phoenix.motorcontrol.StatusFrameEnhanced;
import com.ctre.phoenix.motorcontrol.SupplyCurrentLimitConfiguration;
import com.ctre.phoenix.motorcontrol.TalonFXInvertType;
import com.ctre.phoenix.motorcontrol.can.TalonFX;

import edu.wpi.first.math.controller.ArmFeedforward;
import frc.lib.math.Conversions;

public class ArmConstants {
    // Phoenix ID's
    public static final int kArmMotor1 = 62;

    public static final double kArmGearRatio = 250;

    public static final double kRotateInputSensitivity = 0.5;
   
    public static final int    peakVelocityUp        = 13360;
    public static final double percentOfPeakUp       = .15;
    public static final double cruiseVelocityAccelUp = peakVelocityUp * percentOfPeakUp;

    public static final int    peakVelocityDown        = 8090;
    public static final double percentOfPeakDown       = .65;
    public static final double cruiseVelocityAccelDown = peakVelocityDown * percentOfPeakDown;

    // PID (Feedback)
    public static final double kPUp   = 0.1;
    public static final double kIUp   = 0;
    public static final double kDUp   = 0;

    public static final double kPDown = 0.1;
    public static final double kIDown = 0;
    public static final double kDDown = 0;
   
    // FEEDFORWARD GAINS
    public static final double kS = 0;
    public static final double kG = 0;
    public static final double kV = 0;
    public static final double kA = 0;
    
    // setpoints
    public static final double kArmHome = 0;
    public static final double kArmPutHigh =       Conversions.degreesToFalcon(0, kArmGearRatio);
    public static final double kArmPutMiddle =     Conversions.degreesToFalcon(0, kArmGearRatio); // FIXME: tune these
    public static final double kArmPutLow =        Conversions.degreesToFalcon(0, kArmGearRatio);
    public static final double kArmGrabCone =      Conversions.degreesToFalcon(0, kArmGearRatio);
    public static final double kArmAutonPosition = Conversions.degreesToFalcon(0, kArmGearRatio);
    public static final double kArmTolerance =     100;

    public static final double kForwardSoftLimit = Conversions.degreesToFalcon(100, kArmGearRatio);
    public static final double kReverseSoftLimit = Conversions.degreesToFalcon(-1, kArmGearRatio);
    
    public static void configArmMotor(TalonFX motor) {
        motor.configFactoryDefault();
       
        /* CONFIG MOTION MAGIC */
        motor.config_kP(0, kPUp, 0);
        motor.config_kI(0, kIUp, 0);
        motor.config_kD(0, kDUp, 0);
        motor.configMotionAcceleration(cruiseVelocityAccelUp, 0);
        motor.configMotionCruiseVelocity(cruiseVelocityAccelUp, 0);
        motor.selectProfileSlot(0, 0);
        
        /* THRESHOLDS */
        motor.configForwardSoftLimitThreshold(Conversions.degreesToFalcon(130, ArmConstants.kArmGearRatio),
                0);
        motor.configReverseSoftLimitThreshold(Conversions.degreesToFalcon(-130, ArmConstants.kArmGearRatio), 0);
        motor.configForwardSoftLimitEnable(true, 0);
        motor.configReverseSoftLimitEnable(true, 0);

        /* MOTOR TYPES */
        motor.setInverted(TalonFXInvertType.CounterClockwise);
        motor.setNeutralMode(NeutralMode.Brake);

        /* VOLTAGE COMPENSATION */
        motor.configVoltageCompSaturation(12);
        motor.enableVoltageCompensation(true);

        /* STATUS FRAME PERIODS */
        motor.setStatusFramePeriod(StatusFrameEnhanced.Status_1_General, 10);
        motor.setStatusFramePeriod(StatusFrameEnhanced.Status_2_Feedback0, 10);
        motor.setStatusFramePeriod(StatusFrameEnhanced.Status_3_Quadrature, 255);
        motor.setStatusFramePeriod(StatusFrameEnhanced.Status_4_AinTempVbat, 255);
        motor.setStatusFramePeriod(StatusFrameEnhanced.Status_8_PulseWidth, 255);
        motor.setStatusFramePeriod(StatusFrameEnhanced.Status_10_Targets, 255);
        motor.setStatusFramePeriod(StatusFrameEnhanced.Status_12_Feedback1, 255);
        motor.setStatusFramePeriod(StatusFrameEnhanced.Status_13_Base_PIDF0, 255);
        motor.setStatusFramePeriod(StatusFrameEnhanced.Status_14_Turn_PIDF1, 255);
        motor.setStatusFramePeriod(StatusFrameEnhanced.Status_Brushless_Current, 255);

        /* CURRENT LIMITING */
        SupplyCurrentLimitConfiguration rotateArmMainCurrentLimit = new SupplyCurrentLimitConfiguration();
        rotateArmMainCurrentLimit.currentLimit = 40;
        motor.configSupplyCurrentLimit(rotateArmMainCurrentLimit);
    }
}
