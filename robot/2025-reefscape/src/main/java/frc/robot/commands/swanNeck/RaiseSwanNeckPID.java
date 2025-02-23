// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.commands.swanNeck;

import java.util.function.DoubleSupplier;

import edu.wpi.first.wpilibj2.command.Command;
import frc.robot.subsystems.swanNeck.SwanNeck;

/* You should consider using the more terse Command factories API instead https://docs.wpilib.org/en/stable/docs/software/commandbased/organizing-command-based.html#defining-commands */
public class RaiseSwanNeckPID extends Command {
  DoubleSupplier m_setpoint;
  SwanNeck m_gooseNeck;
  /** Rotates SwanNeck Subsystem Using PID
   * 
   * @param setpoint The setpoint of the Gooseneck In rotations, with horizontal being 0.
   */
  public RaiseSwanNeckPID(DoubleSupplier setpoint, SwanNeck gooseNeck) {
    m_gooseNeck = gooseNeck;
    m_setpoint = setpoint;

    addRequirements(m_gooseNeck);
  }

  // Called when the command is initially scheduled.
  @Override
  public void initialize() {
    m_gooseNeck.setPIDTarget(m_setpoint.getAsDouble());
  }

  // Called every time the scheduler runs while the command is scheduled.
  @Override
  public void execute() {
    m_gooseNeck.rotateSwanNeckPID();
  }

  // Called once the command ends or is interrupted.
  @Override
  public void end(boolean interrupted) {
    m_gooseNeck.setPivotSpeed(0);
  }

  // Returns true when the command should end.
  @Override
  public boolean isFinished() {
    return false;
  }
}
