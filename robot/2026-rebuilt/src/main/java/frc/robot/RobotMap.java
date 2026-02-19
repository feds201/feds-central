package frc.robot;

import static edu.wpi.first.units.Units.Rotations;
import static edu.wpi.first.units.Units.RotationsPerSecond;

import java.util.Map;

import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.math.interpolation.InterpolatingDoubleTreeMap;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.AngularVelocity;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.subsystems.swerve.generated.TunerConstants;
import frc.robot.utils.FieldConstants;
import frc.robot.utils.SwerveModuleStatusUtil;

/**
 * The RobotMap is a mapping from the ports sensors and actuators are wired into
 * to a variable name. This provides flexibility changing wiring.
 */
public final class RobotMap {

    public static class Constants {
    public static boolean disableHAL = false;

    public static void disableHAL() {
        disableHAL = true;
    }
    }

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

    public static class SpindexerConstants {
        public static final int kSpindexerMotorId = 0;
    }

    //All values subject to change, just placeholders for now
    public static class ShooterConstants {
        public static final int kShooterLeaderId = 0;
        public static final int kShooterFollower1Id = 1;
        public static final int kShooterFollower2Id = 2;
        public static final int kShooterFollower3Id = 3;
        public static final int kHoodMotorId = 4;
        public static final AngularVelocity velocityTolerance = RotationsPerSecond.of(3);
         public static final Angle postionTolerance = Rotations.of(.05);

         public static final Angle maxHoodAngle = Rotations.of(0); //tune
         public static final Angle minHoodAngle = Rotations.of(0); //tune


        public static final Translation2d hubCenter = FieldConstants.Hub.innerCenterPoint.toTranslation2d();    
        // This map is used to determine the velocity of the shooter based on the distance to the target. 
        //The key is the distance to the target in meters, and the value is the velocity of the shooter in rotations per second.`
        public static final InterpolatingDoubleTreeMap kShootingVelocityMap = InterpolatingDoubleTreeMap.ofEntries(
            Map.entry(0.0, 0.0)
        );

        public static final InterpolatingDoubleTreeMap kPassingVelocityMap = InterpolatingDoubleTreeMap.ofEntries(
            Map.entry(0.0, 0.0)
        );


         public static final InterpolatingDoubleTreeMap kPassingPositionMap = InterpolatingDoubleTreeMap.ofEntries(
            Map.entry(0.0, 0.0)
        );

         public static final InterpolatingDoubleTreeMap kShootingPositionMap = InterpolatingDoubleTreeMap.ofEntries(
            Map.entry(0.0, 0.0)
        );

        
    }
}

  
