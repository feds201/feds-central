// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot;

import static edu.wpi.first.units.Units.DegreesPerSecond;

import java.util.Optional;

import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.Commands;
import frc.robot.RobotMap.DrivetrainConstants;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import limelight.networktables.AngularVelocity3d;
import limelight.networktables.Orientation3d;
import frc.robot.utils.LimelightWrapper;

public class RobotContainer {

  private final CommandSwerveDrivetrain drivetrain = DrivetrainConstants.createDrivetrain();
  private final LimelightWrapper sampleLocalizationLimelight = new LimelightWrapper("limelight-localization");

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
    // controller.x()
    //     .onTrue((leds.intakeSignal())).onFalse(leds.climbingSignal());
      
    // controller.y()
    //     .onTrue(rollers.RollersCommand(RollerState.ON))
    //     .onFalse(rollers.RollersCommand(RollerState.OFF));
  }

  public Command getAutonomousCommand() {
    return Commands.print("No autonomous command configured");
  }
}
