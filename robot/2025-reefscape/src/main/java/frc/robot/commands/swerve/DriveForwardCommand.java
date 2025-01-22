package frc.robot.commands.swerve;

import edu.wpi.first.wpilibj2.command.Command;
import frc.robot.subsystems.swerve.SwerveSubsystem;

public class DriveForwardCommand extends Command {
    private final SwerveSubsystem swerveSubsystem;
    private final double speed;
    private final double duration;
    private double startTime;

    public DriveForwardCommand(SwerveSubsystem swerveSubsystem, double speed, double duration) {
        this.swerveSubsystem = swerveSubsystem;
        this.speed = speed;
        this.duration = duration;
        addRequirements(swerveSubsystem);
    }

    @Override
    public void initialize() {
        startTime = edu.wpi.first.wpilibj.Timer.getFPGATimestamp();
    }

    @Override
    public void execute() {
        swerveSubsystem.drive(speed, 0, 0, true);
    }

    @Override
    public void end(boolean interrupted) {
        swerveSubsystem.drive(0, 0, 0, true);
        startTime = 0;
    }

    @Override
    public boolean isFinished() {
        return edu.wpi.first.wpilibj.Timer.getFPGATimestamp() - startTime >= duration;
    }
}