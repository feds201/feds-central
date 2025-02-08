// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.commands.Elevator;

import java.util.function.DoubleSupplier;

import edu.wpi.first.wpilibj2.command.Command;
import frc.robot.subsystems.elevator.Elevator;

/* You should consider using the more terse Command factories API instead https://docs.wpilib.org/en/stable/docs/software/commandbased/organizing-command-based.html#defining-commands */
public class rotateElevator extends Command {
  /** Creates a new rotateElevator. */
  private final Elevator c_Elevator;
  private final DoubleSupplier c_ElevatorAngle;
  public rotateElevator(Elevator elevator, DoubleSupplier elevatorAngle) {
    // Use addRequirements() here to declare subsystem dependencies.
    c_Elevator = elevator;
    c_ElevatorAngle = elevatorAngle;
  }

  // Called when the command is initially scheduled.
  @Override
  public void initialize() {
    c_Elevator.setPIDTarget(c_ElevatorAngle.getAsDouble());
  }

  // Called every time the scheduler runs while the command is scheduled.
  @Override
  public void execute() {
    c_Elevator.rotateElevatorPID();
  }

  // Called once the command ends or is interrupted.
  @Override
  public void end(boolean interrupted) {
    c_Elevator.setMotorSpeed(0);
  }

  // Returns true when the command should end.
  @Override
  public boolean isFinished() {
    return c_Elevator.pidAtSetpoint();
  }
}
