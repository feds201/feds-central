package frc.robot;

import static edu.wpi.first.units.Units.Rotations;
import static edu.wpi.first.units.Units.RotationsPerSecond;

import java.util.Map;

import edu.wpi.first.math.Matrix;
import edu.wpi.first.math.VecBuilder;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.math.interpolation.InterpolatingDoubleTreeMap;
import edu.wpi.first.math.numbers.N1;
import edu.wpi.first.math.numbers.N3;
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
   
    public static class VisionConstants {
        // MT1 is configured to be effectively ignored for X/Y position (very large stddev)
        // while still being trusted for rotation. The 1e6 X/Y values indicate extremely
        // high uncertainty in translation so pose estimators will down‑weight MT1's
        // position contribution, but the relatively small rotational stddev (~3 degrees)
        // allows MT1 to meaningfully contribute to heading estimation.
        public static final Matrix<N3, N1> MT1_STDDEV = VecBuilder.fill(1e6, 1e6, Math.PI / 60);
        // MT2 is the complementary measurement source: it is trusted for X/Y translation
        // (small stddevs) and effectively ignored for rotation (very large stddev).
        // Together, these settings implement "use only x/y from MT2" and "use only
        // rotation from MT1" when fusing measurements.
        public static final Matrix<N3, N1> MT2_STDDEV = VecBuilder.fill(0.5, 0.5, 1e6);
    }

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
        public static final int kExtensionMotorID = 58;
        public static final int kRollerMotorID = 59;
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
        public static final int kSpindexerMotorId = 57;
    }

    public static class FeederConstants
    {
        public static final int kFeederKickerMotorId = 56;

    }

    //All values subject to change, just placeholders for now
    public static class ShooterConstants {
        public static final int ShooterRightTop = 53;
        public static final int ShooterRightBottom = 52;
        public static final int ShooterBottomLeft = 51;
        public static final int ShooterTopLeft = 50;
        public static final int ShooterHood = 54;
        public static final AngularVelocity velocityTolerance = RotationsPerSecond.of(3);
         public static final Angle postionTolerance = Rotations.of(.05);

         public static final Angle maxHoodAngle = Rotations.of(30); //tune
         public static final Angle minHoodAngle = Rotations.of(.5); //tune

        //offset of the shooter from robot center
        public static final Translation2d robotShooterOffset = new Translation2d(.25, 0); //TODO: tune
        //rotation of the shooter relative to robot forward
        public static final Rotation2d robotToShooterRotation = Rotation2d.fromDegrees(0.0);
        public static final Translation2d hubCenter = FieldConstants.Hub.innerCenterPoint.toTranslation2d();   
        public static final Translation2d centerPointOutpost = FieldConstants.Outpost.centerPoint;
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

        //TODO: tune
        public static final InterpolatingDoubleTreeMap kFlightTimeMap =
        InterpolatingDoubleTreeMap.ofEntries(
            Map.entry(1.0, 0.35),
            Map.entry(2.0, 0.45),
            Map.entry(3.0, 0.55),
            Map.entry(4.0, 0.65),
            Map.entry(5.0, 0.78),
            Map.entry(6.0, 0.90),
            Map.entry(7.0, 1.02),
            Map.entry(8.0, 1.15),
            Map.entry(9.0, 1.28),
            Map.entry(10.0, 1.40)
        );

        
    }
}

  
