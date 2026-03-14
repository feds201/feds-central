//Push it
// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.
package frc.robot;

import static edu.wpi.first.units.Units.MetersPerSecond;
import com.pathplanner.lib.auto.AutoBuilder;
import com.pathplanner.lib.auto.NamedCommands;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.wpilibj.DriverStation;
import edu.wpi.first.wpilibj.smartdashboard.SendableChooser;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import edu.wpi.first.wpilibj2.command.button.Trigger;
import frc.robot.RobotMap.DrivetrainConstants;
import frc.robot.subsystems.intake.IntakeSubsystem;
import frc.robot.subsystems.intake.IntakeSubsystem.IntakeState;
import frc.robot.subsystems.intake.IntakeSubsystem.RollerState;
import frc.robot.subsystems.feeder.Feeder;
import frc.robot.subsystems.feeder.Feeder.feeder_state;
import frc.robot.subsystems.shooter.ShooterHood;
import frc.robot.subsystems.shooter.ShooterHood.shooterhood_state;
import frc.robot.subsystems.shooter.ShooterWheels;
import frc.robot.subsystems.shooter.ShooterWheels.shooter_state;
import frc.robot.subsystems.spindexer.Spindexer;
import frc.robot.subsystems.spindexer.Spindexer.spindexer_state;
import frc.robot.sim.RebuiltSimManager;


import org.littletonrobotics.junction.Logger;

import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.subsystems.swerve.generated.TunerConstants;
import frc.robot.utils.LimelightWrapper;
import frc.robot.utils.RTU.RootTestingUtility;
import frc.robot.rtu.RTUManager;
import frc.robot.utils.AutoSweeper;
import limelight.networktables.LimelightSettings.ImuMode;
import static edu.wpi.first.units.Units.RotationsPerSecond;
import static edu.wpi.first.units.Units.Rotations;

public class RobotContainer extends ControllerBindings {

    // Singleton accessor so external code (DiagnosticServer) can command
    // shooter/hood.
    private static RobotContainer instance;

    private final CommandSwerveDrivetrain drivetrain = DrivetrainConstants.createDrivetrain();
    // Limelight naming conventions are based on physical inventory system, hence
    // "limelight-two" and "limelight-five" represent our second and fifth
    // limelights respectively.
    private final LimelightWrapper ll4 = new LimelightWrapper("limelight-two", true);
    private final LimelightWrapper ll3 = new LimelightWrapper("limelight-five", false);

    private final CommandXboxController controller = new CommandXboxController(0);
    private final CommandXboxController operaterController = new CommandXboxController(1);

    private final Telemetry telemetry = new Telemetry(TunerConstants.kSpeedAt12Volts.in(MetersPerSecond));

    private final IntakeSubsystem intakeSubsystem = new IntakeSubsystem();
    private final Feeder feederSubsystem = new Feeder();
    private final ShooterHood shooterHood = new ShooterHood(drivetrain);
    private final ShooterWheels shooterWheels = new ShooterWheels(drivetrain);
    private final Spindexer spinDexer = new Spindexer();

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

    public IntakeSubsystem getIntakeSubsystem() {
        return intakeSubsystem;
    }

    public ShooterHood getShooterHood() {
        return shooterHood;
    }

    public ShooterWheels getShooterWheels() {
        return shooterWheels;
    }

    public Feeder getFeederSubsystem() {
        return feederSubsystem;
    }

    public Spindexer getSpindexer() {
        return spinDexer;
    }

    public CommandSwerveDrivetrain getDrivetrain() {
        return drivetrain;
    }

    public RobotContainer() {
    instance = this;
    ll4.getSettings().withImuMode(ImuMode.ExternalImu).save();
    setupDriveBindings(controller);
    setupOperatorBindings(operaterController);
    configureRootTests();
    new Trigger(drivetrain::withinTrench).and(DriverStation::isTeleop).onTrue(shooterHood.setStateCommand(shooterhood_state.IN).andThen(intakeSubsystem.setIntakeStateCommand(IntakeState.EXTENDED)));

    // TODO: migrate to LoggedDashboardChooser from AdvantageKit
    registerNamedCommands();
    autoChooser = AutoBuilder.buildAutoChooser();
    SmartDashboard.putData("Auto Chooser", autoChooser);
    drivetrain.registerTelemetry(telemetry::telemeterize);
  }
  
    // --- APIs used by the diagnostic server / UI to command shooter/hood ---
    private final AutoSweeper autoSweeper = new AutoSweeper(
            rps -> {
                try {
                    shooterWheels.setStateCommand(ShooterWheels.shooter_state.TEST).execute();
                    shooterWheels.setVelocity(RotationsPerSecond.of(rps));
                } catch (Exception e) {
                }
            },
            pos -> {
                try {
                    shooterHood.setStateCommand(ShooterHood.shooterhood_state.TEST).execute();
                    shooterHood.setAngle(Rotations.of(pos)); // pos is already in rotations (0-30)
                } catch (Exception e) {
                }
            });

    public synchronized void setShooterVelocityRps(double rps) {
        try {
            shooterWheels.setVelocity(RotationsPerSecond.of(rps));
        } catch (Exception e) {
            // best-effort
        }
    }

    public synchronized void setHoodPosition(double position) {
        try {
            // position is in rotations (0 to 30 rotations)
            shooterHood.setAngle(Rotations.of(position));
        } catch (Exception e) {
            // best-effort
        }
    }

    /** Backwards-compatible API: set hood angle in degrees (360deg = 1 rotation). */
    public synchronized void setHoodAngleDeg(double deg) {
        try {
            shooterHood.setAngle(Rotations.of(deg / 360.0));
        } catch (Exception e) {
            // best-effort
        }
    }

    /**
     * Start an automatic sweep of shooter velocities from min..max (inclusive)
     * using step, commanding hoodDeg for each step and holding for holdMs
     * milliseconds. This runs in a background thread and can be stopped with
     * stopAutoSweep().
     */
    public synchronized void startAutoSweep(double min, double max, double step, double hoodDeg, int holdMs) {
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
     * Start a dynamic auto-sweep driven by the diagnostic dashboard's telemetry
     * values. Puts shooter wheels and hood into TEST state while the sweep runs
     * and restores them when it finishes.
     * @param holdMs milliseconds to hold each supplier sample
     */
    public synchronized void startAutoSweepFromDiagnostic(int holdMs) {
    // enter test mode immediately
    shooterWheels.setState(frc.robot.subsystems.shooter.ShooterWheels.shooter_state.TEST);
    shooterHood.setState(frc.robot.subsystems.shooter.ShooterHood.shooterhood_state.TEST);

        autoSweeper.startDynamic(
            // shooter velocity supplier (RPS) comes from TelemetryPublisher
            () -> frc.robot.utils.RTU.TelemetryPublisher.getShooterVelocityRps(),
            // hood angle supplier (degrees) comes from TelemetryPublisher
            () -> frc.robot.utils.RTU.TelemetryPublisher.getHoodAngleDeg(),
            // enter test mode (redundant but safe)
            () -> {
                shooterWheels.setState(frc.robot.subsystems.shooter.ShooterWheels.shooter_state.TEST);
                shooterHood.setState(frc.robot.subsystems.shooter.ShooterHood.shooterhood_state.TEST);
            },
            // exit test mode: restore reasonable idle states
            () -> {
                shooterWheels.setState(frc.robot.subsystems.shooter.ShooterWheels.shooter_state.IDLE);
                shooterHood.setState(frc.robot.subsystems.shooter.ShooterHood.shooterhood_state.IN);
            },
            holdMs
        );
    }
  

    public void updateLocalization() {
        if (ll4.getNTTable().containsKey("tv")) {
            ll4.updateLocalizationLimelight(drivetrain);
        } else {
            ll3.updateLocalizationLimelight(drivetrain);
        }
    }

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

    public void initSimulation() {
        simManager = new RebuiltSimManager(drivetrain,
                intakeSubsystem, feederSubsystem, shooterWheels, shooterHood, spinDexer);
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

            boolean triggersOk = controller.getLeftTriggerAxis() >= 0.5 && controller.getRightTriggerAxis() >= 0.5;

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


public void registerNamedCommands() {
  NamedCommands.registerCommand("Extend Hopper", intakeSubsystem.setIntakeStateCommand(IntakeState.EXTENDED));
  NamedCommands.registerCommand("Extend Intake", intakeSubsystem.setIntakeStateCommand(IntakeState.EXTENDED));
  NamedCommands.registerCommand("Retract Intake", intakeSubsystem.setIntakeStateCommand(IntakeState.DEFAULT));
  NamedCommands.registerCommand("Run Rollers", intakeSubsystem.setRollerStateCommand(RollerState.ON));
  NamedCommands.registerCommand("Stop Rollers", intakeSubsystem.setRollerStateCommand(RollerState.OFF));
  NamedCommands.registerCommand("Start Shooter Spin", shooterWheels.setStateCommand(shooter_state.SHOOTING).alongWith(shooterHood.setStateCommand(shooterhood_state.SHOOTING)));
  NamedCommands.registerCommand("Stop Shooter Spin", shooterWheels.setStateCommand(shooter_state.IDLE).alongWith(shooterHood.setStateCommand(shooterhood_state.IN)).alongWith(spinDexer.setStateCommand(spindexer_state.STOP)).alongWith(feederSubsystem.setStateCommand(feeder_state.STOP)));
  NamedCommands.registerCommand("End Shooter Spin", shooterWheels.setStateCommand(shooter_state.IDLE).alongWith(shooterHood.setStateCommand(shooterhood_state.IN)).alongWith(spinDexer.setStateCommand(spindexer_state.STOP)).alongWith(feederSubsystem.setStateCommand(feeder_state.STOP)));
  NamedCommands.registerCommand("Run Shooter", shooterWheels.setStateCommand(shooter_state.SHOOTING).alongWith(feederSubsystem.setStateCommand(feeder_state.RUN)).alongWith(spinDexer.setStateCommand(spindexer_state.RUN)).alongWith(shooterHood.setStateCommand(shooterhood_state.SHOOTING)));
  NamedCommands.registerCommand("Shooting", shooterWheels.setStateCommand(shooter_state.SHOOTING).alongWith(feederSubsystem.setStateCommand(feeder_state.RUN)).alongWith(spinDexer.setStateCommand(spindexer_state.RUN)).alongWith(shooterHood.setStateCommand(shooterhood_state.SHOOTING)));


}



















}
