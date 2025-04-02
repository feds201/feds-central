package frc.robot.subsystems.swerve;

import java.util.Map;
import java.util.function.DoubleSupplier;

import com.ctre.phoenix6.Utils;
import com.ctre.phoenix6.hardware.Pigeon2;
import com.pathplanner.lib.auto.AutoBuilder;
import com.pathplanner.lib.config.RobotConfig;
import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.kinematics.ChassisSpeeds;
import edu.wpi.first.math.kinematics.Odometry;
import edu.wpi.first.wpilibj.shuffleboard.BuiltInWidgets;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardTab;
import edu.wpi.first.wpilibj.shuffleboard.SimpleWidget;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import frc.robot.constants.RobotMap;
import frc.robot.constants.RobotMap.SafetyMap;
import frc.robot.constants.RobotMap.SafetyMap.SwerveConstants;
import frc.robot.utils.SubsystemABS;
import frc.robot.utils.Subsystems;
import frc.robot.utils.Telemetry;
import frc.robot.utils.DrivetrainConstants;
import frc.robot.utils.PoseAllocate;

@SuppressWarnings("unused")
public class SwerveSubsystem extends SubsystemABS {

    private final Pigeon2 pigeonIMU;
    private CommandXboxController driverController;
    public CommandSwerveDrivetrain drivetrain;
    private Double robotFacingAngle;
    private SimpleWidget robotSpeedWidget;
    private PIDController rPidController;
    private AutoBuilder builder;
    private Integer closestTAG;
    private double simX = 0;
    private double simY = 0;
    private double simRotation = 0;
    private Telemetry telemetry;

    public SwerveSubsystem(Subsystems part, String tabName, int pigeonIMUID, CommandXboxController driverController) {
        super(part, tabName);
        this.pigeonIMU = new Pigeon2(pigeonIMUID); // Initialize Pigeon IMU
        this.driverController = driverController;
        this.drivetrain = DrivetrainConstants.drivetrain;
        printcontroller();
        telemetry = new Telemetry(SafetyMap.kMaxSpeed);

        robotFacingAngle = 0.0;
        rPidController = new PIDController(SwerveConstants.kRotationP, SwerveConstants.kRotationI,
                SwerveConstants.kRotationD);
        rPidController.setTolerance(SwerveConstants.kRotationTolerance);
        tab = getTab();

        tab.addNumber("Gyro", () -> robotFacingAngle)
                .withWidget(BuiltInWidgets.kGyro) // Use Gyro widget
                .withProperties(Map.of("startingAngle", 0, "majorTickSpacing", 45)) // Customize properties
                .withPosition(3, 0)
                .withSize(3, 3);

        robotSpeedWidget = tab.add("Robot Speed (%)", (RobotMap.SafetyMap.kMaxSpeedChange * 100))
                .withPosition(3, 5)
                .withWidget(BuiltInWidgets.kNumberSlider)
                .withProperties(Map.of("min", 0, "max", 100))
                .withSize(6, 2);
        tab.add("Rotation PID", rPidController);
        tab.addNumber("Band/Robot X", ()-> drivetrain.getState().Pose.getX());
        tab.addNumber("Band/Robot Y", ()-> drivetrain.getState().Pose.getY());

        tab.addBoolean("Robot Within Barge Range", ()-> Math.abs(DrivetrainConstants.drivetrain.getState().Pose.getX() - 8.775) <  1.135 && Math.abs(DrivetrainConstants.drivetrain.getState().Pose.getX() - 8.775) > 1.04);

        if (Utils.isSimulation()) DrivetrainConstants.drivetrain.registerTelemetry(telemetry::telemeterize);

        

        RobotConfig config;
        try {
            config = RobotConfig.fromGUISettings();
        } catch (Exception e) {
            // Handle exception as needed
            e.printStackTrace();
        }
    }


    @Override
    public void periodic() {
        robotFacingAngle = drivetrain.getState().Pose.getRotation().getDegrees();

       
    }

    @Override
    public void simulationPeriodic() {
        robotFacingAngle = drivetrain.getState().Pose.getRotation().getDegrees();
        


    }

    public double applyDeadband(double value, double deadband) {
        if (Math.abs(value) > deadband) {
            return value;
        }
        return value;
    }

    public double getRobotAngle() {
        return robotFacingAngle;
    }

    @Override
    public void setDefaultCmd() {
        drivetrain.setDefaultCommand(null);

    }

    @Override
    public boolean isHealthy() {
        return drivetrain.isHealthy();
    }

    public void drive(double speed, double strafe, double rotation, boolean fieldCentric) {
        if (fieldCentric) {
            double angle = Math.toRadians(getRobotAngle());
            double temp = speed * Math.cos(angle) + strafe * Math.sin(angle);
            strafe = -speed * Math.sin(angle) + strafe * Math.cos(angle);
            speed = temp;
        }
        drivetrain.setControl(DrivetrainConstants.drive
                .withRotationalRate(rotation * SafetyMap.kMaxAngularAcceleration)
                .withVelocityX(speed * SafetyMap.kMaxSpeed)
                .withVelocityY(strafe * SafetyMap.kMaxSpeed));
    }

    public Command setBetaCmd() {
        return null;
    }

    public void stop() {
        DrivetrainConstants.drivetrain.setControl(DrivetrainConstants.brake);
    }

    public void printcontroller() {
        try {
            tab.addNumber(tabName + "/Left Y", () -> applyDeadband(driverController.getLeftY(), 0.10));
            tab.addNumber(tabName + "/Left X", () -> applyDeadband(driverController.getLeftX(), 0.10));
            tab.addNumber(tabName + "/Right X", () -> applyDeadband(driverController.getRightX(), 0.10));
            tab.addNumber(tabName + "/Right Y", () -> applyDeadband(driverController.getRightY(), 0.10));
            tab.addNumber(tabName + "/Left Trigger", () -> applyDeadband(driverController.getLeftTriggerAxis(), 0.10));
            tab.addNumber(tabName + "/Right Trigger",
                    () -> applyDeadband(driverController.getRightTriggerAxis(), 0.10));
            tab.addBoolean(tabName + "/Left Bumper", driverController.leftBumper());
            tab.addBoolean(tabName + "/Right Bumper", driverController.rightBumper());
            tab.addBoolean(tabName + "/A Button", driverController.a());
            tab.addBoolean(tabName + "/B Button", driverController.b());
            tab.addBoolean(tabName + "/X Button", driverController.x());
            tab.addBoolean(tabName + "/Y Button", driverController.y());
            tab.addBoolean(tabName + "/Start Button", driverController.start());
            tab.addBoolean(tabName + "/Back Button", driverController.back());
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public double snapToNearestLine(double angle, int i) {
        double snapAngle = 360.0 / SafetyMap.FODC.LineCount;
        return Math.round(angle / snapAngle) * snapAngle;
    }

    @Override
    public void Failsafe() {
        stop();
    }

    public double getPIDRotation(double currentX) {

        double temp = rPidController.calculate(currentX);
        if (Math.abs(temp) < 0.1) {
            return 0;
        }

        return temp;
    }

    public void setRotationSetpoint(double setpoint) {
        rPidController.setSetpoint(setpoint);
    }

    public double getRotationSetpoint() {
        return rPidController.getSetpoint();
    }

    public void setTolerance(double tolerance) {
        rPidController.setTolerance(tolerance);
    }

    public void setControl(double rotation, double strafe, double forward) {
        drivetrain.setControl(DrivetrainConstants.drive
                .withRotationalRate(rotation * SafetyMap.kMaxAngularAcceleration)
                .withVelocityX(forward * SafetyMap.kMaxSpeed)
                .withVelocityY(strafe * SafetyMap.kMaxSpeed)

        );
    }

    public void setControl(double rotation, double strafe, double forward, double heading) {
        drivetrain.setControl(DrivetrainConstants.drive
                .withRotationalRate(rotation * SafetyMap.kMaxAngularAcceleration)
                .withVelocityX(forward * SafetyMap.kMaxSpeed)
                .withVelocityY(strafe * SafetyMap.kMaxSpeed));
    }

    public CommandSwerveDrivetrain getDrivetrain() {
        return drivetrain;
    }

    public DoubleSupplier calculateFODC(double rightx, double righty) {
        final double angle = Math.toDegrees(Math.atan2(righty, rightx));

        SmartDashboard.putNumber("Angle", angle);
        SmartDashboard.putNumber("Right X", rightx);
        SmartDashboard.putNumber("Right Y", righty);
        return () -> angle;
    }

    public void resetGyro() {
        pigeonIMU.setYaw(0);
    }

    public Pose2d getPose() {
        return drivetrain.getState().Pose;

    }

    public void driveRobotRelative(double x, double y, int i) {

        drivetrain.setControl(DrivetrainConstants.robotDrive
                .withRotationalRate(i * SafetyMap.kMaxAngularAcceleration)
                .withVelocityX(x * SafetyMap.kMaxSpeed)
                .withVelocityY(y * SafetyMap.kMaxSpeed));
    }

    public void driveFieldRelative(double x, double y, double i) {
        drivetrain.setControl(DrivetrainConstants.drive
                .withRotationalRate(i * SafetyMap.kMaxAngularAcceleration)
                .withVelocityX(x * SafetyMap.kMaxSpeed)
                .withVelocityY(y * SafetyMap.kMaxSpeed));
    }

    // Add these helper methods
    private void resetPose(Pose2d pose) {
        drivetrain.resetPose(pose);
    }

    private ChassisSpeeds getChassisSpeeds() {
        return drivetrain.getState().Speeds;
    }

 
}