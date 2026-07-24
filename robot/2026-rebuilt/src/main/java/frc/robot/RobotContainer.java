// Push it
// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.
package frc.robot;

import static edu.wpi.first.units.Units.Meters;
import static edu.wpi.first.units.Units.MetersPerSecond;
import com.pathplanner.lib.auto.AutoBuilder;
import com.pathplanner.lib.auto.NamedCommands;
import com.pathplanner.lib.commands.PathPlannerAuto;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.networktables.GenericEntry;
import edu.wpi.first.wpilibj.shuffleboard.BuiltInLayouts;
import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardLayout;
import edu.wpi.first.wpilibj.DriverStation;
import edu.wpi.first.wpilibj.RobotBase;
import edu.wpi.first.wpilibj.smartdashboard.SendableChooser;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import edu.wpi.first.wpilibj2.command.button.Trigger;
import frc.robot.RobotMap.DrivetrainConstants;
import frc.robot.commands.swerve.BallTracking;
import frc.robot.commands.swerve.HubDriveAUTO;
import frc.robot.subsystems.intake.Intake;
import frc.robot.subsystems.intake.RackIOSim;
import frc.robot.subsystems.intake.RackIOTalonFX;
import frc.robot.subsystems.intake.RollerIO;
import frc.robot.subsystems.intake.RollerIOSim;
import frc.robot.subsystems.intake.RollerIOTalonFX;
import frc.robot.subsystems.intake.Intake.IntakeState;
import frc.robot.subsystems.intake.Intake.RollerState;
import frc.robot.subsystems.intake.RackIO;
import frc.robot.subsystems.feeder.FeederSubsystem;
import frc.robot.subsystems.feeder.FeederSubsystem.feeder_state;
import frc.robot.subsystems.feeder.FeederIO;
import frc.robot.subsystems.feeder.FeederIOSim;
import frc.robot.subsystems.feeder.FeederIOTalonFX;
import frc.robot.subsystems.shooter.hood.ShooterHoodSubsystem.shooterhood_state;
import frc.robot.subsystems.shooter.wheels.Flywheel;
import frc.robot.subsystems.shooter.wheels.FlywheelIO;
import frc.robot.subsystems.shooter.wheels.FlywheelIOSim;
import frc.robot.subsystems.shooter.wheels.FlywheelIOTalonFX;
import frc.robot.subsystems.shooter.wheels.Flywheel.shooter_state;
import frc.robot.subsystems.shooter.hood.ShooterHoodIO;
import frc.robot.subsystems.shooter.hood.ShooterHoodIOSim;
import frc.robot.subsystems.shooter.hood.ShooterHoodIOTalonFX;
import frc.robot.subsystems.shooter.hood.ShooterHoodSubsystem;
import frc.robot.subsystems.spindexer.SpindexerIOTalonFX;
import frc.robot.subsystems.spindexer.SpindexerSubsystem;
import frc.robot.subsystems.spindexer.SpindexerSubsystem.spindexer_state;
import frc.robot.subsystems.spindexer.SpindexerIO;
import frc.robot.subsystems.spindexer.SpindexerIOSim;
import frc.robot.sim.RebuiltSimManager;
import com.pathplanner.lib.path.PathConstraints;

import org.json.simple.parser.ParseException;
import org.littletonrobotics.junction.Logger;

import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.subsystems.swerve.generated.TunerConstants;
import frc.robot.utils.LimelightWrapper;
import frc.robot.utils.PitTesting;
import frc.robot.rtu.RTUManager;
import frc.robot.utils.AutoSweeper;
import limelight.networktables.LimelightSettings.ImuMode;
import static edu.wpi.first.units.Units.RotationsPerSecond;

import java.io.IOException;
import java.util.List;


import static edu.wpi.first.units.Units.Rotations;

public class RobotContainer extends ControllerBindings {
  // Singleton accessor so external code (DiagnosticServer) can command
  // shooter/hood.
  private static RobotContainer instance;

  private final CommandSwerveDrivetrain drivetrain = DrivetrainConstants.createDrivetrain();
  // Limelight naming conventions are based on physical inventory system, hence
  // "limelight-two" and "limelight-five" represent our second and fifth
  // limelights respectively.
  private final LimelightWrapper llMain = new LimelightWrapper("limelight-two", true);
  private final LimelightWrapper llBackup = new LimelightWrapper("limelight-five", true);

  private static java.io.File usb = RobotMap.PitConstants.usb;


  private final CommandXboxController controller = new CommandXboxController(0);
  private final CommandXboxController operaterController = new CommandXboxController(1);

  private final Telemetry telemetry =
      new Telemetry(TunerConstants.kSpeedAt12Volts.in(MetersPerSecond));

  private final Intake intakeSubsystem;
  private final FeederSubsystem feederSubsystem;
  private final ShooterHoodSubsystem shooterHood;
  private final Flywheel shooterWheels;
  private final SpindexerSubsystem spindexer;

  // --- APIs used by the diagnostic server / UI to command shooter/hood ---
  private final AutoSweeper autoSweeper;


  // Simulation
  private RebuiltSimManager simManager;



  private final RTUManager rtumanager = new RTUManager();


  private final SendableChooser<Command> autoChooser;


  public static RobotContainer getInstance() {
    return instance;
  }

  public CommandXboxController getDriverController() {
    return controller;
  }

  public CommandXboxController getOperatorController() {
    return operaterController;
  }

  public Intake getIntakeSubsystem() {
    return intakeSubsystem;
  }

  public ShooterHoodSubsystem getShooterHood() {
    return shooterHood;
  }

  public Flywheel getShooterWheels() {
    return shooterWheels;
  }

  public FeederSubsystem getFeederSubsystem() {
    return feederSubsystem;
  }

  public SpindexerSubsystem getSpindexer() {
    return spindexer;
  }

  public CommandSwerveDrivetrain getDrivetrain() {
    return drivetrain;
  }

  public LimelightWrapper getLimelightBackup() {
    return llBackup;
  }

  public LimelightWrapper getLimelightMain() {
    return llMain;
  }

  public RobotContainer() {
    instance = this;
    switch (RobotMap.getRobotMode()) {
      case REAL:
        spindexer = new SpindexerSubsystem(new SpindexerIOTalonFX());
        feederSubsystem = new FeederSubsystem(new FeederIOTalonFX());
        intakeSubsystem = new Intake(new RackIOTalonFX(), new RollerIOTalonFX());
        shooterHood = new ShooterHoodSubsystem(new ShooterHoodIOTalonFX(),
            () -> drivetrain.getDistanceToHub().in(Meters),
            () -> drivetrain.getDistanceToCorner().in(Meters));
        shooterWheels =
            new Flywheel(new FlywheelIOTalonFX(), () -> drivetrain.getDistanceToHub().in(Meters),
                () -> drivetrain.getDistanceToCorner().in(Meters));
        break;
      case SIM:
        spindexer = new SpindexerSubsystem(new SpindexerIOSim());
        feederSubsystem = new FeederSubsystem(new FeederIOSim());
        intakeSubsystem = new Intake(new RackIOSim(), new RollerIOSim());
        shooterHood = new ShooterHoodSubsystem(new ShooterHoodIOSim(),
            () -> drivetrain.getDistanceToHub().in(Meters),
            () -> drivetrain.getDistanceToCorner().in(Meters));
        shooterWheels =
            new Flywheel(new FlywheelIOSim(), () -> drivetrain.getDistanceToHub().in(Meters),
                () -> drivetrain.getDistanceToCorner().in(Meters));
        break;
      case REPLAY:
        spindexer = new SpindexerSubsystem(new SpindexerIO() {});
        feederSubsystem = new FeederSubsystem(new FeederIO() {});
        intakeSubsystem = new Intake(new RackIO() {}, new RollerIO() {});
        shooterHood = new ShooterHoodSubsystem(new ShooterHoodIO() {},
            () -> drivetrain.getDistanceToHub().in(Meters),
            () -> drivetrain.getDistanceToCorner().in(Meters));
        shooterWheels =
            new Flywheel(new FlywheelIO() {}, () -> drivetrain.getDistanceToHub().in(Meters),
                () -> drivetrain.getDistanceToCorner().in(Meters));
        break;
      default:
        throw new IllegalStateException("Unexpected value: " + RobotMap.getRobotMode());
    }

    autoSweeper = new AutoSweeper(rps -> {
      try {
        shooterWheels.setStateCommand(shooter_state.TEST).execute();
        shooterWheels.setVelocity(RotationsPerSecond.of(rps));
      } catch (Exception e) {
        e.printStackTrace();
      }
    }, pos -> {
      try {
        shooterHood.setStateCommand(shooterhood_state.TEST).execute();
        shooterHood.setAngle(Rotations.of(pos)); // pos is already in rotations (0-30)
      } catch (Exception e) {
        e.printStackTrace();
      }
    });


    llMain.getSettings().withImuMode(ImuMode.ExternalImu).save();
    setupDriveBindings(controller);
    setupOperatorBindings(operaterController);
    configureRootTests();
    if (RobotBase.isReal()) {
      PitTesting.createDashboard();
    }
    new Trigger(drivetrain::withinTrench).and(DriverStation::isTeleop)
        .onTrue(shooterHood.setStateCommand(shooterhood_state.IN));
    registerNamedCommands();
    SmartDashboard.putBoolean("UseMainLL", true);
    drivetrain.registerTelemetry(telemetry::telemeterize);

    // Set up auto chooser
    autoChooser = AutoBuilder.buildAutoChooser();

    try {
      // Ball tracking autos
      registBallTrackingAuto("Dev-FD-RightMidFieldDoublepass",
          "Internal-FD-RightMidFieldDoublepass-Part1",
          List.of("Internal-FD-RightMidFieldDoublepass-Part2",
              "Internal-FD-RightMidFieldDoublepass-Part3"));
      registBallTrackingAuto("Dev-FD-MidIntakeToLeftBump", "Internal-FD-MidIntakeToLeftBump-Part1",
          List.of("Internal-FD-MidIntakeToLeftBump-Part2"));
      registBallTrackingAuto("Dev-FD-RightSneakDoublepass",
          "Internal-FD-RightSneakDoublepass-Part1", List.of(
              "Internal-FD-RightSneakDoublepass-Part2", "Internal-FD-RightSneakDoublepass-Part3"));

      // Mirrored autons
      autoChooser.addOption("Comp-LeftMidfieldDoublePass",
          new PathPlannerAuto("Comp-RightMidfieldDoublepass", true));
      autoChooser.addOption("Dev-MidIntakeToRightBump",
          new PathPlannerAuto("Comp-MidIntakeToLeftBump", true)); // TESTING - DO NOT USE

      autoChooser.addOption("Comp-LeftSotmMidfieldDoublepass",
          new PathPlannerAuto("Comp-RightSotmMidfieldDoublepass", true));



    } catch (Exception e) {
      e.printStackTrace();
    }


    SmartDashboard.putData("Auto Chooser", autoChooser);
  }

  private void registBallTrackingAuto(String autoName, String part1Name,
      List<String> postTrackingParts) throws IOException, ParseException {

    Command autoCommand = AutoBuilder.buildAuto(part1Name);

    for (String part : postTrackingParts) {
      Pose2d returnPose =
          PathPlannerAuto.getPathGroupFromAutoFile(part).get(0).getStartingHolonomicPose().get();
      autoCommand = autoCommand.andThen(new BallTracking(drivetrain).withTimeout(3.0))
          .andThen(
              AutoBuilder.pathfindToPose(returnPose, new PathConstraints(2.0, 2.0, 360.0, 360.0)))
          .andThen(AutoBuilder.buildAuto(part));
    }

    autoChooser.addOption(autoName, autoCommand);
  }


  public synchronized void setHoodPosition(double position) {
    try {
      // position is in rotations (0 to 30 rotations)
      shooterHood.setAngle(Rotations.of(position));
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  /** Backwards-compatible API: set hood angle in degrees (360deg = 1 rotation). */
  public synchronized void setHoodAngleDeg(double deg) {
    try {
      shooterHood.setAngle(Rotations.of(deg / 360.0));
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  public synchronized void setShooterVelocityRps(double rps) {
    try {
      shooterWheels.setVelocity(RotationsPerSecond.of(rps));
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  /**
   * Start an automatic sweep of shooter velocities from min..max (inclusive) using step, commanding
   * hoodDeg for each step and holding for holdMs milliseconds. This runs in a background thread and
   * can be stopped with stopAutoSweep().
   */
  public synchronized void startAutoSweep(double min, double max, double step, double hoodDeg,
      int holdMs) {
    autoSweeper.start(min, max, step, hoodDeg, holdMs);
  }

  public synchronized void stopAutoSweep() {
    autoSweeper.stop();
  }

  public synchronized boolean isAutoRunning() {
    return autoSweeper.isRunning();
  }

  public synchronized double getAutoCurrent() {
    return autoSweeper.getCurrent();
  }

  /**
   * Start a dynamic auto-sweep driven by the diagnostic dashboard's telemetry values. Puts shooter
   * wheels and hood into TEST state while the sweep runs and restores them when it finishes.
   *
   * @param holdMs milliseconds to hold each supplier sample
   */
  public synchronized void startAutoSweepFromDiagnostic(int holdMs) {
    // enter test mode immediately
    shooterWheels.setState(shooter_state.TEST);
    shooterHood.setState(shooterhood_state.TEST);

    autoSweeper.startDynamic(
        // shooter velocity supplier (RPS) comes from TelemetryPublisher
        () -> frc.robot.utils.RTU.TelemetryPublisher.getShooterVelocityRps(),
        // hood angle supplier (degrees) comes from TelemetryPublisher
        () -> frc.robot.utils.RTU.TelemetryPublisher.getHoodAngleDeg(),
        // enter test mode (redundant but safe)
        () -> {
          shooterWheels.setState(shooter_state.TEST);
          shooterHood.setState(shooterhood_state.TEST);
        },
        // exit test mode: restore reasonable idle states
        () -> {
          shooterWheels.setState(shooter_state.IDLE);
          shooterHood.setState(shooterhood_state.IN);
        }, holdMs);
  }


  public void updateLocalization() {
    if (llMain.isConnected() && SmartDashboard.getBoolean("UseMainLL", true)) {
      llMain.updateLocalizationLimelight(drivetrain);
      // set backup to viewfinder pipeline when not in use
      if (llBackup.getData().pipelineData.getCurrentPipelineIndex() != 1)
        llBackup.getSettings().withPipelineIndex(1);
      SmartDashboard.putString("Active Limelight", "MAIN");
    } else {
      llBackup.updateLocalizationLimelight(drivetrain);
      // ensure atag pipeline is selected when llbackup is used for localization
      if (llBackup.getData().pipelineData.getCurrentPipelineIndex() != 0)
        llBackup.getSettings().withPipelineIndex(0);
      SmartDashboard.putString("Active Limelight", "BACKUP");
    }
  }

  public void publishTelemetry() {
    try {
      var vel = shooterWheels.getVelocity();
      var hood = shooterHood.getPosition();
      var dist = drivetrain.getDistanceToVirtualHub();
      frc.robot.utils.RTU.TelemetryPublisher.publish(vel, hood, dist);
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  public void initSimulation() {
    simManager = new RebuiltSimManager(drivetrain, intakeSubsystem, feederSubsystem, shooterWheels,
        shooterHood, spindexer);
    Logger.recordOutput("Sim/State", "Ready");
    drivetrain.resetPose(RebuiltSimManager.STARTING_POSE);
  }

  public void updateSimulation() {
    if (simManager != null) {
      simManager.periodic();
    }
  }

  public Command getAutonomousCommand() {
    return autoChooser.getSelected();
  }

  private void configureRootTests() {
    // Keep this method for compatibility but delegate to RTUManager
    rtumanager.registerSubsystem();

    rtumanager.setSafetyCheck(() -> {
      if (!controller.getHID().isConnected()) {
        return "Joystick is not connected";
      }

      boolean triggersOk =
          controller.getLeftTriggerAxis() >= 0.5 && controller.getRightTriggerAxis() >= 0.5;

      boolean xyOk = controller.getHID().getXButton() && controller.getHID().getYButton();

      if (!triggersOk && !xyOk) {
        return "Did not receive start command from gamepads, please press both triggers to continue the tests";
      }

      return null; // Safe to run
    });
  }

  public void runRootTests() {
    rtumanager.runAll();
  }

  public void updateRootTests() {


    rtumanager.periodic();
  }

  public void idleSubsystems() {
    intakeSubsystem.setRackState(IntakeState.DEFAULT);
    intakeSubsystem.setRollerState(RollerState.OFF);
    shooterWheels.setState(shooter_state.IDLE);
    shooterHood.setState(shooterhood_state.IN);
    spindexer.setState(spindexer_state.STOP);
    feederSubsystem.setState(feeder_state.STOP);
  }


  public void registerNamedCommands() {
    NamedCommands.registerCommand("Extend Hopper",
        intakeSubsystem.setIntakeStateCommand(IntakeState.EXTENDED));
    NamedCommands.registerCommand("Extend Intake",
        intakeSubsystem.setIntakeStateCommand(IntakeState.EXTENDED));
    NamedCommands.registerCommand("Retract Intake",
        intakeSubsystem.setIntakeStateCommand(IntakeState.DEFAULT));
    NamedCommands.registerCommand("Run Rollers",
        intakeSubsystem.setRollerStateCommand(RollerState.ON));
    NamedCommands.registerCommand("Stop Rollers",
        intakeSubsystem.setRollerStateCommand(RollerState.OFF));
    NamedCommands.registerCommand("Start Shooter Spin",
        shooterWheels.setStateCommand(shooter_state.SHOOTING)
            .alongWith(shooterHood.setStateCommand(shooterhood_state.SHOOTING)));
    NamedCommands.registerCommand("Stop Shooter Spin",
        shooterWheels.setStateCommand(shooter_state.IDLE)
            .alongWith(shooterHood.setStateCommand(shooterhood_state.IN))
            .alongWith(spindexer.setStateCommand(spindexer_state.STOP))
            .alongWith(feederSubsystem.setStateCommand(feeder_state.STOP)));
    NamedCommands.registerCommand("End Shooter Spin",
        shooterWheels.setStateCommand(shooter_state.IDLE)
            .alongWith(shooterHood.setStateCommand(shooterhood_state.IN))
            .alongWith(spindexer.setStateCommand(spindexer_state.STOP))
            .alongWith(feederSubsystem.setStateCommand(feeder_state.STOP)));
    NamedCommands.registerCommand("Run Shooter",
        shooterWheels.setStateCommand(shooter_state.SHOOTING)
            .alongWith(feederSubsystem.setStateCommand(feeder_state.PRUN))
            .alongWith(spindexer.setStateCommand(spindexer_state.RUN))
            .alongWith(shooterHood.setStateCommand(shooterhood_state.SHOOTING)));
    NamedCommands.registerCommand("Shooting",
        shooterWheels.setStateCommand(shooter_state.SHOOTING)
            .alongWith(feederSubsystem.setStateCommand(feeder_state.PRUN))
            .alongWith(spindexer.setStateCommand(spindexer_state.RUN))
            .alongWith(shooterHood.setStateCommand(shooterhood_state.SHOOTING)));
    NamedCommands.registerCommand("Start Passing Spin",
        shooterWheels.setStateCommand(shooter_state.PASSING)
            .alongWith(shooterHood.setStateCommand(shooterhood_state.PASSING)));
    NamedCommands.registerCommand("Passing",
        shooterWheels.setStateCommand(shooter_state.PASSING)
            .alongWith(feederSubsystem.setStateCommand(feeder_state.PRUN))
            .alongWith(spindexer.setStateCommand(spindexer_state.RUN))
            .alongWith(shooterHood.setStateCommand(shooterhood_state.PASSING)));
    NamedCommands.registerCommand("Auto Hub Drive", new HubDriveAUTO(drivetrain));
  }


  private final ShuffleboardLayout llLayout = Shuffleboard.getTab("Pit Testing")
      .getLayout("Limelight Health", BuiltInLayouts.kList).withSize(2, 1).withPosition(4, 5);
  private GenericEntry llBackupConnect = llLayout.add("LL Backup Connected", false).getEntry();
  private GenericEntry llMainConnect = llLayout.add("LL Main Connected", false).getEntry();


  public void limelightConnection() {
    llMainConnect.setBoolean(llMain.isConnected());
    llBackupConnect.setBoolean(llBackup.isConnected());
  }

  private final GenericEntry testLayout =
      Shuffleboard.getTab("Pit Testing").add("storage", false).getEntry();
  private final GenericEntry displayLayout =
      Shuffleboard.getTab("Pit Testing").add("storage info", "").getEntry();

  public void usbStorage() {

    boolean mounted = usb.exists() && usb.isDirectory();
    long totalBytes = usb.getTotalSpace();
    long freeBytes = usb.getUsableSpace();


    boolean storageOk = mounted && freeBytes >= RobotMap.PitConstants.STORAGE_ACCEPTABLE_BYTES;
    String label = !mounted ? "NO DRIVE"
        : String.format("%.1f GB free / %.1f GB total", freeBytes / 1e9, totalBytes / 1e9);

    displayLayout.setString("Logs Flash Drive: " + label);
    testLayout.setBoolean(storageOk);
  }


}
