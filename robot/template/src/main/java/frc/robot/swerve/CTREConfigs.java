package frc.robot.swerve;

import com.ctre.phoenix.motorcontrol.SupplyCurrentLimitConfiguration;
import com.ctre.phoenix.motorcontrol.can.TalonFXConfiguration;
import com.ctre.phoenix.sensors.AbsoluteSensorRange;
import com.ctre.phoenix.sensors.SensorInitializationStrategy;
import com.ctre.phoenix.sensors.SensorTimeBase;
import com.ctre.phoenix.sensors.CANCoderConfiguration;
import frc.robot.constants.SwerveConstants;

public final class CTREConfigs {
    public TalonFXConfiguration swerveAngleFXConfig;
    public TalonFXConfiguration swerveDriveFXConfig;
    public CANCoderConfiguration swerveCanCoderConfig;

    /**
     * 
     */
    public CTREConfigs(){
        swerveAngleFXConfig = new TalonFXConfiguration();
        swerveDriveFXConfig = new TalonFXConfiguration();
        swerveCanCoderConfig = new CANCoderConfiguration();

        /* Swerve Angle Motor Configurations */
        SupplyCurrentLimitConfiguration angleSupplyLimit = new SupplyCurrentLimitConfiguration(
            SwerveConstants.angleEnableCurrentLimit, 
            SwerveConstants.angleContinuousCurrentLimit, 
            SwerveConstants.anglePeakCurrentLimit, 
            SwerveConstants.anglePeakCurrentDuration);

        swerveAngleFXConfig.slot0.kP = SwerveConstants.angleKP;
        swerveAngleFXConfig.slot0.kI = SwerveConstants.angleKI;
        swerveAngleFXConfig.slot0.kD = SwerveConstants.angleKD;
        swerveAngleFXConfig.slot0.kF = SwerveConstants.angleKF;
        swerveAngleFXConfig.supplyCurrLimit = angleSupplyLimit;

        /* Swerve Drive Motor Configuration */
        SupplyCurrentLimitConfiguration driveSupplyLimit = new SupplyCurrentLimitConfiguration(
            SwerveConstants.driveEnableCurrentLimit, 
            SwerveConstants.driveContinuousCurrentLimit, 
            SwerveConstants.drivePeakCurrentLimit, 
            SwerveConstants.drivePeakCurrentDuration);

        swerveDriveFXConfig.slot0.kP = SwerveConstants.driveKP;
        swerveDriveFXConfig.slot0.kI = SwerveConstants.driveKI;
        swerveDriveFXConfig.slot0.kD = SwerveConstants.driveKD;
        swerveDriveFXConfig.slot0.kF = SwerveConstants.driveKF;        
        swerveDriveFXConfig.supplyCurrLimit = driveSupplyLimit;
        swerveDriveFXConfig.openloopRamp = SwerveConstants.openLoopRamp;
        swerveDriveFXConfig.closedloopRamp = SwerveConstants.closedLoopRamp;
        
        /* Swerve Talon SRX Configuration */

        swerveCanCoderConfig.absoluteSensorRange = AbsoluteSensorRange.Unsigned_0_to_360;
        swerveCanCoderConfig.sensorDirection = SwerveConstants.canCoderInvert;
        swerveCanCoderConfig.initializationStrategy = SensorInitializationStrategy.BootToAbsolutePosition;
        swerveCanCoderConfig.sensorTimeBase = SensorTimeBase.PerSecond;
    }
}   