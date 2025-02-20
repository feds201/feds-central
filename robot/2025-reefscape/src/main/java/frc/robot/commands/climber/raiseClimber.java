// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.commands.climber;

import edu.wpi.first.wpilibj2.command.Command;
import frc.robot.subsystems.climber.Climber;

/* You should consider using the more terse Command factories API instead https://docs.wpilib.org/en/stable/docs/software/commandbased/organizing-command-based.html#defining-commands */
public class raiseClimber extends Command {
  /** Creates a new raiseClimber. */
  private Climber m_Climber;
  private double m_TargetAngle;
  public raiseClimber(Climber climber, double targetAngle) {
    m_Climber = climber;
    m_TargetAngle = targetAngle;
    addRequirements(climber);
  }

  

  // Called when the command is initially scheduled.
  @Override
  public void initialize() {
    m_Climber.setPIDTarget(m_TargetAngle);
  }

  // Called every time the scheduler runs while the command is scheduled.
  @Override
  public void execute() {
    m_Climber.rotateClimber(m_Climber.calculatePID(m_Climber.getEncoderValue()));
  }

  // Called once the command ends or is interrupted.
  @Override
  public void end(boolean interrupted) {}

  // Returns true when the command should end.
  @Override
  public boolean isFinished() {
    return m_Climber.pidAtSetpoint();
  }
}
