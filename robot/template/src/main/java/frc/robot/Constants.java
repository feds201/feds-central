package frc.robot;

import com.ctre.phoenix.motorcontrol.NeutralMode;

import edu.wpi.first.math.controller.ArmFeedforward;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.math.kinematics.SwerveDriveKinematics;
import edu.wpi.first.math.trajectory.TrapezoidProfile;
import edu.wpi.first.math.util.Units;
import frc.lib.math.Conversions;
import frc.lib.util.COTSFalconSwerveConstants;
import frc.lib.util.SwerveModuleConstants;

public class Constants {

  public static final double stickDeadbandTurn = 0.05;
  public static final double stickDeadbandDrive = 0.025;



  public static final class VisionConstants {
    public static final double limelightOffset = .13;
    public static final double limelightheight = 1.2;
    public static final double limelightToTopArmOffset = .24;
    public static final double lowTargetHeight = 1.5;
    public static final double highTargetHeight = 2.6;
    public static final double limelightPitchRadians = .67;

    public static final double degreesToEncoderCounts = 175;

    public static final int kIMG_HEIGHT = 640;
    public static final int kIMG_WIDTH = 480;
  }
  

  public static final class SwerveConstants {
    public static final int pigeonID = 0;
    public static final boolean invertGyro = false; // TODO: Always ensure Gyro is CCW+ CW-

    public static final COTSFalconSwerveConstants chosenModule = COTSFalconSwerveConstants
        .SDSMK4(COTSFalconSwerveConstants.driveGearRatios.SDSMK4_L1);

    /* Drivetrain Constants */
    public static final double trackWidth = Units.inchesToMeters(21.5);
    public static final double wheelBase = Units.inchesToMeters(25.5);
    public static final double wheelCircumference = chosenModule.wheelCircumference;

    /*
     * Swerve Kinematics
     * No need to ever change this unless you are not doing a traditional
     * rectangular/square 4 module swerve
     */
    public static final SwerveDriveKinematics swerveKinematics = new SwerveDriveKinematics(
        new Translation2d(wheelBase / 2.0, trackWidth / 2.0),
        new Translation2d(wheelBase / 2.0, -trackWidth / 2.0),
        new Translation2d(-wheelBase / 2.0, trackWidth / 2.0),
        new Translation2d(-wheelBase / 2.0, -trackWidth / 2.0));

    /* Module Gear Ratios */
    public static final double driveGearRatio = chosenModule.driveGearRatio;
    public static final double angleGearRatio = chosenModule.angleGearRatio;

    /* Motor Inverts */
    public static final boolean angleMotorInvert = chosenModule.angleMotorInvert;
    public static final boolean driveMotorInvert = chosenModule.driveMotorInvert;

    /* Angle Encoder Invert */
    public static final boolean canCoderInvert = chosenModule.canCoderInvert;

    /* Swerve Current Limiting */
    public static final int angleContinuousCurrentLimit = 25;
    public static final int anglePeakCurrentLimit = 40;
    public static final double anglePeakCurrentDuration = 0.1;

    public static final boolean angleEnableCurrentLimit = true;

    public static final int driveContinuousCurrentLimit = 35;
    public static final int drivePeakCurrentLimit = 60;
    public static final double drivePeakCurrentDuration = 0.1;
    public static final boolean driveEnableCurrentLimit = true;

    /*
     * These values are used by the drive falcon to ramp in open loop and closed
     * loop driving.
     * We found a small open loop ramp (0.25) helps with tread wear, tipping, etc
     */
    public static final double openLoopRamp = 0.25;
    public static final double closedLoopRamp = 0.0;

    /* Angle Motor PID Values */
    public static final double angleKP = chosenModule.angleKP;
    public static final double angleKI = chosenModule.angleKI;
    public static final double angleKD = chosenModule.angleKD;
    public static final double angleKF = chosenModule.angleKF;

    /* Drive Motor PID Values */
    public static final double driveKP = 0.05; // TODO: This must be tuned to specific robot
    public static final double driveKI = 0.0;
    public static final double driveKD = 0.0;
    public static final double driveKF = 0.0;

    /*
     * Drive Motor Characterization Values
     * Divide SYSID values by 12 to convert from volts to percent output for CTRE
     */
    public static final double driveKS = (0.32 / 12); // TODO: This must be tuned to specific robot
    public static final double driveKV = (1.51 / 12);
    public static final double driveKA = (0.27 / 12);

    /* Swerve Profiling Values */
    /** Meters per Second */
    public static final double maxSpeed = 3; // TODO: This must be tuned to specific robot
    /** Radians per Second */
    public static final double maxAngularVelocity = 3; // TODO: This must be tuned to specific robot


    public static final double kMaxLinearAccel = 2;
    public static final double kDeltaSecs = 0.2;

    /* Neutral Modes */
    public static final NeutralMode angleNeutralMode = NeutralMode.Coast;
    public static final NeutralMode driveNeutralMode = NeutralMode.Brake;

    public static final double kChargingStationTime = 2; // seconds

    /* Module Specific Constants */
    /* Front Left Module - Module 0 */
    public static final class Mod0 { // TODO: This must be tuned to specific robot
      public static final int driveMotorID = 12;
      public static final int angleMotorID = 11;
      public static final int canCoderID = 1;
      public static final Rotation2d angleOffset = Rotation2d.fromDegrees(270.439);
      public static final SwerveModuleConstants constants = new SwerveModuleConstants(driveMotorID, angleMotorID,
          canCoderID, angleOffset);
    }

    /* Front Right Module - Module 1 */
    public static final class Mod1 { // TODO: This must be tuned to specific robot
      public static final int driveMotorID = 32;
      public static final int angleMotorID = 31;
      public static final int canCoderID = 3;
      public static final Rotation2d angleOffset = Rotation2d.fromDegrees(287.666);
      public static final SwerveModuleConstants constants = new SwerveModuleConstants(driveMotorID, angleMotorID,
          canCoderID, angleOffset);
    }

    /* Back Left Module - Module 2 */
    public static final class Mod2 { // TODO: This must be tuned to specific robot
      public static final int driveMotorID = 22;
      public static final int angleMotorID = 21;
      public static final int canCoderID = 2;
      public static final Rotation2d angleOffset = Rotation2d.fromDegrees(345.850);
      public static final SwerveModuleConstants constants = new SwerveModuleConstants(driveMotorID, angleMotorID,
          canCoderID, angleOffset);
    }

    /* Back Right Module - Module 3 */
    public static final class Mod3 { // TODO: This must be tuned to specific robot
      public static final int driveMotorID = 42;
      public static final int angleMotorID = 41;
      public static final int canCoderID = 4;
      public static final Rotation2d angleOffset = Rotation2d.fromDegrees(226.582);
      public static final SwerveModuleConstants constants = new SwerveModuleConstants(driveMotorID, angleMotorID,
          canCoderID, angleOffset);
    }
  }

  public static final class AutoConstants { // TODO: The below constants are used in the example auto, and must be tuned
                                            // to specific robot
    public static final double kMaxSpeedMetersPerSecond = 3;
    public static final double kMaxAccelerationMetersPerSecondSquared = 3;
    public static final double kMaxAngularSpeedRadiansPerSecond = Math.PI;
    public static final double kMaxAngularSpeedRadiansPerSecondSquared = Math.PI;

    public static final double kPXController = 1;
    public static final double kPYController = 1;
    public static final double kPThetaController = 1;

    /* Constraint for the motion profilied robot angle controller */
    public static final TrapezoidProfile.Constraints kThetaControllerConstraints = new TrapezoidProfile.Constraints(
        kMaxAngularSpeedRadiansPerSecond, kMaxAngularSpeedRadiansPerSecondSquared);
  }

  public static final class PowerConstants {
    public static final int kPDPChannel = 1;
    public static final int kPCMChannel = 8;
  }

  public static final class OIConstants {
    //public static final double kDeadzoneThreshold = stickDeadband;
    public static final int kDriveControllerPort = 0;
    public static final int kOperatorControllerPort = 1;
  }

  public static final class IntakeConstants {
    // Pheonix IDs
    public static final int kIntakeBlueLeftDeployMotor = 51;
    public static final int kIntakeBlueLeftWheelMotor = 61;
    public static final int kIntakeRedRightDeployMotor = 52;
    public static final int kIntakeRedRightWheelMotor = 62;
    public static final int kIntakeTriggerID = 2;

    // Speeds
    public static final double kIntakeDeploySpeed = 0.30;
    public static final double kIntakeRetractSpeed = -0.2;
    public static final double kIntakeWheelSpeed = -0.30;

    public static final double kDeployTime = 0.5;
    public static final double kRetractTime = 0.5;

    // Encoder Counts
    public static final double kIntakeEncoderOffsetDeployed = 2640;
    public static final double kIntakeEncoderOffsetRetracted = 0;
  }

  public static final class ArmConstants {

    // Phoenix ID's
    public static final int kArmMotor1 = 57;
    public static final int kArmMotor2 = 58;

    public static final double kArmGearRatio = 38.75;
    public static final double kSetRobotToTarget = .56;
   
    // Feedforward
    public static final double kS = 0;
    public static final double kG = 0.08;
    public static final double kGPercent = kG/12;
    // public static final double kG = 0.044835;
    public static final double kV = 0;
    public static final double kA = 0;
    public static final ArmFeedforward armFeedforward = new ArmFeedforward(kS, kG, kV, kA);
    
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
    
    // setpoints
    public static final double kArmHome = 0;
    public static final double kArmPutHigh = Conversions.degreesToFalcon(90.0, ArmConstants.kArmGearRatio);
    public static final double kArmPutMiddle = Conversions.degreesToFalcon(73.0, ArmConstants.kArmGearRatio); // TODO: tune these
    public static final double kArmPutLow = Conversions.degreesToFalcon(40, kArmGearRatio);

    public static final double kArmGoalThreshold = Conversions.degreesToFalcon(5, ArmConstants.kArmGearRatio);
    public static final double kArmPickConeLeft = Conversions.degreesToFalcon(20, ArmConstants.kArmGearRatio);
    public static final double kArmPickConeRight = Conversions.degreesToFalcon(25, ArmConstants.kArmGearRatio);
    public static final double kArmPickCube = Conversions.degreesToFalcon(22.5, ArmConstants.kArmGearRatio);

    public static final double kForwardSoftLimit = Conversions.degreesToFalcon(100, ArmConstants.kArmGearRatio);
    public static final double kReverseSoftLimit = 0;
  }

  public static final class TelescopeConstants {
    public static final int kTelescopeMotor = 60;

    public static final double kP = 0.05; // FIXME: CONFIG THIS
    public static final double kI = 0;
    public static final double kD = 0;

    public static final int    peakVelocity        = 100_000; // What could this be?
    public static final double percentOfPeak       = .35;
    public static final double cruiseVelocityAccel = peakVelocity * percentOfPeak;
    
    // Setpoints
    public static final double kTelescopeOffset = 0;
    public static final double kTelescopeExtendedMax = 900_000; // FIXME: CONFIG THIS
    public static final double kTelescopeExtendedMiddle = 400_000; // FIXME: CONFIG THIS
    public static final double kTelescopeThreshold = 1000;
    public static final double kForwardTelescopeSoftLimit = 1_000_000;
    public static final double kReverseTelescopeSoftLimit = -1;

    public static final double kManualSpeed = 0.40;

    public static final Rotation2d kThreshold = Rotation2d.fromDegrees(3);
  }


  public static final class OrientatorConstants {
    public static final int kOrientatorMotorID = 29;
    public static final double kOrientatorSpeed = 0.10;
    public static final double KOrientatorTime = 2.5;
  }

  public static final class ClawConstants {
    public static final int kClawMotor = 56;

    // set points
    public static final double kOpenClawPosition = 480;
    public static final double kBallClawPosition = 254;
    public static final double kConeClawPosition = 100;

    public static final double kHoldBallSpeed = -0.1; // tune these
    public static final double kHoldConeSpeed = -0.1;
    public static final double kExtendSpeed = 0.35;
  }

  public enum coneOrientation{
    LEFT,
    RIGHT
  }
}