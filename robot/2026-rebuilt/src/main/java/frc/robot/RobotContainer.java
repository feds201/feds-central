// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot;

import static edu.wpi.first.units.Units.MetersPerSecond;

import java.time.Instant;

import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.Commands;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import frc.robot.RobotMap.DrivetrainConstants;
import frc.robot.subsystems.intake.IntakeSubsystem;
import frc.robot.subsystems.intake.RollersSubsystem;
import frc.robot.subsystems.feeder.Feeder;
import frc.robot.subsystems.feeder.Feeder.feeder_state;
import frc.robot.subsystems.intake.Intake;
import frc.robot.subsystems.shooter.Shooter;
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

  // TODO: implement this for real (was just added to enable simulation)
  private final Shooter shooter = new Shooter();
  private final ShooterHood shooterHood = new ShooterHood(drivetrain);
  private final ShooterWheels shooterWheels = new ShooterWheels(drivetrain);

  // TODO: implement this for real (was just added to enable simulation)
  private final Intake intake = new Intake();
  // Local testing subsystem (contains @RobotAction tests used by RootTestingUtility)
  // private final TestingSubsystem testingSubsystem = new TestingSubsystem();

  private final Spindexer spinDexer = new Spindexer();
 

  // TODO: implement this for real (was just added to enable simulation)
  // Swerve drive requests
  private final SwerveRequest.FieldCentric fieldCentric = new SwerveRequest.FieldCentric();
  // TODO: implement this for real (was just added to enable simulation)
  private final double MAX_SPEED = TunerConstants.kSpeedAt12Volts.in(MetersPerSecond);
  // TODO: implement this for real (was just added to enable simulation)
  private final double MAX_ANGULAR_RATE = Math.PI * 2; // rad/s

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
    // controller.a()
    //   .onTrue(IntakeSubsystem.dyanmicCommand(Direction.kReverse));
    // controller.b()
    //   .onTrue(IntakeSubsystem.dyanmicCommand(Direction.kForward));
    // controller.x()
    //   .onTrue(IntakeSubsystem.quatsiCommand(Direction.kReverse));
    // controller.y()
    //   .onTrue(IntakeSubsystem.quatsiCommand(Direction.kForward));

    controller.leftTrigger()
        .onTrue(intakeSubsystem.extendIntake());

    controller.leftBumper()
        .onTrue(intakeSubsystem.retractIntake());

    // controller.x()
    //     .onTrue((leds.intakeSignal())).onFalse(leds.climbingSignal());

    // controller.y()
    //     .onTrue(rollers.RollersCommand(RollerState.ON))
    //     .onFalse(rollers.RollersCommand(RollerState.OFF));

    // TODO: implement this for real (was just added to enable simulation)
    // Default drive command: field-centric swerve with left stick + right stick rotation
    drivetrain.setDefaultCommand(
        drivetrain.applyRequest(() -> fieldCentric
            .withVelocityX(-controller.getLeftY() * MAX_SPEED)
            .withVelocityY(-controller.getLeftX() * MAX_SPEED)
            .withRotationalRate(-controller.getRightX() * MAX_ANGULAR_RATE)));

    // TODO: implement this for real (was just added to enable simulation)
    // M key (Right bumper): intake
    controller.rightBumper()
        .whileTrue(intake.intakeCommand());

    // TODO: implement this for real (was just added to enable simulation)
    // / key (Left bumper): shoot
    // NOTE: leftBumper also bound to intakeSubsystem.retractIntake() above
    controller.leftBumper()
        .whileTrue(shooter.shootCommand());

    // TODO: implement this for real (was just added to enable simulation)
    // D-pad up: hood angle up
    // D-pad down: hood angle down
    // (POV buttons need custom triggers)
    // controller.y()
    //     .whileTrue(shooter.hoodUpCommand());
    // controller.y().onTrue(new InstantCommand (() -> setShooterToShooting()));

    controller.y().onTrue(
      Commands.sequence(
        shooterHood.setStateCommand(shooterhood_state.SHOOTING), 
        shooterWheels.setStateCommand(shooter_state.SHOOTING)
      )
    );

    controller.x().whileTrue(
      Commands.sequence(
      feederSubsystem.setStateCommand(feeder_state.RUN),
      spinDexer.setStateCommand(spindexer_state.RUN)
      )
    );



    // TODO: implement this for real (was just added to enable simulation)-

   // controller.x().whileTrue(new InstantCommand(() -> getFuelIntoShooter()));

  }

 
  

  public void getFuelIntoShooter(){
      feederSubsystem.setState(feeder_state.RUN);
      spinDexer.setState(spindexer_state.RUN);
  }

  /** Called from Robot.simulationInit(). */
  public void initSimulation() {
    try {
      // RebuiltSimManager depends on optional simulation libraries. Guard against
      // missing simulation classes so entering simulation/test mode doesn't crash
      // the robot when those libraries are not present on the classpath.
      simManager = new RebuiltSimManager(drivetrain, shooter, intake);
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
        intakeSubsystem,
        shooter,
        intake
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
