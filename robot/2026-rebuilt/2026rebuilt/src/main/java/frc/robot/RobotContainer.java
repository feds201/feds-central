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
import frc.robot.subsystems.IntakeSubsystem.IntakeState;
import frc.robot.subsystems.RollersSubsystem.RollerState;

public class RobotContainer {
  CommandXboxController controller = new CommandXboxController(0);
  //RollersSubsystem rollers = RollersSubsystem.getInstance();
  LedsSubsystem leds = new LedsSubsystem();
  IntakeSubsystem intake = new IntakeSubsystem();

  public RobotContainer() {
    configureBindings();

  }

  private void configureBindings() {
    controller.x()
        .onTrue((leds.intakeSignal())).onFalse(leds.climbingSignal());
      

    // controller.y()
    //     .onTrue(rollers.RollersCommand(RollerState.ON))
    //     .onFalse(rollers.RollersCommand(RollerState.OFF));
  }

  public Command getAutonomousCommand() {
    return Commands.print("No autonomous command configured");
  }
}
