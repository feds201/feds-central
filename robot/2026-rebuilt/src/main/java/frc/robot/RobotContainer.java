// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot;

import static edu.wpi.first.units.Units.DegreesPerSecond;
import static edu.wpi.first.units.Units.MetersPerSecond;
import static edu.wpi.first.units.Units.RadiansPerSecond;

import java.util.Optional;

import edu.wpi.first.wpilibj.XboxController;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.Commands;
import edu.wpi.first.wpilibj2.command.button.JoystickButton;
import edu.wpi.first.wpilibj2.command.button.Trigger;
import frc.robot.RobotMap.DrivetrainConstants;
import frc.robot.sim.RebuiltSimManager;
import frc.robot.subsystems.intake.Intake;
import frc.robot.subsystems.shooter.Shooter;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import com.ctre.phoenix6.swerve.SwerveRequest;
import frc.robot.subsystems.swerve.generated.TunerConstants;
import limelight.networktables.AngularVelocity3d;
import limelight.networktables.Orientation3d;
import frc.robot.utils.LimelightWrapper;

public class RobotContainer {

  private final CommandSwerveDrivetrain drivetrain = DrivetrainConstants.createDrivetrain();
  private final Shooter shooter = new Shooter();
  private final Intake intake = new Intake();
  private final LimelightWrapper sampleLocalizationLimelight = new LimelightWrapper("limelight-localization");

  private final XboxController driverController = new XboxController(0);

  // Swerve drive requests
  private final SwerveRequest.FieldCentric fieldCentric = new SwerveRequest.FieldCentric();
  private final double MAX_SPEED = TunerConstants.kSpeedAt12Volts.in(MetersPerSecond);
  private final double MAX_ANGULAR_RATE = Math.PI * 2; // rad/s

  // Simulation
  private RebuiltSimManager simManager;

  public RobotContainer() {
    configureBindings();
  }

  public void updateLocalization() {
    sampleLocalizationLimelight.getSettings()
        .withRobotOrientation(new Orientation3d(drivetrain.getRotation3d(),
            new AngularVelocity3d(DegreesPerSecond.of(0),
                DegreesPerSecond.of(0),
                DegreesPerSecond.of(0))))
        .save();

    // Get MegaTag2 pose
    Optional<limelight.networktables.PoseEstimate> visionEstimate = sampleLocalizationLimelight.getPoseEstimator(true)
        .getPoseEstimate();
    // If the pose is present
    visionEstimate.ifPresent((limelight.networktables.PoseEstimate poseEstimate) -> {
      // Add it to the pose estimator.
      drivetrain.addVisionMeasurement(poseEstimate.pose.toPose2d(), poseEstimate.timestampSeconds);
    });
  }

  private void configureBindings() {
    // Default drive command: field-centric swerve with left stick + right stick rotation
    drivetrain.setDefaultCommand(
        drivetrain.applyRequest(() -> fieldCentric
            .withVelocityX(-driverController.getLeftY() * MAX_SPEED)
            .withVelocityY(-driverController.getLeftX() * MAX_SPEED)
            .withRotationalRate(-driverController.getRightX() * MAX_ANGULAR_RATE)));

    // M key (Right bumper): intake
    new JoystickButton(driverController, XboxController.Button.kRightBumper.value)
        .whileTrue(intake.intakeCommand());

    // / key (Left bumper): shoot
    new JoystickButton(driverController, XboxController.Button.kLeftBumper.value)
        .whileTrue(shooter.shootCommand());

    // D-pad up: hood angle up
    // D-pad down: hood angle down
    // (POV buttons need custom triggers)
    new JoystickButton(driverController, XboxController.Button.kY.value)
        .whileTrue(shooter.hoodUpCommand());
    new JoystickButton(driverController, XboxController.Button.kA.value)
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
