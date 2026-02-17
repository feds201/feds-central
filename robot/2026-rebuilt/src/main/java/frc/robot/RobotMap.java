package frc.robot;

import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.subsystems.swerve.generated.TunerConstants;
import frc.robot.utils.SwerveModuleStatusUtil;

/**
 * The RobotMap is a mapping from the ports sensors and actuators are wired into
 * to a variable name. This provides flexibility changing wiring.
 */
public final class RobotMap {

    public enum robotState{
        SIM,REAL,REPLAY;
    }
    public static final class IntakeSubsystemConstants {
        public static final int kMotorID = 1;
        public static final int kLimit_switch_rID = 2;
        public static final int kLimit_switch_lID = 3; 

    }

    public static robotState getRobotMode() {
        return Robot.isReal() ? robotState.REAL : robotState.SIM;
    }

    public static class DrivetrainConstants{
        private static final int kFrontLeftDriveMotorId = 11;
        private static final int kFrontLeftSteerMotorId = 12;
        private static final int kFrontLeftEncoderId = 13;
        private static final int kFrontRightDriveMotorId = 21;
        private static final int kFrontRightSteerMotorId = 22;
        private static final int kFrontRightEncoderId = 23;
        private static final int kBackLeftDriveMotorId = 32;
        private static final int kBackLeftSteerMotorId = 31;
        private static final int kBackLeftEncoderId = 33;
        private static final int kBackRightDriveMotorId = 41;
        private static final int kBackRightSteerMotorId = 42;
        private static final int kBackRightEncoderId = 43;

        public static CommandSwerveDrivetrain createDrivetrain(){
            SwerveModuleStatusUtil.addSwerveModule(SwerveModuleStatusUtil.ModuleLocation.FL, kFrontLeftDriveMotorId, kFrontLeftSteerMotorId, kFrontLeftEncoderId);
            SwerveModuleStatusUtil.addSwerveModule(SwerveModuleStatusUtil.ModuleLocation.FR, kFrontRightDriveMotorId, kFrontRightSteerMotorId, kFrontRightEncoderId);
            SwerveModuleStatusUtil.addSwerveModule(SwerveModuleStatusUtil.ModuleLocation.BL, kBackLeftDriveMotorId, kBackLeftSteerMotorId, kBackLeftEncoderId);
            SwerveModuleStatusUtil.addSwerveModule(SwerveModuleStatusUtil.ModuleLocation.BR, kBackRightDriveMotorId, kBackRightSteerMotorId, kBackRightEncoderId);
        
            return TunerConstants.createDrivetrain();
        }
    }
}
