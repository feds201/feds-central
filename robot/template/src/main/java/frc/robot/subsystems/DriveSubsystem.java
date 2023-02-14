package frc.robot.subsystems;

import com.ctre.phoenix.motorcontrol.FeedbackDevice;
import com.ctre.phoenix.motorcontrol.StatusFrameEnhanced;
import com.ctre.phoenix.motorcontrol.can.TalonSRX;

import edu.wpi.first.wpilibj.Encoder;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.Constants;
import frc.robot.Constants.ModuleConstants;
import frc.robot.config.SwerveDriveConfig;
import frc.robot.sensors.Pigeon;
import frc.robot.swerve.FourCornerSwerveDrive;
import frc.robot.swerve.ISwerveModule;
import frc.robot.swerve.RobotPose;
import frc.robot.swerve.SDSMk4FXModule;
import edu.wpi.first.wpilibj.XboxController;


public class DriveSubsystem extends SubsystemBase {

    private final FourCornerSwerveDrive swerveDrive;

    private SwerveDriveConfig swerveDriveConfig;

    private RobotPose pose;

    private Pigeon m_pigeon;

    public DriveSubsystem() {
        this.m_pigeon = Pigeon.getInstance();

        TalonSRX talon1 = new TalonSRX(ModuleConstants.kSwerveFrontLeftEncoder);
        TalonSRX talon2 = new TalonSRX(ModuleConstants.kSwerveFrontRightEncoder);
        TalonSRX talon3 = new TalonSRX(ModuleConstants.kSwerveBackLeftEncoder);
        TalonSRX talon4 = new TalonSRX(ModuleConstants.kSwerveBackRightEncoder);
        configEncoderTalon(talon1);
        configEncoderTalon(talon2);
        configEncoderTalon(talon3);
        configEncoderTalon(talon4);

        swerveDriveConfig = new SwerveDriveConfig();

        pose = new RobotPose();

        ISwerveModule frontLeft = new SDSMk4FXModule(ModuleConstants.kSwerveFrontLeftSteer, ModuleConstants.kSwerveFrontLeftDrive,
            ModuleConstants.kSwerveFrontLeftEncoder, ModuleConstants.kFrontLeftEncoderOffset,
            swerveDriveConfig.moduleConfig);
        ISwerveModule frontRight = new SDSMk4FXModule(ModuleConstants.kSwerveFrontRightSteer, ModuleConstants.kSwerveFrontRightDrive,
            ModuleConstants.kSwerveFrontRightEncoder, ModuleConstants.kFrontRightEncoderOffset,
            swerveDriveConfig.moduleConfig);
        ISwerveModule backLeft = new SDSMk4FXModule(ModuleConstants.kSwerveBackLeftSteer, ModuleConstants.kServeBackRightDrive,
            ModuleConstants.kSwerveBackLeftEncoder, ModuleConstants.kBackLeftEncoderOffset,
            swerveDriveConfig.moduleConfig);
        ISwerveModule backRight = new SDSMk4FXModule(ModuleConstants.kSwerveBackRightSteer, ModuleConstants.kSwerveFrontRightDrive,
            ModuleConstants.kSwerveBackRightEncoder, ModuleConstants.kBackRightEncoderOffset,
            swerveDriveConfig.moduleConfig);
        this.swerveDrive = new FourCornerSwerveDrive(frontLeft, frontRight, backLeft, backRight,
            m_pigeon, pose, swerveDriveConfig);
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
