// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot;

import com.ctre.phoenix.motorcontrol.FeedbackDevice;
import com.ctre.phoenix.motorcontrol.StatusFrameEnhanced;
import com.ctre.phoenix.motorcontrol.can.TalonSRX;

import edu.wpi.first.wpilibj.TimedRobot;
import edu.wpi.first.wpilibj.XboxController;
import frc.robot.swerve.ISwerveDrive;
import frc.robot.config.SwerveDriveConfig;
import frc.robot.swerve.FourCornerSwerveDrive;
import frc.robot.swerve.ISwerveModule;
import frc.robot.swerve.RobotPose;
import frc.robot.swerve.SDSMk4FXModule;
import frc.robot.swerve.SwerveMode;

/**
 * The VM is configured to automatically run this class, and to call the
 * functions corresponding to
 * each mode, as described in the TimedRobot documentation. If you change the
 * name of this class or
 * the package after creating this project, you must also update the
 * build.gradle file in the
 * project.
 */
public class Robot extends TimedRobot {
  /**
   * This function is run when the robot is first started up and should be used
   * for any
   * initialization code.
   */

  public static final int PDP_CHANNEL = 1;
  public static final int PCM_CHANNEL = 8;

  public static final int SWERVE_FRONT_LEFT_STEER = 41;
  public static final int SWERVE_FRONT_LEFT_DRIVE = 42;
  public static final int SWERVE_FRONT_LEFT_ENCODER = 4;

  public static final int SWERVE_FRONT_RIGHT_STEER = 21;
  public static final int SWERVE_FRONT_RIGHT_DRIVE = 22;
  public static final int SWERVE_FRONT_RIGHT_ENCODER = 2;

  public static final int SWERVE_BACK_LEFT_STEER = 31;
  public static final int SWERVE_BACK_LEFT_DRIVE = 32;
  public static final int SWERVE_BACK_LEFT_ENCODER = 3;

  public static final int SWERVE_BACK_RIGHT_STEER = 11;
  public static final int SWERVE_BACK_RIGHT_DRIVE = 12;
  public static final int SWERVE_BACK_RIGHT_ENCODER = 1;

  public static final int SWERVE_PIGEON = 0;

  public static final double FRONT_LEFT_ENCODER_OFFSET = 0.6586990356445312;
  public static final double FRONT_RIGHT_ENCODER_OFFSET = 0.745635986328125;
  public static final double BACK_LEFT_ENCODER_OFFSET = 0.01123046875;
  public static final double BACK_RIGHT_ENCODER_OFFSET = 0.16309356689453125;

  public static final double DEADZONE_THRESHOLD = 0.1;

  public XboxController driverController = new XboxController(0);

  private ISwerveDrive swerveDrive;
  private SwerveDriveConfig swerveDriveConfig;

  private RobotPose pose;

  @Override
  public void robotInit() {
    TalonSRX talon1 = new TalonSRX(SWERVE_FRONT_LEFT_ENCODER);
    TalonSRX talon2 = new TalonSRX(SWERVE_FRONT_RIGHT_ENCODER);
    TalonSRX talon3 = new TalonSRX(SWERVE_BACK_LEFT_ENCODER);
    TalonSRX talon4 = new TalonSRX(SWERVE_BACK_RIGHT_ENCODER);
    configEncoderTalon(talon1);
    configEncoderTalon(talon2);
    configEncoderTalon(talon3);
    configEncoderTalon(talon4);

    swerveDriveConfig = new SwerveDriveConfig();

    pose = new RobotPose();

    ISwerveModule frontLeft = new SDSMk4FXModule(SWERVE_FRONT_LEFT_STEER, SWERVE_FRONT_LEFT_DRIVE,
        SWERVE_FRONT_LEFT_ENCODER, FRONT_LEFT_ENCODER_OFFSET,
        swerveDriveConfig.moduleConfig);
    ISwerveModule frontRight = new SDSMk4FXModule(SWERVE_FRONT_RIGHT_STEER, SWERVE_FRONT_RIGHT_DRIVE,
        SWERVE_FRONT_RIGHT_ENCODER, FRONT_RIGHT_ENCODER_OFFSET,
        swerveDriveConfig.moduleConfig);
    ISwerveModule backLeft = new SDSMk4FXModule(SWERVE_BACK_LEFT_STEER, SWERVE_BACK_LEFT_DRIVE,
        SWERVE_BACK_LEFT_ENCODER, BACK_LEFT_ENCODER_OFFSET,
        swerveDriveConfig.moduleConfig);
    ISwerveModule backRight = new SDSMk4FXModule(SWERVE_BACK_RIGHT_STEER, SWERVE_BACK_RIGHT_DRIVE,
        SWERVE_BACK_RIGHT_ENCODER, BACK_RIGHT_ENCODER_OFFSET,
        swerveDriveConfig.moduleConfig);
    swerveDrive = new FourCornerSwerveDrive(frontLeft, frontRight, backLeft, backRight,
        SWERVE_PIGEON, pose, swerveDriveConfig);

    
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
  public void robotPeriodic() {
    swerveDrive.periodic(); 
  }

  @Override
  public void autonomousInit() {
  }

  @Override
  public void autonomousPeriodic() {
  }

  @Override
  public void teleopInit() {
    
  }

  @Override
  public void teleopPeriodic() {
    double forward = -driverController.getLeftY();
		double strafe = driverController.getLeftX();
		double rotateX = driverController.getRightX();

		double linearAngle = -Math.atan2(forward, strafe) / Math.PI / 2 + 0.25;
		linearAngle = (linearAngle % 1 + 1) % 1;
		double linearSpeed = deadzone(Math.sqrt(forward * forward + strafe * strafe), DEADZONE_THRESHOLD);

    double rotate = deadzone(rotateX, DEADZONE_THRESHOLD) / 2;

    swerveDrive.setTargetVelocity(linearAngle, linearSpeed, rotate);
  }

  @Override
  public void disabledInit() {
  }

  @Override
  public void disabledPeriodic() {
  }

  @Override
  public void testInit() {
    swerveDrive.align();

    double [] alignments = new double[4];
    swerveDrive.getAlignments(alignments);

    System.out.println("Front Left: " + alignments[0]);
    System.out.println("Front Right: " + alignments[1]);
    System.out.println("Back Left: " + alignments[2]);
    System.out.println("Back Right: " + alignments[3]);


  }

  @Override
  public void testPeriodic() {
  }

  @Override
  public void simulationInit() {
  }

  @Override
  public void simulationPeriodic() {
  }
  
  public final double deadzone(double input, double threshold) {
		if (Math.abs(input) < threshold)
			return 0;
		return Math.signum(input) * (Math.abs(input) - threshold) / (1 - threshold);
	}

}
