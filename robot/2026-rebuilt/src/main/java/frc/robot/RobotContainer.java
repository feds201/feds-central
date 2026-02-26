// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot;

import com.pathplanner.lib.auto.AutoBuilder;
import com.pathplanner.lib.auto.NamedCommands;

import edu.wpi.first.wpilibj.smartdashboard.SendableChooser;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.Commands;
import frc.robot.RobotMap.DrivetrainConstants;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.utils.LimelightWrapper;

public class RobotContainer {

  private final CommandSwerveDrivetrain drivetrain = DrivetrainConstants.createDrivetrain();
  private final LimelightWrapper ll4 = new LimelightWrapper("limelight-four-localization");
  private final LimelightWrapper ll3 = new LimelightWrapper("limelight-three-localization");
  private final SendableChooser<Command> autoChooser;


  public RobotContainer() {
    configureBindings();
    autoChooser = AutoBuilder.buildAutoChooser();

    SmartDashboard.putData("Auto Chooser", autoChooser);
  }

  public void updateLocalization() {
    LimelightWrapper.updateLocalizationLimelight(ll3, false, drivetrain);
    LimelightWrapper.updateLocalizationLimelight(ll4, true, drivetrain);
  }
  
  private void configureBindings() {}

  public Command getAutonomousCommand() {
    return autoChooser.getSelected();
  }
}
