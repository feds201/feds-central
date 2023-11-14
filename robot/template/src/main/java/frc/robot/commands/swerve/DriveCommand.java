package frc.robot.commands.swerve;

import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.subsystems.SwerveSubsystem;

public class DriveCommand extends CommandBase {
    private final SwerveSubsystem s_swerve;
    private final double xDrive;
    private final double yDrive;
    private final double rotation;

    public DriveCommand(SwerveSubsystem swerve, double xDrive, double yDrive, double rotation) {
        this.s_swerve = swerve;
        this.xDrive = xDrive;
        this.yDrive = yDrive;
        this.rotation = rotation;

        addRequirements(s_swerve);
    }

    @Override
    public void initialize() {}

    @Override
    public void execute() {
        s_swerve.drive(new Translation2d(xDrive, yDrive), rotation, true, true);
    }


    @Override
    public void end(boolean interrupted) {
        
    }

    @Override
    public boolean isFinished() {
        return false;
    }
}
