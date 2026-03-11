package frc.robot.commands.intake;

import edu.wpi.first.wpilibj.Timer;
import edu.wpi.first.wpilibj2.command.Command;
import frc.robot.subsystems.intake.IntakeSubsystem;

/**
 * Command that pulses the intake extend/retract while held using time durations.
 * Runs until canceled.
 */
public class AgitateWhileHeldTimeCommand extends Command {
  private final IntakeSubsystem intake;
  private final double extendSeconds;
  private final double retractSeconds;
  private boolean extended = false;
  private double phaseEnd = 0.0;

  public AgitateWhileHeldTimeCommand(IntakeSubsystem intake, double extendSeconds, double retractSeconds) {
    this.intake = intake;
    this.extendSeconds = extendSeconds;
    this.retractSeconds = retractSeconds;
    addRequirements(intake);
  }

  @Override
  public void initialize() {
    intake.setState(IntakeSubsystem.IntakeState.EXTENDED);
    extended = true;
    intake.startRoller();
    phaseEnd = Timer.getFPGATimestamp() + extendSeconds;
  }

  @Override
  public void execute() {
    double now = Timer.getFPGATimestamp();
    if (now >= phaseEnd) {
      if (extended) {
        intake.setState(IntakeSubsystem.IntakeState.DEFAULT);
        intake.stopRoller();
        extended = false;
        phaseEnd = now + retractSeconds;
      } else {
        intake.setState(IntakeSubsystem.IntakeState.EXTENDED);
        intake.startRoller();
        extended = true;
        phaseEnd = now + extendSeconds;
      }
    }
  }

  @Override
  public void end(boolean interrupted) {
    intake.setState(IntakeSubsystem.IntakeState.DEFAULT);
    intake.stopRoller();
  }

  @Override
  public boolean isFinished() {
    return false; // runs until canceled
  }
}
