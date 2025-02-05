package frc.robot.commands.Elevator;

import edu.wpi.first.wpilibj2.command.Command;
import frc.robot.subsystems.Elevator.Elevator;
import edu.wpi.first.wpilibj.Timer;

public class GoUpCommand extends Command {
    private final Elevator elevatorSubsystem;
    private final Timer timer = new Timer();
    private final double duration;
    private final double speed;

    public GoUpCommand(Elevator elevatorSubsystem, double speed, double duration) {
        this.elevatorSubsystem = elevatorSubsystem;
        this.speed = speed;
        this.duration = duration;

        // Declare subsystem dependencies
        addRequirements(elevatorSubsystem);
    }

    @Override
    public void initialize() {
        timer.reset();
        timer.start();
        elevatorSubsystem.setMotorSpeed(speed); // Start motor at the given speed
    }

    @Override
    public void execute() {
        // Optionally, log or monitor the current height during execution
        // System.out.println("Current Height: " + elevatorSubsystem.getRangePosition());
    }

    @Override
    public boolean isFinished() {
        // Stop after the specified duration
        return timer.hasElapsed(duration);
    }

    @Override
    public void end(boolean interrupted) {
        // elevatorSubsystem.setMotorSpeed(0); // Stop the motor
        // System.out.println("Final Height: " + elevatorSubsystem.getRangePosition());
    }
}
