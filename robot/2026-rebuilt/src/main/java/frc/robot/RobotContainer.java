// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot;

import static edu.wpi.first.units.Units.MetersPerSecond;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.Commands;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import frc.robot.RobotMap.DrivetrainConstants;
import frc.robot.commands.swerve.HubDrive;
import frc.robot.commands.swerve.TeleopSwerve;
import frc.robot.subsystems.intake.IntakeSubsystem;
import frc.robot.subsystems.intake.RollersSubsystem;
import frc.robot.subsystems.intake.RollersSubsystem.RollerState;
import frc.robot.subsystems.feeder.Feeder;
import frc.robot.subsystems.feeder.Feeder.feeder_state;
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

  private HubDrive hubDrive;

  private final CommandXboxController controller = new CommandXboxController(0);


  private final IntakeSubsystem intakeSubsystem = new IntakeSubsystem();
  
  private final RollersSubsystem rollersSubsystem = RollersSubsystem.getInstance();

  private final Feeder feederSubsystem = new Feeder();

  // TODO: implement this for real (was just added to enable simulation)
  private final Shooter shooterSim = new Shooter();
  private final ShooterHood shooterHood = new ShooterHood(drivetrain);
  private final ShooterWheels shooterWheels = new ShooterWheels(drivetrain);

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
    if(Robot.isSimulation()){
      configureBindingsSim();
    } else {
      configureBindings();
    }
    
    configureRootTests();
    
    hubDrive = new HubDrive(drivetrain, null);
  }

  public void updateLocalization() {
    if (ll4.getNTTable().containsKey("tv")) {
      ll4.updateLocalizationLimelight(drivetrain);
    } else {
      ll3.updateLocalizationLimelight(drivetrain);
    }
  }
  private void configureBindingsSim(){
     // TODO: rm once shooter hood/wheels are tuned
    controller.leftBumper().whileTrue(shooterSim.shootCommand());
    controller.a().whileTrue(shooterSim.hoodDownCommand());
    controller.b().whileTrue(shooterSim.hoodUpCommand());

    // Default drive command: field-centric swerve with left stick + right stick rotation
    drivetrain.setDefaultCommand(
        new TeleopSwerve(drivetrain, controller));
  }

  private void configureBindings() {

    controller.start()
       .onTrue(DrivetrainConstants.createDrivetrain().runOnce(() -> DrivetrainConstants.createDrivetrain().seedFieldCentric()));
    

    controller.leftTrigger()
        .onTrue(intakeSubsystem.extendIntake().andThen(rollersSubsystem.RollersCommand(RollerState.ON)))
        .onFalse(rollersSubsystem.RollersCommand(RollerState.OFF));

    controller.leftBumper()
        .onTrue(intakeSubsystem.retractIntake());

    controller.rightTrigger().and(hubDrive::pidAtSetpoint).and(shooterWheels::atSetpoint).whileTrue(
            Commands.sequence(
            shooterWheels.setStateCommand(shooter_state.SHOOTING),
             spinDexer.setStateCommand(spindexer_state.RUN),
            feederSubsystem.setStateCommand(feeder_state.RUN)
            )
          ).onFalse(
            Commands.sequence(
            feederSubsystem.setStateCommand(feeder_state.STOP),
            spinDexer.setStateCommand(spindexer_state.STOP)
            )
          );

      // Right Bumper being reserved for Climbing

    controller.x()
      .onTrue(
        Commands.sequence(
          shooterHood.setStateCommand(shooterhood_state.LAYUP),
          shooterWheels.setStateCommand(shooter_state.LAYUP)
        )
      );
      onFalse(shooterHood.setStateCommand(shooterhood_state.IDLE));

      controller.a().and(shooterWheels::atSetpoint).whileTrue(
        Commands.sequence(
            shooterWheels.setStateCommand(shooter_state.SHOOTING),
             spinDexer.setStateCommand(spindexer_state.RUN),
            feederSubsystem.setStateCommand(feeder_state.RUN)
        )
      );
      onFalse(
        Commands.sequence(
          shooterWheels.setStateCommand(shooter_state.IDLE),
          spinDexer.setStateCommand(spindexer_state.STOP),
          feederSubsystem.setStateCommand(feeder_state.STOP)
        )
      );
        
    controller.y()
      .onTrue(
        Commands.sequence(
          shooterHood.setStateCommand(shooterhood_state.HALFCOURT),
          shooterWheels.setStateCommand(shooter_state.HALFCOURT)
        )
      ); 
      onFalse(shooterHood.setStateCommand(shooterhood_state.IDLE));
      
          // Default drive command: field-centric swerve with left stick + right stick rotation
          drivetrain.setDefaultCommand(
              new TeleopSwerve(drivetrain, controller));
      
          // M key (Right bumper): intake rollers
          controller.rightBumper()
              .whileTrue(rollersSubsystem.RollersCommand(RollerState.ON))
              .onFalse(rollersSubsystem.RollersCommand(RollerState.OFF));
      
          controller.povRight().whileTrue(
            Commands.sequence(
              shooterHood.setStateCommand(shooterhood_state.SHOOTING), 
              shooterWheels.setStateCommand(shooter_state.SHOOTING)
            ).alongWith(hubDrive))
          .onFalse(
            Commands.sequence(
              shooterHood.setStateCommand(shooterhood_state.OUT), 
              shooterWheels.setStateCommand(shooter_state.IDLE)
            ).alongWith(hubDrive)
            );
      
        }
      
       
        
      
      
        private void onFalse(Command setStateCommand) {
          // TODO Auto-generated method stub
          throw new UnsupportedOperationException("Unimplemented method 'onFalse'");
        }
      
        /** Called from Robot.simulationInit(). */
  public void initSimulation() {
    try {
      // RebuiltSimManager depends on optional simulation libraries. Guard against
      // missing simulation classes so entering simulation/test mode doesn't crash
      // the robot when those libraries are not present on the classpath.
      simManager = new RebuiltSimManager(drivetrain, shooterSim, rollersSubsystem);
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
        intakeSubsystem,
        shooterSim
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
