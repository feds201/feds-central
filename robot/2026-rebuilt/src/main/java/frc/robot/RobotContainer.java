// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot;

import static edu.wpi.first.units.Units.MetersPerSecond;


import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.Commands;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import frc.robot.RobotMap.DrivetrainConstants;
import frc.robot.subsystems.intake.IntakeSubsystem;
import frc.robot.subsystems.intake.Intake;
import frc.robot.subsystems.shooter.Shooter;
import frc.robot.sim.RebuiltSimManager;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import com.ctre.phoenix6.swerve.SwerveRequest;
import frc.robot.subsystems.swerve.generated.TunerConstants;
import frc.robot.utils.LimelightWrapper;
import limelight.networktables.LimelightSettings.ImuMode;

public class RobotContainer {

  private final CommandSwerveDrivetrain drivetrain = DrivetrainConstants.createDrivetrain();
  //Limelight naming conventions are based on physical inventory system, hence "limelight-two" and "limelight-five" represent our second and fifth limelights respectively.
  private final LimelightWrapper ll4 = new LimelightWrapper("limelight-two", true);
  private final LimelightWrapper ll3 = new LimelightWrapper("limelight-five", false);

  private final CommandXboxController controller = new CommandXboxController(0);
  private final IntakeSubsystem intakeSubsystem = new IntakeSubsystem();

  // TODO: implement this for real (was just added to enable simulation)
  private final Shooter shooter = new Shooter();
  // TODO: implement this for real (was just added to enable simulation)
  private final Intake intake = new Intake();

  // TODO: implement this for real (was just added to enable simulation)
  // Swerve drive requests
  private final SwerveRequest.FieldCentric fieldCentric = new SwerveRequest.FieldCentric();
  // TODO: implement this for real (was just added to enable simulation)
  private final double MAX_SPEED = TunerConstants.kSpeedAt12Volts.in(MetersPerSecond);
  // TODO: implement this for real (was just added to enable simulation)
  private final double MAX_ANGULAR_RATE = Math.PI * 2; // rad/s

  // Simulation
  private RebuiltSimManager simManager;

  public RobotContainer() {
    ll4.getSettings().withImuMode(ImuMode.ExternalImu).save();
    configureBindings();
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
    controller.y()
        .whileTrue(shooter.hoodUpCommand());
    // TODO: implement this for real (was just added to enable simulation)
    controller.a()
        .whileTrue(shooter.hoodDownCommand());
  }

  /** Called from Robot.simulationInit(). */
  public void initSimulation() {
    simManager = new RebuiltSimManager(drivetrain, shooter, intake);
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
}
