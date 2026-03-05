// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.
package frc.robot;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.Commands;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import frc.robot.RobotMap.DrivetrainConstants;
import frc.robot.RobotMap.ShooterConstants;
import frc.robot.commands.swerve.HubDrive;
// import frc.robot.commands.swerve.PassingDrive;
// import frc.robot.commands.swerve.PathfindToPose;
import frc.robot.commands.swerve.TeleopSwerve;
import frc.robot.subsystems.intake.IntakeSubsystem;
import frc.robot.subsystems.intake.RollersSubsystem;
import frc.robot.subsystems.intake.IntakeSubsystem.IntakeState;
import frc.robot.subsystems.intake.RollersSubsystem.RollerState;
import frc.robot.subsystems.feeder.Feeder;
import frc.robot.subsystems.feeder.Feeder.feeder_state;
import frc.robot.subsystems.shooter.ShooterHood;
import frc.robot.subsystems.shooter.ShooterWheels;
import frc.robot.subsystems.shooter.ShooterHood.shooterhood_state;
import frc.robot.subsystems.shooter.ShooterWheels.shooter_state;
import frc.robot.subsystems.spindexer.Spindexer;
import frc.robot.subsystems.spindexer.Spindexer.spindexer_state;
import frc.robot.sim.RebuiltSimManager;
import frc.robot.subsystems.testing.ShooterTestSubsystem;

import static edu.wpi.first.units.Units.MetersPerSecond;

import org.littletonrobotics.junction.Logger;

import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.subsystems.swerve.generated.TunerConstants;
import frc.robot.utils.LimelightWrapper;
import frc.robot.utils.RTU.RootTestingUtility;
import limelight.Limelight;
import limelight.networktables.LimelightSettings.ImuMode;
import static edu.wpi.first.units.Units.RotationsPerSecond;
import static edu.wpi.first.units.Units.Rotations;
import java.util.concurrent.Executors;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Future;

public class RobotContainer {

    // Singleton accessor so external code (DiagnosticServer) can command shooter/hood.
    private static RobotContainer instance;

    private final CommandSwerveDrivetrain drivetrain = DrivetrainConstants.createDrivetrain();
    //Limelight naming conventions are based on physical inventory system, hence "limelight-two" and "limelight-five" represent our second and fifth limelights respectively.
    private final LimelightWrapper ll4 = new LimelightWrapper("limelight-two", true);
    private final LimelightWrapper ll3 = new LimelightWrapper("limelight-five", false);
    private final Limelight ll_intake = new Limelight("ll-intake");

    private final CommandXboxController controller = new CommandXboxController(0);
    private final CommandXboxController operaterController = new CommandXboxController(1);

    private final Telemetry telemetry = new Telemetry(TunerConstants.kSpeedAt12Volts.in(MetersPerSecond));

    private final IntakeSubsystem intakeSubsystem = new IntakeSubsystem();

    private final RollersSubsystem rollersSubsystem = RollersSubsystem.getInstance();

    private final Feeder feederSubsystem = new Feeder();

    private final ShooterHood shooterHood = new ShooterHood(drivetrain);
    private final ShooterWheels shooterWheels = new ShooterWheels(drivetrain);

    // Test-time swerve configuration: multiplier to slow swerve and flag to disable
    private final double swerveMultiplier = 0.5; // make swerve very slow during tests
    private boolean swerveEnabled = true;

    // Local testing subsystem (contains @RobotAction tests used by RootTestingUtility)
    // private final TestingSubsystem testingSubsystem = new TestingSubsystem();
    private final Spindexer spinDexer = new Spindexer();

    // Simulation
    private RebuiltSimManager simManager;

    // Shooter RTU test subsystem (created after spinDexer is available)
    private final ShooterTestSubsystem shooterTestSubsystem = new ShooterTestSubsystem(shooterWheels, spinDexer, feederSubsystem);

    private final RootTestingUtility rootTester = new RootTestingUtility();

    public RobotContainer() {
        instance = this;
        ll4.getSettings().withImuMode(ImuMode.ExternalImu).save();
        //configureBindingsDriver(); // commented out for test bindings
        testBindings(); // use test bindings as requested (swerves disabled)
        // configureBindingsOperator();

        configureRootTests();
        drivetrain.registerTelemetry(telemetry::telemeterize);
    }

    /** Get the active RobotContainer instance. May be null before construction. */
    public static RobotContainer getInstance() {
        return instance;
    }

    // --- APIs used by the diagnostic server / UI to command shooter/hood ---
    private final ExecutorService autoExecutor = Executors.newSingleThreadExecutor(r -> new Thread(r, "auto-sweep"));
    private volatile boolean autoRunning = false;
    private volatile double autoCurrent = 0.0;
    private volatile Future<?> autoFuture = null;

    public synchronized void setShooterVelocityRps(double rps) {
        try {
            shooterWheels.setVelocity(RotationsPerSecond.of(rps));
        } catch (Exception e) {
            // best-effort
        }
    }

    public synchronized void setHoodAngleDeg(double deg) {
        try {
            // convert degrees -> rotations (360 deg = 1 rotation)
            shooterHood.setAngle(Rotations.of(deg / 360.0));
        } catch (Exception e) {
            // best-effort
        }
    }

    /**
     * Start an automatic sweep of shooter velocities from min..max (inclusive) using step,
     * commanding hoodDeg for each step and holding for holdMs milliseconds. This runs
     * in a background thread and can be stopped with stopAutoSweep().
     */
    public synchronized void startAutoSweep(double min, double max, double step, double hoodDeg, int holdMs) {
        // stop existing sweep
        stopAutoSweep();
        autoRunning = true;
        autoFuture = autoExecutor.submit(() -> {
            try {
                for (double v = min; v <= max && autoRunning; v += step) {
                    autoCurrent = v;
                    setShooterVelocityRps(v);
                    setHoodAngleDeg(hoodDeg);
                    try { Thread.sleep(Math.max(10, holdMs)); } catch (InterruptedException ie) { break; }
                }
            } finally {
                autoRunning = false;
                autoFuture = null;
            }
        });
    }

    public synchronized void stopAutoSweep() {
        autoRunning = false;
        if (autoFuture != null) {
            autoFuture.cancel(true);
            autoFuture = null;
        }
    }

    public synchronized boolean isAutoRunning() { return autoRunning; }

    public synchronized double getAutoCurrent() { return autoCurrent; }

    public void updateLocalization() {
        if (ll4.getNTTable().containsKey("tv")) {
            ll4.updateLocalizationLimelight(drivetrain);
        } else {
            ll3.updateLocalizationLimelight(drivetrain);
        }
    }

    /** Publish a small set of live telemetry values for the RTU dashboard. Called from Robot.robotPeriodic(). */
    public void publishTelemetry() {
        try {
            var vel = shooterWheels.getVelocity();
            var hood = shooterHood.getPosition();
            var dist = drivetrain.getDistanceToVirtualHub();
            frc.robot.utils.RTU.TelemetryPublisher.publish(vel, hood, dist);
        } catch (Exception e) {
            // swallow — telemetry is best-effort
        }
    }

    // private void configureBindingsOperator(){
    //   //Manual way to extend and retract the intake
    //   operaterController.rightTrigger()
    //       .onTrue(intakeSubsystem.setMotorPower(0.1))
    //       .onFalse(intakeSubsystem.setMotorPower( 0.0));
    //   operaterController.rightBumper()
    //       .onTrue(intakeSubsystem.setMotorPower(-0.1))
    //       .onFalse(intakeSubsystem.setMotorPower( 0.0));
    //   // Manual way to change the angle of the shooter hood
    //   operaterController.leftTrigger()
    //     .onTrue(shooterHood.setMotorPower(0.1))
    //     .onFalse(shooterHood.setMotorPower(0.0));
    //   operaterController.leftBumper()
    //     .onTrue(shooterHood.setMotorPower(-0.1))
    //     .onFalse(shooterHood.setMotorPower(0.0));
    //   //Add multiplier to hood angle
    //   operaterController.a()
    //     .onTrue(new InstantCommand(()-> shooterHood.updateHoodAngleMultiplier(.01)));
    //   operaterController.b()
    //     .onTrue(new InstantCommand(()-> shooterHood.updateHoodAngleMultiplier(-.01)));
    // }
    // private void configureBindingsDriver() {
    //   //Button to reset field centric direction (backup if vision fails)
    //   controller.start()
    //      .onTrue(new InstantCommand(drivetrain::seedFieldCentric));
    //   controller.povUp()
    //      .whileTrue(new PathfindToPose(drivetrain, new Pose2d(2.0, 2.0, new Rotation2d())));
    //   // -------- INTAKE CONTROLS --------- 
    //   //Button to extend intake and run rollers
    //   controller.leftTrigger()
    //       .onTrue(intakeSubsystem.setIntakeStateCommand(IntakeState.EXTENDED)
    //       .andThen(rollersSubsystem.RollersCommand(RollerState.ON)))
    //       .onFalse(rollersSubsystem.RollersCommand(RollerState.OFF));
    //   //Button to retract intake
    //   controller.leftBumper()
    //       .onTrue(intakeSubsystem.setIntakeStateCommand(IntakeState.DEFAULT));
    //   // Default drive command: field-centric swerve with left stick + right stick rotation
    //   if (swerveEnabled) {
    //     drivetrain.setDefaultCommand(new TeleopSwerve(drivetrain, controller, swerveMultiplier));
    //   } else {
    //     // Swerve disabled for test mode: bind a no-op command that *does* require drivetrain
    //     // so nothing else can steal it during tests.
    //     drivetrain.setDefaultCommand(Commands.runOnce(() -> {}, drivetrain));
    //   }
    //   // M key (Right bumper): intake rollers
    //   controller.rightBumper()
    //       .whileTrue(rollersSubsystem.RollersCommand(RollerState.ON))
    //       .onFalse(rollersSubsystem.RollersCommand(RollerState.OFF));
    //   // Hood aiming: A = aim down, B = aim up (ShooterSim adjusts angle at fixed rate)
    //   if(Robot.isSimulation()){
    //   controller.a()
    //       .onTrue(shooterHood.setStateCommand(shooterhood_state.AIMING_DOWN))
    //       .onFalse(shooterHood.setStateCommand(shooterhood_state.IN));
    //   controller.b()
    //       .onTrue(shooterHood.setStateCommand(shooterhood_state.AIMING_UP))
    //       .onFalse(shooterHood.setStateCommand(shooterhood_state.IN)); 
    //   }
    //Button to shoot from against trench side
    // controller.y()
    //   .onTrue(Commands.sequence(
    //     feederSubsystem.setStateCommand(feeder_state.RUN),
    //     spinDexer.setStateCommand(spindexer_state.RUN),
    //     shooterHood.setStateCommand(shooterhood_state.HALFCOURT),
    //     shooterWheels.setStateCommand(shooter_state.HALFCOURT)))
    //   .onFalse(Commands.sequence(
    //     feederSubsystem.setStateCommand(feeder_state.STOP),
    //     spinDexer.setStateCommand(spindexer_state.STOP),
    //     shooterWheels.setStateCommand(shooter_state.IDLE),
    //     shooterHood.setStateCommand(shooterhood_state.IN)));
    //Button to shoot from against hub
    // controller.x()
    //   .onTrue(Commands.sequence(
    //     feederSubsystem.setStateCommand(feeder_state.RUN),
    //     spinDexer.setStateCommand(spindexer_state.RUN),
    //     shooterWheels.setStateCommand(shooter_state.LAYUP),
    //     shooterHood.setStateCommand(shooterhood_state.LAYUP)))
    //   .onFalse(Commands.sequence(
    //     feederSubsystem.setStateCommand(feeder_state.STOP),
    //     spinDexer.setStateCommand(spindexer_state.STOP),
    //     shooterWheels.setStateCommand(shooter_state.IDLE),
    //     shooterHood.setStateCommand(shooterhood_state.IN)));
    //   controller.x().onTrue(shooterHood.setStateCommand(shooterhood_state.TEST).andThen(shooterWheels.setStateCommand(shooter_state.TEST)));
    //   controller.y().onTrue(feederSubsystem.commandRun().andThen(spinDexer.setStateCommand(spindexer_state.RUN))).onFalse(feederSubsystem.commandStop().andThen(spinDexer.setStateCommand(spindexer_state.STOP)));
    //   // If out of neutral zone, face hub and ready shoot
    //   controller.povRight().and(()->!ShooterConstants.neutralZone.contains(drivetrain.getState().Pose.getTranslation())).whileTrue(
    //     Commands.sequence(
    //       shooterHood.setStateCommand(shooterhood_state.SHOOTING), 
    //       shooterWheels.setStateCommand(shooter_state.SHOOTING)
    //     ).alongWith(new HubDrive(drivetrain, controller)))
    //   .onFalse(
    //     Commands.sequence(
    //       shooterHood.setStateCommand(shooterhood_state.OUT), 
    //       shooterWheels.setStateCommand(shooter_state.IDLE)
    //     ));
    //   // If in neutral zone, face outpost and ready shoot (passing shot)
    //   controller.povRight().and(()->ShooterConstants.neutralZone.contains(drivetrain.getState().Pose.getTranslation())).whileTrue(
    //      Commands.sequence(
    //       shooterHood.setStateCommand(shooterhood_state.PASSING), 
    //       shooterWheels.setStateCommand(shooter_state.PASSING)
    //     ).alongWith(new PassingDrive(drivetrain, controller)))
    //   .onFalse(
    //     Commands.sequence(
    //       shooterHood.setStateCommand(shooterhood_state.OUT), 
    //       shooterWheels.setStateCommand(shooter_state.IDLE)
    //     ));
    //   //Button to fire, if swerve is aimed and shooter is at speed.
    //   controller.rightTrigger().and(HubDrive::pidAtSetpoint).and(shooterWheels::atSetpoint).whileTrue(
    //     Commands.sequence(
    //     feederSubsystem.setStateCommand(feeder_state.RUN),
    //     spinDexer.setStateCommand(spindexer_state.RUN)
    //     )
    //   ).onFalse(
    //     Commands.sequence(
    //     feederSubsystem.setStateCommand(feeder_state.STOP),
    //     spinDexer.setStateCommand(spindexer_state.STOP)
    //     )
    //   );
    // }
    /**
     * Test-only bindings per user request. - Disables swerve default driving -
     * D-pad up/down control hood angle (slow) - X runs shooter velocity using
     * interpolation table while held - Right trigger simply shoots
     * (wheels+hood+feeder+spindexer) while held
     */
    private void testBindings() {
        // Disable swerve for this test scenario
        swerveEnabled = true;

        if (swerveEnabled) {
        drivetrain.setDefaultCommand(new TeleopSwerve(drivetrain, controller, swerveMultiplier));
      } else {
        // Swerve disabled for test mode: bind a no-op command that *does* require drivetrain
        // so nothing else can steal it during tests.
        drivetrain.setDefaultCommand(Commands.runOnce(() -> {}, drivetrain));
      }
        // D-pad up/down: manually jog hood angle slowly
        controller.povUp().onTrue(shooterHood.resetHoodAngle());

        controller.povDown()
                .whileTrue(shooterHood.setMotorPower(-0.05))
                .onFalse(shooterHood.setMotorPower(0.0));


        // X: run shooter velocity using interpolation table while held; stop on release
        // controller.x()
        //   .whileTrue(Commands.run(() -> shooterWheels.setState(shooter_state.LAYUP)))
        //   .onFalse(Commands.runOnce(() -> shooterWheels.setState(shooter_state.IDLE)));
        // Right trigger: shoot (wheels + hood + feeder + spindexer) while held, stop on release
        controller.rightTrigger()
                .whileTrue(Commands.sequence(
                        shooterWheels.setStateCommand(shooter_state.LAYUP),
                        shooterHood.setStateCommand(shooterhood_state.SHOOTING),
                        feederSubsystem.setStateCommand(feeder_state.RUN),
                        spinDexer.setStateCommand(spindexer_state.RUN)
                ))
                .onFalse(Commands.sequence(
                        feederSubsystem.setStateCommand(feeder_state.STOP),
                        spinDexer.setStateCommand(spindexer_state.STOP),
                        shooterWheels.setStateCommand(shooter_state.IDLE),
                        shooterHood.setStateCommand(shooterhood_state.IN)
                ));

        controller.x().onTrue(shooterHood.setStateCommand(shooterhood_state.TEST).andThen(shooterWheels.setStateCommand(shooter_state.TEST)));
        controller.y().onTrue(feederSubsystem.commandRun().andThen(spinDexer.setStateCommand(spindexer_state.RUN))).onFalse(feederSubsystem.commandStop().andThen(spinDexer.setStateCommand(spindexer_state.STOP)));
        controller.a().onTrue(Commands.parallel(
          shooterWheels.setStateCommand(shooter_state.IDLE),
          feederSubsystem.setStateCommand(feeder_state.STOP)
        ));

  
    }

    /**
     * Called from Robot.simulationInit().
     */
    public void initSimulation() {
        simManager = new RebuiltSimManager(drivetrain, rollersSubsystem,
                intakeSubsystem, feederSubsystem, shooterWheels, shooterHood, spinDexer);
        Logger.recordOutput("Sim/State", "Ready");
        drivetrain.resetPose(RebuiltSimManager.STARTING_POSE);
    }

    /**
     * Called from Robot.simulationPeriodic().
     */
    public void updateSimulation() {
        if (simManager != null) {
            simManager.periodic();
        }
    }

    public Command getAutonomousCommand() {
        return Commands.print("No autonomous command configured");
    }

    // ── Root Testing Utility ──────────────────────────────────
    /**
     * Register every subsystem that contains @RobotAction methods. Called once
     * from the constructor.
     */
    private void configureRootTests() {
        // Register only the shooter profile test subsystem so it is the only test that will run
        rootTester.registerSubsystem(shooterTestSubsystem);

        rootTester.setSafetyCheck(() -> {
            if (!controller.getHID().isConnected()) {
                return "Joystick is not connected";
            }

            // Primary start command: both triggers held past threshold
            boolean triggersOk = controller.getLeftTriggerAxis() >= 0.5 && controller.getRightTriggerAxis() >= 0.5;

            // Alternate start command: X + Y buttons pressed simultaneously (convenience for some controllers)
            boolean xyOk = controller.getHID().getXButton() && controller.getHID().getYButton();

            if (!triggersOk && !xyOk) {
                return "Did not receive start command from gamepads, please press both triggers to continue the tests";
            }

            return null; // Safe to run
        });
    }

    /**
     * Called from Robot.testInit(). Discovers and runs all @RobotAction tests.
     */
    public void runRootTests() {
        rootTester.runAll();
    }

    /**
     * Called from Robot.testPeriodic(). Keeps dashboard data fresh.
     */
    public void updateRootTests() {
        rootTester.periodic();
    }
}
