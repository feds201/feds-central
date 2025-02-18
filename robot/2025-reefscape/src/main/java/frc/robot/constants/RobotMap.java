package frc.robot.constants;

import com.ctre.phoenix6.configs.TalonFXConfiguration;
import com.ctre.phoenix6.configs.TalonFXConfigurator;
import com.ctre.phoenix6.signals.NeutralModeValue;
import com.ctre.phoenix6.configs.CurrentLimitsConfigs;
import com.ctre.phoenix6.configs.TalonFXConfiguration;
import com.ctre.phoenix6.configs.TalonFXConfigurator;
import com.pathplanner.lib.path.PathConstraints;

import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.util.Units;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;

public class RobotMap {

    public static class SafetyMap {
        public static final double kMaxSpeed = 6.0;
        public static final double kMaxRotation = 1.0;
        public static final double kMaxAcceleration = 1.0;
        public static final double kMaxAngularAcceleration = 1.0;
        public static final double kMaxAngularRate = Math.PI; // 3/4 of a rotation per second max angular velocity
        public static final double kAngularRateMultiplier = 1;
        public static final double kJoystickDeadband = 0.1;
        public static double kMaxSpeedChange = 1;
        public static double kFollowerCommand = 6;

        public static class AutonConstraints {
            public static final double kMaxSpeed = 1.0;
            public static final double kMaxAcceleration = 3.0;
            public static final double kMaxAngularRate = Units.degreesToRadians(0);
            public static final double kMaxAngularAcceleration = Units.degreesToRadians(360);
            public static final PathConstraints kPathConstraints = new PathConstraints(kMaxSpeed, kMaxAcceleration,
                    kMaxAngularRate, kMaxAngularAcceleration);
        }

        public static class SwerveConstants {
            public static double kRotationP = 0.007;
            public static double kRotationI = .000;// .0001
            public static double kRotationD = .00;
            public static double speedpercentage = 1.0;
            public static double kRotationTolerance = 1.0;
        }

        public static class FODC {
            public static final int LineCount = 72;
            public static double AngleDiff = 0.0;
        }
    }

    // USB Ports for Controllers
    public static class UsbMap {
        public static final int DRIVER_CONTROLLER = 0;
        public static final int OPERATOR_CONTROLLER = 1;
        public static CommandXboxController driverController = new CommandXboxController(DRIVER_CONTROLLER);
        public static CommandXboxController operatorController = new CommandXboxController(OPERATOR_CONTROLLER);
    }

    // CAN IDs for Swerve Drive System
    public static class SwerveMap {
        public static final int FRONT_LEFT_STEER = 0;
        public static final int FRONT_RIGHT_STEER = 1;
        public static final int BACK_LEFT_STEER = 2;
        public static final int BACK_RIGHT_STEER = 3;
        public static final int FRONT_LEFT_DRIVE = 4;
        public static final int FRONT_RIGHT_DRIVE = 5;
        public static final int BACK_LEFT_DRIVE = 6;
        public static final int BACK_RIGHT_DRIVE = 7;
    }

    public static class ElevatorMap {
        public static final int ELEVATOR_MOTOR = 61;
        public static final int ELEVATOR_MOTOR2 = 62;
        public static final int ELEVATOR_SPEED = 0;
        public static final int EVEVATOR_ENCODER = 63;
        public static final double ELEVATOR_P = 0.001;
        public static final double ELEVATOR_I = 0;
        public static final double ELEVATOR_D = 0;
        public static final double ELEVATOR_F = 0;
        public static final double PARENT_GEAR_RADIUS = Units.inchesToMeters(2.5);
        public static final double ELEVATOR_CIRCUMFERENCE = 2 * Math.PI * PARENT_GEAR_RADIUS;
        public static final double ELEVATOR_CURRENT_LIMIT = 20;

    }

    public static class ClimberMap {
        public static final int CLIMBER_LEADER_MOTOR = 51;
        public static final int CLIMBER_FOLLOWER_MOTOR = 52;
        public static final int CLIMBER_ENCODER = 53;
        public static final int CLIMBER_LEFT_DI = 1;
        public static final int CLIMBER_RIGHT_DI = 2;
        public static final int CLIMBER_CURRENT_LIMIT = 40;
        public static final double CLIMBER_PID_TOLERANCE = 3;
        public static final double CLIMBER_UP_ANGLE = 90;
        public static final double CLIMBER_STOW_ANGLE = 0;
        public static final PIDController climberPID = new PIDController(0, 0, 0);

        ClimberMap() {
            climberPID.setTolerance(CLIMBER_PID_TOLERANCE);
        }
    }

    // Additional motor controllers or sensors could be added here
    public static class SensorMap {
        // Example: Add sensor ports (like encoders, gyros, etc.)
        public static final int GYRO_PORT = 0;
        public static final int INTAKE_IR_SENSOR = 2;

    }

    // You can add more mappings for other subsystems like intake, shooter, etc.

    public static class VisionMap {

        public static final double ballRadius = 9; // cm ; 3.5 inches
        public static final double targetHeight = 1.6; // m ; 38.7 inches
        public static final double cameraHeight = .6; // m ; 16 inches
        public static final double cameraAngle = 40; // degrees

        public static class CameraConfig {
            public static class BackCam {
                public static final int CAMERA_HEIGHT = 480;
                public static final int CAMERA_WIDTH = 640;
                public static final double TARGET_HEIGHT = 0.0;
                public static final double HORIZONTAL_FOV = 59.6;
                public static final double VERTICAL_FOV = 45.7;

            }

            public static class FrontCam {
                public static final int CAMERA_HEIGHT = 480;
                public static final int CAMERA_WIDTH = 640;
                public static final double TARGET_HEIGHT = 0.0;
                public static final double HORIZONTAL_FOV = 59.6;
                public static final double VERTICAL_FOV = 45.7;
            }

            public static double tx;
            public static double ty;
            public static double ta;
            public static double distance;
        }

    }

    public static class IntakeMap {

        public static final int INTAKE_MOTOR_CURRENT_LIMIT = 20;
        public static final int PIVOT_MOTOR_CURRENT_LIMIT = 20;

        public static class SensorCanId {
            public static final int INTAKE_MOTOR = 71;
            public static final int PIVOT_MOTOR = 72;
            public static final int CORAL_CANRANGE = 100;
            public static final int ALGAE_CANRANGE = 100;
            public static final int INTAKE_ENCODER = 73;

        }

        public static PIDController intakePid = new PIDController(0, 0, 0);

        public static TalonFXConfiguration getBreakConfiguration() {
            TalonFXConfiguration configuration = new TalonFXConfiguration();
            configuration.MotorOutput.NeutralMode = NeutralModeValue.Brake;
            return configuration;
        }

        public static TalonFXConfiguration getCoastConfiguration() {
            TalonFXConfiguration configuration = new TalonFXConfiguration();
            configuration.MotorOutput.NeutralMode = NeutralModeValue.Coast;
            return configuration;
        }
    }

    public static class CurrentLimiter {
        public static CurrentLimitsConfigs getCurrentLimitConfiguration(double amps) {
            CurrentLimitsConfigs configs = new CurrentLimitsConfigs();

            configs.StatorCurrentLimit = amps;
            configs.StatorCurrentLimitEnable = true;

            return configs;
        }
    }

    public static class AutonPosesMap {
        public static final Pose2d right16 = new Pose2d(4.953, 5.185, Rotation2d.fromDegrees(-120));
        public static final Pose2d left16 = new Pose2d(5.226, 5.058, Rotation2d.fromDegrees(-120));
        public static final Pose2d right26 = new Pose2d(5.704, 4.152, Rotation2d.fromDegrees(180));
        public static final Pose2d left26 = new Pose2d(5.713, 3.879, Rotation2d.fromDegrees(180));
        public static final Pose2d right36 = new Pose2d(5.245, 3.03, Rotation2d.fromDegrees(120));
        public static final Pose2d left36 = new Pose2d(4.953, 2.874, Rotation2d.fromDegrees(120));
        public static final Pose2d right46 = new Pose2d(4, 2.874, Rotation2d.fromDegrees(60));
        public static final Pose2d left46 = new Pose2d(3.715, 3.03, Rotation2d.fromDegrees(60));
        public static final Pose2d right56 = new Pose2d(3.247, 3.849, Rotation2d.fromDegrees(0));
        public static final Pose2d left56 = new Pose2d(3.256, 4.191, Rotation2d.fromDegrees(0));
        public static final Pose2d right66 = new Pose2d(3.715, 5.029, Rotation2d.fromDegrees(-60));
        public static final Pose2d left66 = new Pose2d(4.014, 5.187, Rotation2d.fromDegrees(-60));
    }
}