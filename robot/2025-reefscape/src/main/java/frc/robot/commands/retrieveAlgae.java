package frc.robot.commands;

import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.wpilibj2.command.Command;
import frc.robot.subsystems.coralAlgaeIntake.coralAlgaeIntake;

public class retrieveAlgae extends Command {
  private coralAlgaeIntake intakeSubsystem; // NUll
  private boolean isFinished;
  private PIDController pidController;

  public retrieveAlgae(coralAlgaeIntake intake) {
  this.intakeSubsystem = intake;

  }

  
  @Override
  public void initialize() {

  }

  @Override
  public void execute() {}


  @Override
  public void end(boolean interrupted) {}


  @Override
  public boolean isFinished() {
    return false;
  }
}
