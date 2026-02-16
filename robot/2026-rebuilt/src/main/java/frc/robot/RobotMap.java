package frc.robot;

import edu.wpi.first.math.Matrix;
import edu.wpi.first.math.VecBuilder;
import edu.wpi.first.math.numbers.N1;
import edu.wpi.first.math.numbers.N3;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.subsystems.swerve.generated.TunerConstants;
import frc.robot.utils.SwerveModuleStatusUtil;

/**
 * The RobotMap is a mapping from the ports sensors and actuators are wired into
 * to a variable name. This provides flexibility changing wiring.
 */
public final class RobotMap {
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

    public static class VisionConstants{
        //Use only yaw from MT1
        public static final Matrix<N3, N1> MT1_STDDEV = VecBuilder.fill(1e6, 1e6, Math.PI/60);
        //Use only x/y from MT2
        public static final Matrix<N3, N1> MT2_STDDEV = VecBuilder.fill(0.05, 0.05, 1e6);

    }
}
