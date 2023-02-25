package frc.robot;

public class Constants {

  public static final class SensorConstants {
    public static final int kPigeon = 0;
  }

  public static final class ModuleConstants {
    public static final int kSwerveFrontLeftDrive = 42;
    public static final int kSwerveFrontRightDrive = 22;
    public static final int kServeBackLeftDrive = 32;
    public static final int kServeBackRightDrive = 12;

    public static final int kSwerveFrontLeftSteer = 41;
    public static final int kSwerveFrontRightSteer = 21;
    public static final int kSwerveBackLeftSteer = 31;
    public static final int kSwerveBackRightSteer = 11;

    public static final double kFrontLeftEncoderOffset = 0.6527862548828125;
    public static final double kFrontRightEncoderOffset = 0.759521484375;
    public static final double kBackLeftEncoderOffset = 0.01407623291015625;
    public static final double kBackRightEncoderOffset = 0.16002655029296875;

    public static final int kSwerveFrontLeftEncoder = 4;
    public static final int kSwerveFrontRightEncoder = 2;
    public static final int kSwerveBackLeftEncoder = 3;
    public static final int kSwerveBackRightEncoder = 1;
  }

  public static final class PowerConstants {
    public static final int kPDPChannel = 1;
    public static final int kPCMChannel = 8;
  }

  public static final class OIConstants {
    public static final double kDeadzoneThreshold = 0.1;
    public static final int kDriveControllerPort = 0;
    public static final int kOperatorControllerPort = 1;
  }

  public static final class IntakeConstants {
    // Pheonix IDs
    public static final int kIntakeRightDeployMotor = 52;
    public static final int kIntakeRightWheelMotor = 62;
    public static final int kIntakeTriggerID = 2;

    // Speeds
    public static final double kIntakeDeploySpeed = -0.05;
    public static final double kIntakeRetractSpeed = -0.15;
    public static final double kIntakeWheelSpeed = 0.30;

    // Encoder Counts
    public static final double kIntakeEncoderOffsetDeployed = 2640;
    public static final double kIntakeEncoderOffsetRetracted = 0;
  }

  public static final class ArmConstants {

    //Phoenix ID's
    public static final int kArmMotor1 = 57;
    public static final int kArmMotor2 = 58;
    //public static final int kArmPulley = 60;

    //speeds
    public static final double kArmMotorSpeed = 0.075;
    public static final double kArmPulleySpeed = 0.1;

    public static final double kArmOffset = -1025;
    public static final double kArmRotatePreset1 = 5000;
    public static final double kArmRotateMin = -5000;
    public static final double kArmRotateMax = 5000;
    public static final double multiplier = 1;
  }

  public static final class TelescopeConstants {
    public static final int kTelescopeMotor = 60;

    public static final double kTelescopeSpeed = 0.05;

    public static final double kTelescopeOffset = 0;
    public static final double kTelescopeExtended = 6000;
  }

  public static final class OrientatorConstants {
    public static final int kOrientatorMotor1 = 0;
    public static final int kOrientatorMotor2 = 0;
  }

  public static final class ClawConstants {
    public static final int kClawMotor = 56;
  }

}