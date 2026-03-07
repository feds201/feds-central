package frc.robot.commands.intake;

import edu.wpi.first.wpilibj.Timer;
import edu.wpi.first.wpilibj2.command.Command;
import frc.robot.subsystems.intake.IntakeSubsystem;


public class AgitateWhileHeldRotationsCommand extends Command {
	private enum Phase { EXTENDING, RETRACTING }
	private static final double HOME_ROTATIONS = 0.0;

	private final IntakeSubsystem intake;
	private final double rotationsPerPulse;
	private final double retractDwellSeconds;

	private Phase phase;
	private double targetPosition;
	private boolean moveAwayFromHome;
	private double moveDirection;
	private final Timer dwellTimer = new Timer();


	public AgitateWhileHeldRotationsCommand(IntakeSubsystem intake,
	                                        double rotationsPerPulse,
	                                        double retractDwellSeconds) {
		this.intake = intake;
		this.rotationsPerPulse = rotationsPerPulse;
		this.retractDwellSeconds = retractDwellSeconds;
		addRequirements(intake); // properly require the subsystem
	}

	/** Convenience: 0.3 s retract dwell by default. */
	public AgitateWhileHeldRotationsCommand(IntakeSubsystem intake, double rotationsPerPulse) {
		this(intake, rotationsPerPulse, 0.3);
	}

	@Override
	public void initialize() {
		moveAwayFromHome = true;
		startExtend();
	}

	@Override
	public void execute() {
		switch (phase) {
			case EXTENDING -> {
				double currentPosition = intake.getRollerPosition();
				boolean reachedTarget = moveDirection > 0
						? currentPosition >= targetPosition
						: currentPosition <= targetPosition;
				if (reachedTarget) {
					// Done with this pulse — retract and dwell
					intake.stopRoller();
					intake.setState(IntakeSubsystem.IntakeState.DEFAULT);
					phase = Phase.RETRACTING;
					moveAwayFromHome = !moveAwayFromHome;
					dwellTimer.restart();
				}
			}
			case RETRACTING -> {
				if (dwellTimer.hasElapsed(retractDwellSeconds)) {
					// Dwell complete — start next pulse
					startExtend();
				}
			}
		}
	}

	@Override
	public void end(boolean interrupted) {
		intake.stopRoller();
		intake.setState(IntakeSubsystem.IntakeState.DEFAULT);
		dwellTimer.stop();
	}

	@Override
	public boolean isFinished() {
		return false; // runs until canceled
	}

	private void startExtend() {
		intake.setState(IntakeSubsystem.IntakeState.EXTENDED);
		double currentPosition = intake.getRollerPosition();
		targetPosition = moveAwayFromHome ? Math.abs(rotationsPerPulse) : HOME_ROTATIONS;
		moveDirection = Math.signum(targetPosition - currentPosition);
		if (moveDirection >= 0) {
			intake.startRoller();
		} else {
			intake.setRollerState(IntakeSubsystem.RollerState.REVERSE);
		}
		phase = Phase.EXTENDING;
	}
}

