// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.commands;

import java.nio.channels.ShutdownChannelGroupException;

import com.ctre.phoenix6.signals.PIDOutput_PIDOutputModeValue;

import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardTab;
import edu.wpi.first.wpilibj2.command.Command;
import frc.robot.constants.RobotMap.IntakeMap;
import frc.robot.subsystems.swanNeck.SwanNeck;

/* You should consider using the more terse Command factories API instead https://docs.wpilib.org/en/stable/docs/software/commandbased/organizing-command-based.html#defining-commands */
public class Vaulting extends Command {
  private double givenAngle;
  private SwanNeck swanNeck;

  /** Creates a new Vaulting. */
  public Vaulting(double setAngle, SwanNeck neck) {
    this.givenAngle = setAngle;
    this.swanNeck = neck;
    addRequirements(neck);

  }

  // Called when the command is initially scheduled.
  @Override
  public void initialize() {
    IntakeMap.intakePid.setSetpoint(givenAngle);
  }

  // Called every time the scheduler runs while the command is scheduled.
  @Override
  public void execute() {
    swanNeck.runPivotMotor(IntakeMap.intakePid.calculate(swanNeck.getPivotAngle()));
  }

  // Called once the command ends or is interrupted.
  @Override
  public void end(boolean interrupted) {  
  }

  // Returns true when the command should end.
  @Override
  public boolean isFinished() {
    return IntakeMap.intakePid.atSetpoint();
  }
}
