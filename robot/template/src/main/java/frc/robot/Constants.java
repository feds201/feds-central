package frc.robot;

public class Constants {
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
    public static final int kSwervePigeon = 0;
  }

  public static final class PowerConstants {
    public static final int kPDPChannel = 1;
    public static final int kPCMChannel = 8;
  }

  public static final class OIConstants {
    public static final double kDeadzoneThreshold = 0.1;
    public static final int kDriveControllerPort = 0;
  }

  public static final class IntakeConstants {
    public static final int kIntakeRightDeployMotor = 52;
    public static final int kIntakeRightWheelMotor = 62;
    public static final int KrightIntakeControllerChannel = 3232;
    public static final double kIntakeDeploySpeed = 0.15;
    public static final double kIntakeWheelSpeed = 0.30;
    public static final double kIntakeEncoderOffset = 1000;
  }

  public static final class ArmConstants {
    public static final int kArmMotor1 = 0;
    public static final int kArmMotor2 = 0;
  }

  public static final class TelescopeConstants {
    public static final int kTelescopeMotor = 0;
  }

  public static final class OrientatorConstants {
    public static final int kOrientatorMotor1 = 0;
    public static final int kOrientatorMotor2 = 0;
  }

  public static final class ClawConstants {
    public static final int kClawMotor = 0;
  }

}