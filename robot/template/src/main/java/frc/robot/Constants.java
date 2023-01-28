package frc.robot;

public class Constants {
  public static final class ModuleConstants {
    public static final int kSwerveFrontLeftDrive = 42;
    public static final int SWERVE_FRONT_RIGHT_DRIVE = 22;
    public static final int SWERVE_BACK_LEFT_DRIVE = 32;
    public static final int SWERVE_BACK_RIGHT_DRIVE = 12;

    public static final int SWERVE_FRONT_LEFT_STEER = 41;
    public static final int SWERVE_FRONT_RIGHT_STEER = 21;
    public static final int SWERVE_BACK_LEFT_STEER = 31;
    public static final int SWERVE_BACK_RIGHT_STEER = 11;

    public static final double FRONT_LEFT_ENCODER_OFFSET = 0.6527862548828125;
    public static final double FRONT_RIGHT_ENCODER_OFFSET = 0.759521484375;
    public static final double BACK_LEFT_ENCODER_OFFSET = 0.01407623291015625;
    public static final double BACK_RIGHT_ENCODER_OFFSET = 0.16002655029296875;

    public static final int SWERVE_FRONT_LEFT_ENCODER = 4;
    public static final int SWERVE_FRONT_RIGHT_ENCODER = 2;
    public static final int SWERVE_BACK_LEFT_ENCODER = 3;
    public static final int SWERVE_BACK_RIGHT_ENCODER = 1;
    public static final int SWERVE_PIGEON = 0;
  }

  public static final class PowerConstants {
    public static final int PDP_CHANNEL = 1;
    public static final int PCM_CHANNEL = 8;
  }

  public static final class OIConstants {
    public static final double DEADZONE_THRESHOLD = 0.1;
    public static final int kDriveControllerPort = 0;
  }

}
