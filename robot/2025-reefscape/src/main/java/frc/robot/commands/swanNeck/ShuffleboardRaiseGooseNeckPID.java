// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.commands.swanNeck;

import java.util.function.DoubleSupplier;

import edu.wpi.first.wpilibj2.command.Command;
import frc.robot.subsystems.swanNeck.SwanNeck;

/* You should consider using the more terse Command factories API instead https://docs.wpilib.org/en/stable/docs/software/commandbased/organizing-command-based.html#defining-commands */
public class ShuffleboardRaiseGooseNeckPID extends Command {
  SwanNeck m_swanNeck;
  DoubleSupplier m_setpoint;
  /** Creates a new testingRaiseClimberPID. */
  public ShuffleboardRaiseGooseNeckPID(DoubleSupplier setpoint, SwanNeck swanNeck) {
    m_setpoint = setpoint;
    m_swanNeck = swanNeck;
    addRequirements(m_swanNeck);
    // Use addRequirements() here to declare subsystem dependencies.
  }

  // Called when the command is initially scheduled.
  @Override
  public void initialize() {}

  // Called every time the scheduler runs while the command is scheduled.
  @Override
  public void execute() {
    m_swanNeck.rotateSwanNeckPID();
  }

  // Called once the command ends or is interrupted.
  @Override
  public void end(boolean interrupted) {}

  // Returns true when the command should end.
  @Override
  public boolean isFinished() {
    return false;
  }
}
