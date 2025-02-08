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
import frc.robot.subsystems.gooseNeck.GooseNeck;

/* You should consider using the more terse Command factories API instead https://docs.wpilib.org/en/stable/docs/software/commandbased/organizing-command-based.html#defining-commands */
public class Vaulting extends Command {
  private double givenAngle;
  private GooseNeck gooseneck;
  private PIDController pidController;
  private ShuffleboardTab tab;

  /** Creates a new Vaulting. */
  public Vaulting(double setAngle, GooseNeck neck) {
    this.givenAngle = setAngle;
    this.gooseneck = neck;
    tab = Shuffleboard.getTab("getName()");
    addRequirements(neck);

  }

  // Called when the command is initially scheduled.
  @Override
  public void initialize() {
    // gooseneck.unlockPivot();
    pidController = new PIDController(0,0,0);
    pidController.setTolerance(2);
    tab.add(gooseneck);
    pidController.setSetpoint(givenAngle);
  }

  // Called every time the scheduler runs while the command is scheduled.
  @Override
  public void execute() {
    gooseneck.runPivotMotor(pidController.calculate(gooseneck.getPivotAngle()));
  }

  // Called once the command ends or is interrupted.
  @Override
  public void end(boolean interrupted) {  
  }

  // Returns true when the command should end.
  @Override
  public boolean isFinished() {
    return pidController.atSetpoint();
  }
}
