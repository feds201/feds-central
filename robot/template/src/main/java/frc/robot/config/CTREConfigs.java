package frc.robot.config;

import com.ctre.phoenix.motorcontrol.SupplyCurrentLimitConfiguration;
import com.ctre.phoenix.motorcontrol.can.TalonFXConfiguration;
import com.ctre.phoenix.motorcontrol.can.TalonSRXConfiguration;
import frc.robot.Constants;

public final class CTREConfigs {
    public TalonFXConfiguration swerveAngleFXConfig;
    public TalonFXConfiguration swerveDriveFXConfig;
    public TalonSRXConfiguration swerveTalonSRXConfig;

    public CTREConfigs(){
        swerveAngleFXConfig = new TalonFXConfiguration();
        swerveDriveFXConfig = new TalonFXConfiguration();
        swerveTalonSRXConfig = new TalonSRXConfiguration();

        /* Swerve Angle Motor Configurations */
        SupplyCurrentLimitConfiguration angleSupplyLimit = new SupplyCurrentLimitConfiguration(
            Constants.SwerveConstants.angleEnableCurrentLimit, 
            Constants.SwerveConstants.angleContinuousCurrentLimit, 
            Constants.SwerveConstants.anglePeakCurrentLimit, 
            Constants.SwerveConstants.anglePeakCurrentDuration);

        swerveAngleFXConfig.slot0.kP = Constants.SwerveConstants.angleKP;
        swerveAngleFXConfig.slot0.kI = Constants.SwerveConstants.angleKI;
        swerveAngleFXConfig.slot0.kD = Constants.SwerveConstants.angleKD;
        swerveAngleFXConfig.slot0.kF = Constants.SwerveConstants.angleKF;
        swerveAngleFXConfig.supplyCurrLimit = angleSupplyLimit;

        /* Swerve Drive Motor Configuration */
        SupplyCurrentLimitConfiguration driveSupplyLimit = new SupplyCurrentLimitConfiguration(
            Constants.SwerveConstants.driveEnableCurrentLimit, 
            Constants.SwerveConstants.driveContinuousCurrentLimit, 
            Constants.SwerveConstants.drivePeakCurrentLimit, 
            Constants.SwerveConstants.drivePeakCurrentDuration);

        swerveDriveFXConfig.slot0.kP = Constants.SwerveConstants.driveKP;
        swerveDriveFXConfig.slot0.kI = Constants.SwerveConstants.driveKI;
        swerveDriveFXConfig.slot0.kD = Constants.SwerveConstants.driveKD;
        swerveDriveFXConfig.slot0.kF = Constants.SwerveConstants.driveKF;        
        swerveDriveFXConfig.supplyCurrLimit = driveSupplyLimit;
        swerveDriveFXConfig.openloopRamp = Constants.SwerveConstants.openLoopRamp;
        swerveDriveFXConfig.closedloopRamp = Constants.SwerveConstants.closedLoopRamp;
        
        /* Swerve Talon SRX Configuration */

        // in SwerveModule.java
    }
}