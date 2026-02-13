// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot;

import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.Commands;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import frc.robot.subsystems.IntakeSubsystem;
import frc.robot.subsystems.LedsSubsystem;


public class RobotContainer {
CommandXboxController controller = new CommandXboxController(0);
IntakeSubsystem intake = new IntakeSubsystem();
LedsSubsystem leds = new LedsSubsystem();
  public RobotContainer() {
      controller.x().onTrue(intake.runIntakeMotors().alongWith(leds.shootingSignal())).onFalse(intake.stopIntakeMotors());
      controller.a().onTrue(intake.runIntakeMasterMotors().alongWith(leds.intakeSignal())).onFalse(intake.stopIntakeMotors());
      controller.b().onTrue(leds.climbingSignal());
       controller.y().onTrue(leds.hasGamePieceSignal());



  }



  public Command getAutonomousCommand() {
    return Commands.print("No autonomous command configured");
  }
}
