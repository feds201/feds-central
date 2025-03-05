package frc.robot;

import java.io.IOException;
import java.nio.file.Path;
import java.util.Map;
import java.util.function.DoubleSupplier;

import org.json.simple.parser.ParseException;

import com.ctre.phoenix6.Utils;
import com.ctre.phoenix6.swerve.SwerveDrivetrain.SwerveDriveState;
import com.pathplanner.lib.auto.AutoBuilder;
import com.pathplanner.lib.auto.NamedCommands;
import com.pathplanner.lib.commands.PathPlannerAuto;
import com.pathplanner.lib.commands.PathfindingCommand;
import com.pathplanner.lib.events.EventTrigger;
import com.pathplanner.lib.path.PathConstraints;
import com.pathplanner.lib.path.PathPlannerPath;
import com.pathplanner.lib.util.FileVersionException;

import edu.wpi.first.math.controller.HolonomicDriveController;
import edu.wpi.first.math.estimator.SwerveDrivePoseEstimator;
import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.kinematics.SwerveModulePosition;
import edu.wpi.first.math.util.Units;
import edu.wpi.first.networktables.NetworkTable;
import edu.wpi.first.networktables.NetworkTableInstance;
import edu.wpi.first.networktables.StructPublisher;
import edu.wpi.first.wpilibj.XboxController.Axis;
import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardTab;
import edu.wpi.first.wpilibj.smartdashboard.SendableChooser;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.CommandScheduler;
import edu.wpi.first.wpilibj2.command.Commands;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.ParallelCommandGroup;
import edu.wpi.first.wpilibj2.command.RepeatCommand;
import edu.wpi.first.wpilibj2.command.button.CommandPS5Controller;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import edu.wpi.first.wpilibj2.command.button.RobotModeTriggers;
import edu.wpi.first.wpilibj2.command.button.Trigger;
import frc.robot.commands.auton.FeedThenL3;
import frc.robot.commands.auton.MoveBack;
import frc.robot.commands.auton.pathfindToReef;
import frc.robot.commands.auton.posePathfindToReef;
import frc.robot.commands.auton.pathfindToReef.reefPole;
import frc.robot.commands.climber.RaiseClimberBasic;
import frc.robot.commands.lift.RotateElevatorBasic;
import frc.robot.commands.lift.RotateElevatorDownPID;
import frc.robot.commands.lift.RotateElevatorPID;
import frc.robot.commands.lift.RotateElevatorSafePID;
import frc.robot.commands.swanNeck.PlaceLTwo;
import frc.robot.commands.swanNeck.RaiseSwanNeck;
import frc.robot.commands.swanNeck.RaiseSwanNeckPID;
import frc.robot.commands.swanNeck.PlaceLThree;
import frc.robot.commands.swanNeck.SpinSwanWheels;
import frc.robot.commands.swanNeck.IntakeCoralSequence;
import frc.robot.commands.swanNeck.PlaceLFour;
import frc.robot.commands.swanNeck.PlaceLOne;
import frc.robot.commands.swerve.ConfigureHologenicDrive;
import frc.robot.commands.swerve.DriveForwardCommand;
import frc.robot.commands.swerve.GameNavigator;
import frc.robot.constants.*;
import frc.robot.constants.RobotMap.ElevatorMap;
import frc.robot.constants.RobotMap.IntakeMap;
import frc.robot.constants.RobotMap.SafetyMap;
import frc.robot.constants.RobotMap.SensorMap;
import frc.robot.constants.RobotMap.UsbMap;
import frc.robot.constants.RobotMap.SafetyMap.AutonConstraints;
import frc.robot.subsystems.climber.Climber;
import frc.robot.subsystems.lift.Lift;
import frc.robot.subsystems.swanNeck.SwanNeck;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.subsystems.swerve.SwerveSubsystem;
import frc.robot.subsystems.vision.camera.Camera;
import frc.robot.utils.AutoPathFinder;
import frc.robot.utils.DrivetrainConstants;
import frc.robot.utils.LimelightHelpers;
import frc.robot.utils.ObjectType;
import frc.robot.utils.PoseAllocate;
import frc.robot.utils.PoseEstimator;
import frc.robot.utils.RobotFramework;
import frc.robot.utils.SafetyManager;
import frc.robot.utils.SubsystemABS;
import frc.robot.utils.Subsystems;
import frc.robot.utils.Telemetry;

@SuppressWarnings("unused") // DO NOT REMOVE

public class RobotContainer extends RobotFramework {

    private final SwerveSubsystem swerveSubsystem;
    private final CommandXboxController driverController;
    private final CommandXboxController operatorController;
    private Telemetry telemetry;
    private final SendableChooser<Command> teleOpChooser;
    private final SendableChooser<Command> autonChooser;
    private SendableChooser<Command> commandChooser;
    private final Camera frontRightCamera;
    private final Camera frontLeftCamera;
    private final Camera rearRightCamera;
    private final Camera rearLeftCamera;
    private final Climber climber;
    public Command zeroMechanisms;

    // private final Camera rearCamera;
    private final PathConstraints autoAlignConstraints;
    private final PoseEstimator poseEstimator;
    private Lift elevator;
    private SwanNeck swanNeck;

    private final NetworkTableInstance inst = NetworkTableInstance.getDefault();

    public RobotContainer() {
        double swerveSpeedMultiplier = 0.4;
        driverController = UsbMap.driverController;
        operatorController = UsbMap.operatorController;
        autoAlignConstraints = AutonConstraints.kPathConstraints;

        poseEstimator = new PoseEstimator(DrivetrainConstants.drivetrain);

        climber = new Climber(
            Subsystems.CLIMBER,
             Subsystems.CLIMBER.getNetworkTable());

        elevator = new Lift(
                Subsystems.ELEVATOR,
                Subsystems.ELEVATOR.getNetworkTable());

        swerveSubsystem = new SwerveSubsystem(
                Subsystems.SWERVE_DRIVE,
                Subsystems.SWERVE_DRIVE.getNetworkTable(),
                SensorMap.GYRO_PORT,
                driverController);

        frontRightCamera = new Camera(
                Subsystems.VISION,
                Subsystems.VISION.getNetworkTable(),
                ObjectType.APRIL_TAG_FRONT,
                "limelight-seven");

        frontLeftCamera = new Camera(
            Subsystems.VISION, Subsystems.VISION.getNetworkTable(), ObjectType.APRIL_TAG_FRONT_LEFT, "limelight-five"
        );

        rearRightCamera = new Camera(Subsystems.VISION, Subsystems.VISION.getNetworkTable(), ObjectType.APRIL_TAG_BACK,
                "limelight-three");

        rearLeftCamera = new Camera(Subsystems.VISION, Subsystems.VISION.getNetworkTable(), ObjectType.APRIL_TAG_LEFT,
                "limelight-one");

        swanNeck = new SwanNeck(
                Subsystems.INTAKE,
                Subsystems.INTAKE.getNetworkTable());
        telemetry = new Telemetry(5);

        teleOpChooser = new SendableChooser<>();

        setupDrivetrain();

        DrivetrainConstants.drivetrain.setDefaultCommand(DrivetrainConstants.drivetrain.applyRequest(() -> DrivetrainConstants.drive
        .withVelocityX(-driverController.getLeftY() * SafetyMap.kMaxSpeed
                        * SafetyMap.kMaxSpeedChange)
        .withVelocityY(-driverController.getLeftX() * SafetyMap.kMaxSpeed
                        * SafetyMap.kMaxSpeedChange)
        .withRotationalRate(-driverController.getRightX()
                        * SafetyMap.kMaxAngularRate
                        * SafetyMap.kAngularRateMultiplier)));

        zeroMechanisms = new InstantCommand(()-> elevator.zeroElevator())
        .alongWith(new InstantCommand(()-> swanNeck.zeroPivotPosition())).alongWith(new InstantCommand(()-> climber.zeroClimber()));

         
        setupEventTriggers();
        setupNamedCommands();
        autonChooser = AutoBuilder.buildAutoChooser();
        setupPaths();
        SmartDashboard.putData(autonChooser);
        configureBindings();

        telemetry = new Telemetry(SafetyMap.kMaxSpeed);
        DrivetrainConstants.drivetrain.registerTelemetry(telemetry::telemeterize);

    }

    // ADD: Getter for Elevator
    public Lift getElevator() {
        return elevator;
    }


    public void setupVisionImplants() {
        var driveState = DrivetrainConstants.drivetrain.getState();
        double headingDeg = driveState.Pose.getRotation().getDegrees();
        Rotation2d gyroAngle = driveState.Pose.getRotation();
        SmartDashboard.putNumber("robot rotation", headingDeg);
        double omega = Units.radiansToRotations(driveState.Speeds.omegaRadiansPerSecond);
        frontRightCamera.SetRobotOrientation(headingDeg, 0, 0, 0, 0, 0);
        rearRightCamera.SetRobotOrientation(headingDeg, 0, 0, 0, 0, 0);
        rearLeftCamera.SetRobotOrientation(headingDeg, 0, 0, 0, 0, 0);
        frontLeftCamera.SetRobotOrientation(headingDeg, 0, 0, 0, 0, 0);

        SwerveModulePosition[] modulePositions = driveState.ModulePositions;
        poseEstimator.updatePose();

        PoseAllocate frontRightPose = frontRightCamera.getRobotPose();
        PoseAllocate rearRightPose = rearRightCamera.getRobotPose();
        PoseAllocate rearLeftPose = rearLeftCamera.getRobotPose();
        PoseAllocate frontLeftPose = frontLeftCamera.getRobotPose();

        if (frontRightPose != null
                && frontRightPose.getPose() != null
                && frontRightPose.getPoseEstimate().tagCount > 0
                && Math.abs(omega) < 2) {
            DrivetrainConstants.drivetrain.addVisionMeasurement(frontRightPose.getPose(), frontRightPose.getTime());

        }

        if (frontLeftPose != null
                && frontLeftPose.getPose() != null
                && frontLeftPose.getPoseEstimate().tagCount > 0
                && Math.abs(omega) < 2) {
            DrivetrainConstants.drivetrain.addVisionMeasurement(frontLeftPose.getPose(), frontLeftPose.getTime());

        }

        if (rearLeftPose != null
                && rearLeftPose.getPose() != null
                && rearLeftPose.getPoseEstimate().tagCount > 0
                && Math.abs(omega) < 2) {
            DrivetrainConstants.drivetrain.addVisionMeasurement(rearLeftPose.getPose(), rearLeftPose.getTime());

        }

        if (rearRightPose != null
                && rearRightPose.getPose() != null
                && rearRightPose.getPoseEstimate().tagCount > 0
                && Math.abs(omega) < 2) {
            DrivetrainConstants.drivetrain.addVisionMeasurement(rearRightPose.getPose(), rearRightPose.getTime());

        }

    }

    private void configureBindings() {
        //Triggers 
        new Trigger(elevator :: getElevatorAboveThreshold).and(RobotModeTriggers.teleop()).onTrue(new ConfigureHologenicDrive(driverController, DrivetrainConstants.drivetrain)).onFalse(ConfigureHologenicDrive(driverController, swerveSubsystem, elevator));
        
        //Operator
        operatorController.y()
            .whileTrue(new PlaceLOne(elevator, swanNeck));
        operatorController.b()
            .whileTrue(new PlaceLTwo(elevator, swanNeck));

        operatorController.a()
            .whileTrue(new PlaceLThree(elevator, swanNeck));

        operatorController.x()
            .whileTrue(new PlaceLFour(elevator, swanNeck).andThen(new RotateElevatorDownPID(elevator).until(elevator :: pidDownAtSetpoint)));

        operatorController.axisLessThan(Axis.kLeftY.value, -0.1).whileTrue(new RaiseSwanNeck(swanNeck, ()-> .1));
        operatorController.axisGreaterThan(Axis.kLeftY.value, 0.1).whileTrue(new RaiseSwanNeck(swanNeck, ()-> -.1));

        operatorController.axisLessThan(Axis.kRightY.value, -0.1).whileTrue(new RotateElevatorBasic(()-> .1, elevator));
        operatorController.axisGreaterThan(Axis.kRightY.value, 0.1).whileTrue(new RotateElevatorBasic(()-> -.1, elevator));

        operatorController.leftBumper().whileTrue(new MoveBack(DrivetrainConstants.drivetrain));

        operatorController.rightBumper().whileTrue(new RotateElevatorDownPID(elevator));
        operatorController.povDown().and(driverController.y()).whileTrue(new RaiseClimberBasic(()-> .15, climber).until(climber:: climberPastZero).unless(climber :: climberPastZero));


        
        //Driver

        driverController.povRight()
                .onTrue(new InstantCommand(()-> CommandScheduler.getInstance().cancelAll()));

        // driverController.b().onTrue(zeroMechanisms);
        
        driverController.start()
                .onTrue(DrivetrainConstants.drivetrain
                        .runOnce(() -> DrivetrainConstants.drivetrain.seedFieldCentric()));

        driverController.leftBumper()
                .onTrue(new posePathfindToReef(frc.robot.commands.auton.posePathfindToReef.reefPole.LEFT,
                        DrivetrainConstants.drivetrain, frontRightCamera, frontLeftCamera));

        driverController.rightBumper()
                .onTrue(new posePathfindToReef(frc.robot.commands.auton.posePathfindToReef.reefPole.RIGHT,
                        DrivetrainConstants.drivetrain, frontRightCamera, frontLeftCamera));

        driverController.y().and(operatorController.povUp())
                .whileTrue(new RaiseClimberBasic(()-> -.15 , climber).until(climber :: climberPastMax).unless(climber :: climberPastMax));
        
        driverController.leftTrigger()
                .whileTrue(new IntakeCoralSequence(swanNeck));

        driverController.rightTrigger()
                .whileTrue(new SpinSwanWheels(swanNeck, ()->.4));
        

    }

    private void setupEventTriggers(){
         new EventTrigger("L3Infinite").whileTrue(new RotateElevatorSafePID(elevator));
         new EventTrigger("FeedThenL3").whileTrue(new FeedThenL3(elevator, swanNeck));
    }

    private void setupNamedCommands() {
        NamedCommands.registerCommand("Field Relative", DrivetrainConstants.drivetrain.runOnce(() -> DrivetrainConstants.drivetrain.seedFieldCentric()));
        NamedCommands.registerCommand("L4", new PlaceLFour(elevator, swanNeck));
        NamedCommands.registerCommand("ElevatorDown", new RotateElevatorDownPID(elevator).until(elevator :: pidDownAtSetpoint));
        NamedCommands.registerCommand("Feed", new IntakeCoralSequence(swanNeck));
        NamedCommands.registerCommand("ZeroMechanisms", zeroMechanisms);
        NamedCommands.registerCommand("L3Infinite", new RaiseSwanNeckPID(()-> IntakeMap.ReefStops.SAFEANGLE, swanNeck).until(swanNeck ::pidAtSetpoint).andThen(new RotateElevatorPID(elevator, ()-> ElevatorMap.L2ROTATION)));
    }

    public void setupPaths() {
        autonChooser.setDefaultOption("Drive Forward", new DriveForwardCommand(swerveSubsystem, 0.5, 5));
        Shuffleboard.getTab(Subsystems.SWERVE_DRIVE.getNetworkTable()).add("Auton Chooser", autonChooser).withSize(2, 1)
                .withProperties(Map.of("position", "0, 0"));
    }


    public void setupDrivetrain() {
        teleOpChooser.setDefaultOption("Holo-Genic Drive", ConfigureHologenicDrive(driverController, swerveSubsystem, elevator));
        teleOpChooser.addOption("Arcade Drive", ConfigureArcadeDrive(driverController, swerveSubsystem));
        teleOpChooser.addOption("Tank Drive", ConfigureTankDrive(driverController, swerveSubsystem));
        teleOpChooser.addOption("Orbit Mode (Beta)", ConfigureOrbitMode(driverController, swerveSubsystem));
        teleOpChooser.addOption("BeyBlade (Maniac)", ConfigureBeyBlade(driverController, swerveSubsystem));
        teleOpChooser.addOption("FODC System (PID)", ConfigureFODC(driverController, swerveSubsystem));

        Shuffleboard.getTab(Subsystems.SWERVE_DRIVE.getNetworkTable()).add("TeleOp Chooser", teleOpChooser)
                .withSize(2, 1)
                .withProperties(Map.of("position", "0, 1"));
    }

    public void setupElevator() {
        // commandChooser.addOption("GoingUP", new GoUpCommand(elevator, 0.1, 1.0));

        Shuffleboard.getTab(Subsystems.SWERVE_DRIVE.getNetworkTable()).add("Command Chooser", commandChooser)
                .withSize(2, 1)
                .withProperties(Map.of("position", "0, 2"));
    }

    // DO NOT REMOVE
    public SubsystemABS[] SafeGuardSystems() {
        return new SubsystemABS[] {
                swerveSubsystem,
                frontRightCamera,
                rearLeftCamera,
                rearRightCamera,
                frontLeftCamera

        };
    }

    // ONLY RUNS IN TEST MODE
    public Object[] TestCommands() {
        return new Object[] {
        };
    }

    public Object[] TestAutonCommands() {
        return new Object[] {
        };
    }

    public Command getAutonomousCommand() {
        return autonChooser.getSelected();
    }

    public Command getTeleOpCommand() {
        return teleOpChooser.getSelected();
    }

    public Command TestSystems() {
        return null;
    }
}
