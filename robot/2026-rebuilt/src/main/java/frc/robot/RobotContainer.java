// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot;

import static edu.wpi.first.units.Units.MetersPerSecond;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.Commands;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import frc.robot.RobotMap.DrivetrainConstants;
import frc.robot.commands.swerve.TeleopSwerve;
import frc.robot.subsystems.intake.IntakeSubsystem;
import frc.robot.subsystems.intake.RollersSubsystem;
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
import org.littletonrobotics.junction.Logger;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import com.ctre.phoenix6.swerve.SwerveRequest;
import frc.robot.subsystems.swerve.generated.TunerConstants;
import frc.robot.utils.LimelightWrapper;
import frc.robot.utils.RTU.RootTestingUtility;
import limelight.networktables.LimelightSettings.ImuMode;

public class RobotContainer {
  
  private final CommandSwerveDrivetrain drivetrain = DrivetrainConstants.createDrivetrain();
  //Limelight naming conventions are based on physical inventory system, hence "limelight-two" and "limelight-five" represent our second and fifth limelights respectively.
  private final LimelightWrapper ll4 = new LimelightWrapper("limelight-two", true);
  private final LimelightWrapper ll3 = new LimelightWrapper("limelight-five", false);

  private final CommandXboxController controller = new CommandXboxController(0);


  private final IntakeSubsystem intakeSubsystem = new IntakeSubsystem();
  
  private final RollersSubsystem rollersSubsystem = RollersSubsystem.getInstance();

  private final Feeder feederSubsystem = new Feeder();

  private final ShooterHood shooterHood = new ShooterHood(drivetrain);
  private final ShooterWheels shooterWheels = new ShooterWheels(drivetrain);

  // Local testing subsystem (contains @RobotAction tests used by RootTestingUtility)
  // private final TestingSubsystem testingSubsystem = new TestingSubsystem();

  private final Spindexer spinDexer = new Spindexer();
 
  // Simulation
  private RebuiltSimManager simManager;

  private final RootTestingUtility rootTester = new RootTestingUtility();

  public RobotContainer() {
    ll4.getSettings().withImuMode(ImuMode.ExternalImu).save();
    configureBindings();
    configureRootTests();
  }

  public void updateLocalization() {
    if (ll4.getNTTable().containsKey("tv")) {
      ll4.updateLocalizationLimelight(drivetrain);
    } else {
      ll3.updateLocalizationLimelight(drivetrain);
    }
  }
  private void configureBindings() {
    controller.leftTrigger()
        .onTrue(intakeSubsystem.extendIntake().andThen(rollersSubsystem.RollersCommand(RollerState.ON)))
        .onFalse(rollersSubsystem.RollersCommand(RollerState.OFF));

    controller.leftBumper()
        .onTrue(intakeSubsystem.retractIntake());

    // Default drive command: field-centric swerve with left stick + right stick rotation
    drivetrain.setDefaultCommand(
        new TeleopSwerve(drivetrain, controller));

    // M key (Right bumper): intake rollers
    controller.rightBumper()
        .whileTrue(rollersSubsystem.RollersCommand(RollerState.ON))
        .onFalse(rollersSubsystem.RollersCommand(RollerState.OFF));

    controller.y()
      .onTrue(Commands.sequence(
        shooterHood.setStateCommand(shooterhood_state.SHOOTING),
        shooterWheels.setStateCommand(shooter_state.SHOOTING)))
      .onFalse(Commands.sequence(
        shooterHood.setStateCommand(shooterhood_state.IN),
        shooterWheels.setStateCommand(shooter_state.IDLE)));

    // Hood aiming: A = aim down, B = aim up (ShooterSim adjusts angle at fixed rate)
    controller.a()
        .onTrue(shooterHood.setStateCommand(shooterhood_state.AIMING_DOWN))
        .onFalse(shooterHood.setStateCommand(shooterhood_state.IN));
    controller.b()
        .onTrue(shooterHood.setStateCommand(shooterhood_state.AIMING_UP))
        .onFalse(shooterHood.setStateCommand(shooterhood_state.IN));

    controller.x()
      .onTrue(Commands.sequence(
        feederSubsystem.setStateCommand(feeder_state.RUN),
        spinDexer.setStateCommand(spindexer_state.RUN)))
      .onFalse(Commands.sequence(
        feederSubsystem.setStateCommand(feeder_state.STOP),
        spinDexer.setStateCommand(spindexer_state.STOP)));

  }

 
  


  /** Called from Robot.simulationInit(). */
  public void initSimulation() {
    try {
      // RebuiltSimManager depends on optional simulation libraries. Guard against
      // missing simulation classes so entering simulation/test mode doesn't crash
      // the robot when those libraries are not present on the classpath.
      simManager = new RebuiltSimManager(drivetrain, rollersSubsystem,
          intakeSubsystem, feederSubsystem, shooterWheels, shooterHood, spinDexer);
      // Signal simulation enabled for dashboards
      Logger.recordOutput("Sim/Enabled", true);
    } catch (LinkageError e) {
      // Missing simulation dependency (e.g. frc.sim.core.PhysicsWorld) or link error
      Logger.recordOutput("Sim/Error", "Simulation libraries not found or failed to link: " + e.toString());
      Logger.recordOutput("Sim/Enabled", false);
      simManager = null;
    } catch (Throwable t) {
      // Any other error during simulation init should not kill the robot program.
      Logger.recordOutput("Sim/Error", "Failed to initialize simulation: " + t.toString());
      t.printStackTrace();
      Logger.recordOutput("Sim/Enabled", false);
      simManager = null;
    }
    drivetrain.resetPose(new Pose2d(.5, .5, new Rotation2d(0)));
  }

  /** Called from Robot.simulationPeriodic(). */
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
   * Register every subsystem that contains @RobotAction methods.
   * Called once from the constructor.
   */
  private void configureRootTests() {
    rootTester.registerSubsystem(
        intakeSubsystem
    // testingSubsystem
        // Add more subsystems here as they're wired in:
        // feeder, climber, spindexer, etc.
    );

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

  /** Called from Robot.testInit(). Discovers and runs all @RobotAction tests. */
  public void runRootTests() {
    rootTester.runAll();
  }

  /** Called from Robot.testPeriodic(). Keeps dashboard data fresh. */
  public void updateRootTests() {
    rootTester.periodic();
  }
}
