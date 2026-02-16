// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot;

import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.Commands;
import frc.robot.RobotMap.DrivetrainConstants;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.utils.LimelightWrapper;
import limelight.networktables.LimelightSettings.ImuMode;

public class RobotContainer {

  private final CommandSwerveDrivetrain drivetrain = DrivetrainConstants.createDrivetrain();
   private final LimelightWrapper ll4 = new LimelightWrapper("limelight-two", true);
   
  public RobotContainer() {
    ll4.getSettings().withImuMode(ImuMode.ExternalImu).save();
    configureBindings();
  }

  public void updateLocalizationLL4() {
          ll4.updateLocalizationLimelight(drivetrain);
    }
  
  private void configureBindings() {}

  public Command getAutonomousCommand() {
    return Commands.print("No autonomous command configured");
  }
}
