package frc.robot.commands.drive;

import org.opencv.core.RotatedRect;

import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.kinematics.SwerveModuleState;
import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.subsystems.SwerveSubsystem;

public class LockWheels extends CommandBase {
    private SwerveSubsystem s_Swerve;

    public LockWheels(SwerveSubsystem s_Swerve) {
        this.s_Swerve = s_Swerve;
    }

    @Override
    public void initialize() {
        SwerveModuleState[] states = { 
                new SwerveModuleState(1, Rotation2d.fromDegrees(45)),
                new SwerveModuleState(1, Rotation2d.fromDegrees(135)),
                new SwerveModuleState(1, Rotation2d.fromDegrees(45)),
                new SwerveModuleState(1, Rotation2d.fromDegrees(135))};
        s_Swerve.setModuleStates(states);
    }

    @Override
    public boolean isFinished() {
        return true;
    }

    @Override
    public void end(boolean interrupted) {
        SwerveModuleState[] states = { 
            new SwerveModuleState(0, Rotation2d.fromDegrees(45)),
            new SwerveModuleState(0, Rotation2d.fromDegrees(135)),
            new SwerveModuleState(0, Rotation2d.fromDegrees(45)),
            new SwerveModuleState(0, Rotation2d.fromDegrees(135))};
        s_Swerve.setModuleStates(states);
    }
}
