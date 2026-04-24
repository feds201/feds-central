package frc.robot;

import static edu.wpi.first.units.Units.Rotations;
import static edu.wpi.first.units.Units.RotationsPerSecond;

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
        public static final int klimit_switchID=9;
        public static final int kRollerMotorID = 62;
        public static final int kRollerMotorFollowerID = 60;
        public static final double agitateCycleConstant = 0.5;

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
        public static final double forwardTime = 1.25;
        public static final double reverseTime = .05;
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

    public static class PitConstants {
        public static final double kPoweredThresholdVolts = 4.0;

        final static long STORAGE_PER_MATCH_BYTES = 100_000_000L;  // confirmed we use ~100MB/match for logs!
        final static long STORAGE_ACCEPTABLE_BYTES = 4 * STORAGE_PER_MATCH_BYTES; 
        static java.io.File usb = new java.io.File("/u/"); 
    }

    public static class ShooterConstants {
        /** Hood motor forward soft limit in rotor rotations — the maximum travel position. */
        public static final double HOOD_FORWARD_SOFT_LIMIT_ROT = 30.0;
        /** Physical hood angle in degrees when the motor is at 0 rotor rotations (fully retracted). */
        public static final double HOOD_MIN_ANGLE_DEG = 35.5;
        /** Physical hood angle in degrees when the motor is at HOOD_FORWARD_SOFT_LIMIT_ROT (fully extended). */
        public static final double HOOD_MAX_ANGLE_DEG = 67.4;
        public static final int ShooterRightTop = 53;
        public static final int ShooterRightBottom = 52;
        public static final int ShooterBottomLeft = 51;
        public static final int ShooterTopLeft = 50;
        public static final int ShooterHood = 54;
        public static final AngularVelocity velocityTolerance = RotationsPerSecond.of(3);
         public static final Angle postionTolerance = Rotations.of(.05);

         public static final Angle maxHoodAngle = Rotations.of(27); //tune
         public static final Angle minHoodAngle = Rotations.of(0); //tune

        //offset of the shooter from robot center
        public static final Translation2d robotShooterOffset = new Translation2d(.25, 0); //TODO: tune
        //rotation of the shooter relative to robot forward
        public static final Rotation2d robotToShooterRotation = Rotation2d.fromDegrees(0.0);
        public static final Translation2d hubCenter = FieldConstants.Hub.innerCenterPoint.toTranslation2d();   
        public static final Rectangle2d trench = new Rectangle2d(robotShooterOffset, hubCenter);
        public static final Translation2d passingRight = FieldConstants.Outpost.centerPoint.plus(new Translation2d(0, 2));
        public static final Translation2d passingLeft = new Translation2d(0, 7.44).minus(new Translation2d(0, 2));
        public static final Translation2d BlueLeftTopLeft = new Translation2d(4.0, 11.208);
        public static final Translation2d BlueLeftBottomRight = new Translation2d(5.17, 6.75);
        public static final Rectangle2d BlueLeftTrench = new Rectangle2d(BlueLeftTopLeft, BlueLeftBottomRight);

        public static final Translation2d RedLeftTopLeft = new Translation2d(11.375, 1.221);
        public static final Translation2d RedLeftBottomRight = new Translation2d(12.6, -3);
        public static final Rectangle2d RedLeftTrench = new Rectangle2d(RedLeftTopLeft, RedLeftBottomRight);

        public static final Translation2d BlueRightTopLeft = new Translation2d(5.2, -3);
        public static final Translation2d BlueRightBottomRight = new Translation2d(4, 1.26);
        public static final Rectangle2d BlueRightTrench = new Rectangle2d(BlueRightTopLeft, BlueRightBottomRight);

        public static final Translation2d RedRightTopRight = new Translation2d(12.56, 6.88);
        public static final Translation2d RedRightBottomRight = new Translation2d(11.181, 11);
        public static final Rectangle2d RedRightTrench = new Rectangle2d(RedRightTopRight, RedRightBottomRight);

        public static final Rectangle2d neutralZone = new Rectangle2d(FieldConstants.LeftTrench.openingTopLeft.toTranslation2d(), FieldConstants.RightTrench.oppOpeningTopRight.toTranslation2d());
    
        // This map is used to determine the velocity of the shooter based on the distance to the target. 
        //The key is the distance to the target in meters, and the value is the velocity of the shooter in rotations per second.`
        public static final InterpolatingDoubleTreeMap kShootingVelocityMap = InterpolatingDoubleTreeMap.ofEntries(
            Map.entry(1.44, 28.0),//done 
            Map.entry(1.7, 28.0),//done 
            Map.entry(2.01, 28.0),//done
            Map.entry(2.56, 30.0),//done
            Map.entry(2.89, 31.0),//done
            Map.entry(3.08, 33.5),//done 
            Map.entry(3.37, 34.5),//done
            Map.entry(3.97,38.0), //done 
            Map.entry(4.75, 39.0),
            Map.entry(5.0,42.0),// done
            Map.entry(6.02, 42.0),//done 
            Map.entry(6.85,43.0), // Done
            Map.entry(7.6, 45.5), // done   
            Map.entry(100.0, 45.5)//far off top limit to prevent unwanted scaling past this distance 
        );

        public static final InterpolatingDoubleTreeMap kShootingPositionMap = InterpolatingDoubleTreeMap.ofEntries(
            Map.entry(1.44, 0.0),//done
            Map.entry(1.77, 0.0),//done
            Map.entry(2.01, 3.8),//done 
            Map.entry(2.56, 9.0),//done 
            Map.entry(2.89, 9.0),//done
            Map.entry(3.08, 8.5),//done //bumped all past this point by .2 up
            Map.entry(3.37, 8.5),//done
            Map.entry(3.97,10.5),//done
            Map.entry(4.75, 14.5),
            Map.entry(5.0, 15.5),// done
            Map.entry(6.02, 22.5), //done 
            Map.entry(6.85, 25.5), // done
            Map.entry(7.6, 29.5), // done
            Map.entry(100.0, 29.5) //far off top limit to prevent unwanted scaling past this distance 
        );

        public static final InterpolatingDoubleTreeMap kPassingVelocityMap = InterpolatingDoubleTreeMap.ofEntries(
           Map.entry(5.07, 26.0),
           Map.entry(6.5, 30.0),
           Map.entry(8.53, 35.0),
           Map.entry(11.12, 44.0),
           Map.entry(12.0,80.0),
           Map.entry(14.0, 90.0)

        );


         public static final InterpolatingDoubleTreeMap kPassingPositionMap = InterpolatingDoubleTreeMap.ofEntries(
            Map.entry(5.07, 29.0),
            Map.entry(6.5,29.0),
            Map.entry(8.53, 29.0),
            Map.entry(11.12, 29.0),
            Map.entry(12.0,30.0),
            Map.entry(14.0, 30.0)
        );

         

        // Dead code — ShootOnTheMove now uses a polynomial formula instead of this lookup table.
        // public static final InterpolatingDoubleTreeMap kFlightTimeMap =
        // InterpolatingDoubleTreeMap.ofEntries(
        //     Map.entry(1.44, (8.2-7.21)),
        //     Map.entry(2.11, (2.2-1.25)),
        //     Map.entry(2.24, (19.75-18.79)),
        //     Map.entry(2.96, (18.91-17.84)),
        //     // Map.entry(3.39, (4.15-3.34)), // weird outlier, ignoring
        //     Map.entry(4.07, (7.01-5.69)),
        //     Map.entry(4.6, (13.03-11.59)),
        //     Map.entry(5.23, (1.42-0.07)),
        //     Map.entry(7.6, 1.43)
        // );

        
    }
}



