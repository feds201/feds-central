package frc.robot.swerve;

import com.ctre.phoenix.motorcontrol.ControlMode;
import com.ctre.phoenix.motorcontrol.DemandType;
import com.ctre.phoenix.motorcontrol.StatusFrameEnhanced;
import com.ctre.phoenix.motorcontrol.can.TalonFX;
import com.ctre.phoenix.sensors.CANCoder;

import edu.wpi.first.math.controller.SimpleMotorFeedforward;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.kinematics.SwerveModulePosition;
import edu.wpi.first.math.kinematics.SwerveModuleState;
import frc.lib.math.Conversions;
import frc.lib.util.CTREModuleState;
import frc.lib.util.SwerveModuleConstants;
import frc.robot.constants.SwerveConstants;
import frc.robot.Robot; 

public class SwerveModule {
    public int moduleNumber;
    private Rotation2d angleOffset;
    private Rotation2d lastAngle;

    private TalonFX mAngleMotor;
    private TalonFX mDriveMotor;
    
    private CANCoder angleEncoder;

    SimpleMotorFeedforward feedforward = new SimpleMotorFeedforward(SwerveConstants.driveKS, SwerveConstants.driveKV, SwerveConstants.driveKA);

    public SwerveModule(int moduleNumber, SwerveModuleConstants moduleConstants){
        this.moduleNumber = moduleNumber;
        this.angleOffset = moduleConstants.angleOffset;
        
        /* Angle Encoder Config */
        angleEncoder = new CANCoder(moduleConstants.canCoderID);
        configAngleEncoder();

        /* Angle Motor Config */
        mAngleMotor = new TalonFX(moduleConstants.angleMotorID);
        configAngleMotor();

        /* Drive Motor Config */
        mDriveMotor = new TalonFX(moduleConstants.driveMotorID);
        configDriveMotor();

        lastAngle = getState().angle;
    }

    public void setDesiredState(SwerveModuleState desiredState, boolean isOpenLoop){
        /* This is a custom optimize function, since default WPILib optimize assumes continuous controller which CTRE and Rev onboard is not */
        desiredState = CTREModuleState.optimize(desiredState, getState().angle); 
        setAngle(desiredState);
        setSpeed(desiredState, isOpenLoop);
    }

    private void setSpeed(SwerveModuleState desiredState, boolean isOpenLoop){
        if(isOpenLoop){
            double percentOutput = desiredState.speedMetersPerSecond / SwerveConstants.maxSpeed;
            mDriveMotor.set(ControlMode.PercentOutput, percentOutput);
        }
        else {
            double velocity = Conversions.MPSToFalcon(desiredState.speedMetersPerSecond, SwerveConstants.wheelCircumference,SwerveConstants.driveGearRatio);
            mDriveMotor.set(ControlMode.Velocity, velocity, DemandType.ArbitraryFeedForward, feedforward.calculate(desiredState.speedMetersPerSecond));
        }
    }

    private void setAngle(SwerveModuleState desiredState){
        Rotation2d angle = (Math.abs(desiredState.speedMetersPerSecond) <= (SwerveConstants.maxSpeed * 0.01)) ? lastAngle : desiredState.angle; //Prevent rotating module if speed is less then 1%. Prevents Jittering.
        
        mAngleMotor.set(ControlMode.Position, Conversions.degreesToFalcon(angle.getDegrees(), SwerveConstants.angleGearRatio));
        lastAngle = angle;
    }

    private Rotation2d getAngle(){
        return Rotation2d.fromDegrees(Conversions.falconToDegrees(mAngleMotor.getSelectedSensorPosition(), SwerveConstants.angleGearRatio));
    }

    public Rotation2d getCanCoderAngle(){
        return Rotation2d.fromDegrees(angleEncoder.getAbsolutePosition());
    }

    public void resetToAbsolute(){
        double absolutePosition = Conversions.degreesToFalcon(getCanCoderAngle().getDegrees() - angleOffset.getDegrees(), SwerveConstants.angleGearRatio);
        mAngleMotor.setSelectedSensorPosition(absolutePosition);
    }

    private void configAngleEncoder(){        
        angleEncoder.configFactoryDefault();
        angleEncoder.configAllSettings(Robot.ctreConfigs.swerveCanCoderConfig);
    }

    private void configAngleMotor(){
        mAngleMotor.configFactoryDefault();
        mAngleMotor.configAllSettings(Robot.ctreConfigs.swerveAngleFXConfig);
        mAngleMotor.setInverted(SwerveConstants.angleMotorInvert);
        mAngleMotor.setNeutralMode(SwerveConstants.angleNeutralMode);

        mAngleMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_1_General, 20);
		mAngleMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_2_Feedback0, 10);
		mAngleMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_3_Quadrature, 255);
		mAngleMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_4_AinTempVbat, 255);
		mAngleMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_8_PulseWidth, 255);
		mAngleMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_10_Targets, 255);
		mAngleMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_12_Feedback1, 255);
		mAngleMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_13_Base_PIDF0, 20);
		mAngleMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_14_Turn_PIDF1, 255);
		mAngleMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_Brushless_Current, 255);
        resetToAbsolute();
    }

    private void configDriveMotor(){        
        mDriveMotor.configFactoryDefault();
        mDriveMotor.configAllSettings(Robot.ctreConfigs.swerveDriveFXConfig);
        mDriveMotor.setInverted(SwerveConstants.driveMotorInvert);
        mDriveMotor.setNeutralMode(SwerveConstants.driveNeutralMode);
        mDriveMotor.setSelectedSensorPosition(0);


        mDriveMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_1_General, 20);
		mDriveMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_2_Feedback0, 10);
		mDriveMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_3_Quadrature, 255);
		mDriveMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_4_AinTempVbat, 255);
		mDriveMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_8_PulseWidth, 255);
		mDriveMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_10_Targets, 255);
		mDriveMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_12_Feedback1, 255);
		mDriveMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_13_Base_PIDF0, 20);
		mDriveMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_14_Turn_PIDF1, 255);
		mDriveMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_Brushless_Current, 255);
    }

    public SwerveModuleState getState(){
        return new SwerveModuleState(
            Conversions.falconToMPS(mDriveMotor.getSelectedSensorVelocity(), SwerveConstants.wheelCircumference, SwerveConstants.driveGearRatio), 
            getAngle()
        ); 
    }

    public SwerveModulePosition getPosition(){
        return new SwerveModulePosition(
            Conversions.falconToMeters(mDriveMotor.getSelectedSensorPosition(), SwerveConstants.wheelCircumference, SwerveConstants.driveGearRatio), 
            getAngle()
        );
    }
}