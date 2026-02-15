// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot;

import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.Commands;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import frc.robot.subsystems.IntakeSubsystem;
import frc.robot.subsystems.LedsSubsystem;
import frc.robot.subsystems.RollersSubsystem;
import frc.robot.subsystems.RollersSubsystem.RollerState;

public class RobotContainer {
  CommandXboxController controller = new CommandXboxController(0);
  RollersSubsystem rollers = RollersSubsystem.getInstance();
  LedsSubsystem leds = LedsSubsystem.getInstance();
  // IntakeSubsystem intake = new IntakeSubsystem();

  public RobotContainer() {
    configureBindings();

  }

  private void configureBindings() {
    controller.x()
        .onTrue((leds.climbingSignal()))
        .onFalse(leds.resetLEDS());
      

    controller.y()
        .onTrue(rollers.RollersCommand(RollerState.ON).alongWith(leds.intakeSignal()))
        .onFalse(rollers.RollersCommand(RollerState.OFF).alongWith(leds.resetLEDS()));
     
    controller.b()
        .onTrue(leds.hasGamePieceSignal())
        .onFalse(leds.resetLEDS());

    controller.a()
      .onTrue(leds.shootingSignal())
      .onFalse(leds.resetLEDS());



  }


  

  public Command getAutonomousCommand() {
    return Commands.print("No autonomous command configured");
  }
}
