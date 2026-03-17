package frc.robot;

import static edu.wpi.first.units.Units.Rotations;
import static edu.wpi.first.units.Units.RotationsPerSecond;

import java.lang.reflect.Field;
import java.util.Map;

import edu.wpi.first.math.Matrix;
import edu.wpi.first.math.VecBuilder;
import edu.wpi.first.math.geometry.Rectangle2d;
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
        // while still being trusted for rotation. The 1e16 X/Y values indicate extremely
        // high uncertainty in translation so pose estimators will down‑weight MT1's
        // position contribution, but the relatively small rotational stddev (~3 degrees)
        // allows MT1 to meaningfully contribute to heading estimation.
        public static final Matrix<N3, N1> MT1_STDDEV = VecBuilder.fill(1e16, 1e16, Math.PI / 60);
        // MT2 is the complementary measurement source: it is trusted for X/Y translation
        // (small stddevs) and effectively ignored for rotation (very large stddev).
        // Together, these settings implement "use only x/y from MT2" and "use only
        // rotation from MT1" when fusing measurements.
        public static final Matrix<N3, N1> MT2_STDDEV = VecBuilder.fill(0.5, 0.5, 1e16);
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
        public static final int kMotorID = 61;
        public static final int kLimit_switch_rID = 2;
        public static final int kLimit_switch_lID = 3; 
        public static final int kRollerMotorID = 62;

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

    public static class indexingConstants {
        public static final double forwardTime = 2;
        public static final double reverseTime = .5;
    }

    public static class FeederConstants
    {
        public static final int kFeederKickerMotorId = 56;

    }

    //All values subject to change, just placeholders for now
    public static class PathfindConstants {
        public static final double xP = 0.0;
        public static final double xI = 0.0;
        public static final double xD = 0.0;
        public static final double yP = 0.0;
        public static final double yI = 0.0;
        public static final double yD = 0.0;
        public static final double rotP = 0.0;
        public static final double rotI = 0.0;
        public static final double rotD = 0.0;
    }

    public static class ShooterConstants {
        public static final int ShooterRightTop = 53;
        public static final int ShooterRightBottom = 52;
        public static final int ShooterBottomLeft = 51;
        public static final int ShooterTopLeft = 50;
        public static final int ShooterHood = 54;
        public static final AngularVelocity velocityTolerance = RotationsPerSecond.of(3);
         public static final Angle postionTolerance = Rotations.of(.05);

         public static final Angle maxHoodAngle = Rotations.of(27); //tune
         public static final Angle minHoodAngle = Rotations.of(.5); //tune

        //offset of the shooter from robot center
        public static final Translation2d robotShooterOffset = new Translation2d(.25, 0); //TODO: tune
        //rotation of the shooter relative to robot forward
        public static final Rotation2d robotToShooterRotation = Rotation2d.fromDegrees(0.0);
        public static final Translation2d hubCenter = FieldConstants.Hub.innerCenterPoint.toTranslation2d();   
        public static final Rectangle2d trench = new Rectangle2d(robotShooterOffset, hubCenter);
        public static final Translation2d passingRight = FieldConstants.Outpost.centerPoint;
        public static final Translation2d passingLeft = new Translation2d(0, 7.44);

        public static final Translation2d BlueLeftTopLeft = new Translation2d(4.0, 8.208);
        public static final Translation2d BlueLeftBottomRight = new Translation2d(5.17, 6.75);
        public static final Rectangle2d BlueLeftTrench = new Rectangle2d(BlueLeftTopLeft, BlueLeftBottomRight);

        public static final Translation2d RedLeftTopLeft = new Translation2d(11.375, 1.221);
        public static final Translation2d RedLeftBottomRight = new Translation2d(12.6, 0.082);
        public static final Rectangle2d RedLeftTrench = new Rectangle2d(RedLeftTopLeft, RedLeftBottomRight);

        public static final Translation2d BlueRightTopLeft = new Translation2d(5.2, 0.018);
        public static final Translation2d BlueRightBottomRight = new Translation2d(4, 1.26);
        public static final Rectangle2d BlueRightTrench = new Rectangle2d(BlueRightTopLeft, BlueRightBottomRight);

        public static final Translation2d RedRightTopRight = new Translation2d(12.56, 6.88);
        public static final Translation2d RedRightBottomRight = new Translation2d(11.181, 8.104);
        public static final Rectangle2d RedRightTrench = new Rectangle2d(RedRightTopRight, RedRightBottomRight);

        public static final Rectangle2d neutralZone = new Rectangle2d(FieldConstants.LeftTrench.openingTopLeft.toTranslation2d(), FieldConstants.RightTrench.oppOpeningTopRight.toTranslation2d());
    
        // This map is used to determine the velocity of the shooter based on the distance to the target. 
        //The key is the distance to the target in meters, and the value is the velocity of the shooter in rotations per second.`
        public static final InterpolatingDoubleTreeMap kShootingVelocityMap = InterpolatingDoubleTreeMap.ofEntries(
            Map.entry(1.44, 27.0),//done
            Map.entry(1.63, 28.0),//done
            Map.entry(1.98, 29.0),//done
            Map.entry(2.57, 31.5),//done
            Map.entry(2.83, 33.7),//done
             Map.entry(3.09, 36.5),//done --- AUTON SHOOTING POSITION
            Map.entry(3.42, 38.0), //done
            Map.entry(4.59, 41.0), //done
            Map.entry(100.0, 40.5)//far off top limit to prevent unwanted scaling past this distance 
        );

        public static final InterpolatingDoubleTreeMap kShootingPositionMap = InterpolatingDoubleTreeMap.ofEntries(
            Map.entry(1.44, 0.0),//done
            Map.entry(1.63, 3.3),//done
            Map.entry(1.98, 7.3),//done
            Map.entry(2.57, 11.3),//done
            Map.entry(2.83, 15.0),//done
             Map.entry(3.09, 15.0),// -- AUTON SHOOTING POSITION
            Map.entry(3.42, 16.7),//done
            Map.entry(4.59, 23.2), //done
            Map.entry(100.0, 23.2) //far off top limit to prevent unwanted scaling past this distance 
        );

        public static final InterpolatingDoubleTreeMap kPassingVelocityMap = InterpolatingDoubleTreeMap.ofEntries(
            Map.entry(0.0, 0.0)
        );


         public static final InterpolatingDoubleTreeMap kPassingPositionMap = InterpolatingDoubleTreeMap.ofEntries(
            Map.entry(0.0, 0.0)
        );

         

        //TODO: tune
        public static final InterpolatingDoubleTreeMap kFlightTimeMap =
        InterpolatingDoubleTreeMap.ofEntries(
            Map.entry(1.61, 1.01),
            Map.entry(2.58, 0.84),
            Map.entry(2.9, 0.98),
            Map.entry(3.6, 1.27),
            Map.entry(1.61, 1.01),
            Map.entry(2.58, 0.84),
            Map.entry(2.9, 0.98),
            Map.entry(3.6, 1.27)
        );

        
    }
}



