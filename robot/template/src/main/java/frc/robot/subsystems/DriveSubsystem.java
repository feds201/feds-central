package frc.robot.subsystems;

import com.ctre.phoenix.motorcontrol.FeedbackDevice;
import com.ctre.phoenix.motorcontrol.StatusFrameEnhanced;
import com.ctre.phoenix.motorcontrol.can.TalonSRX;

import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.Constants;
import frc.robot.config.SwerveDriveConfig;
import frc.robot.swerve.FourCornerSwerveDrive;
import frc.robot.swerve.ISwerveModule;
import frc.robot.swerve.RobotPose;
import frc.robot.swerve.SDSMk4FXModule;

public class DriveSubsystem extends SubsystemBase {

    private final FourCornerSwerveDrive swerveDrive;

    private SwerveDriveConfig swerveDriveConfig;

    private RobotPose pose;

    public DriveSubsystem() {
        TalonSRX talon1 = new TalonSRX(Constants.SWERVE_FRONT_LEFT_ENCODER);
        TalonSRX talon2 = new TalonSRX(Constants.SWERVE_FRONT_RIGHT_ENCODER);
        TalonSRX talon3 = new TalonSRX(Constants.SWERVE_BACK_LEFT_ENCODER);
        TalonSRX talon4 = new TalonSRX(Constants.SWERVE_BACK_RIGHT_ENCODER);
        configEncoderTalon(talon1);
        configEncoderTalon(talon2);
        configEncoderTalon(talon3);
        configEncoderTalon(talon4);

        swerveDriveConfig = new SwerveDriveConfig();

        pose = new RobotPose();

        ISwerveModule frontLeft = new SDSMk4FXModule(Constants.SWERVE_FRONT_LEFT_STEER, Constants.SWERVE_FRONT_LEFT_DRIVE,
            Constants.SWERVE_FRONT_LEFT_ENCODER, Constants.FRONT_LEFT_ENCODER_OFFSET,
            swerveDriveConfig.moduleConfig);
        ISwerveModule frontRight = new SDSMk4FXModule(Constants.SWERVE_FRONT_RIGHT_STEER, Constants.SWERVE_FRONT_RIGHT_DRIVE,
            Constants.SWERVE_FRONT_RIGHT_ENCODER, Constants.FRONT_RIGHT_ENCODER_OFFSET,
            swerveDriveConfig.moduleConfig);
        ISwerveModule backLeft = new SDSMk4FXModule(Constants.SWERVE_BACK_LEFT_STEER, Constants.SWERVE_BACK_LEFT_DRIVE,
            Constants.SWERVE_BACK_LEFT_ENCODER, Constants.BACK_LEFT_ENCODER_OFFSET,
            swerveDriveConfig.moduleConfig);
        ISwerveModule backRight = new SDSMk4FXModule(Constants.SWERVE_BACK_RIGHT_STEER, Constants.SWERVE_BACK_RIGHT_DRIVE,
            Constants.SWERVE_BACK_RIGHT_ENCODER, Constants.BACK_RIGHT_ENCODER_OFFSET,
            swerveDriveConfig.moduleConfig);
        this.swerveDrive = new FourCornerSwerveDrive(frontLeft, frontRight, backLeft, backRight,
            Constants.SWERVE_PIGEON, pose, swerveDriveConfig);
    }

    private static void configEncoderTalon(TalonSRX talon) {
        talon.configFactoryDefault();
        talon.configSelectedFeedbackSensor(FeedbackDevice.CTRE_MagEncoder_Absolute);
        talon.configFeedbackNotContinuous(true, 50);
        talon.setSensorPhase(true);
        talon.setInverted(false);
        talon.setStatusFramePeriod(StatusFrameEnhanced.Status_1_General, 255);
        talon.setStatusFramePeriod(StatusFrameEnhanced.Status_2_Feedback0, 255);
        talon.setStatusFramePeriod(StatusFrameEnhanced.Status_3_Quadrature, 255);
        talon.setStatusFramePeriod(StatusFrameEnhanced.Status_4_AinTempVbat, 255);
        talon.setStatusFramePeriod(StatusFrameEnhanced.Status_8_PulseWidth, 255);
        talon.setStatusFramePeriod(StatusFrameEnhanced.Status_10_Targets, 255);
        talon.setStatusFramePeriod(StatusFrameEnhanced.Status_12_Feedback1, 255);
        talon.setStatusFramePeriod(StatusFrameEnhanced.Status_13_Base_PIDF0, 255);
        talon.setStatusFramePeriod(StatusFrameEnhanced.Status_14_Turn_PIDF1, 255);
    }

    @Override
    public void periodic() {
        this.swerveDrive.periodic(); 
    }

    public void setTargetVelocity(double linearAngle, double linearSpeed, double rotate) {
        this.swerveDrive.setTargetVelocity(linearAngle, linearSpeed, rotate);
    } 

    public double getPoseAngle() {
        return pose.angle;
    }
}
