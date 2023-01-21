package frc.robot.swerve;

import frc.robot.config.SwerveDriveConfig;

public interface ISwerveDrive extends edu.wpi.first.wpilibj2.command.Subsystem {

	public void setTargetVelocity(double linearAngle, double linearSpeed, double rotate);
	public void setMode(SwerveMode mode);

	public void getAlignments(double[] output);
	public void setAlignmentsAbsolute(double[] alignments);
	public void setAlignmentsRelative(double[] alignments);
	public void align();

	public void configure(SwerveDriveConfig config);

	public double getTargetLinearAngle();
	public double getTargetLinearSpeed();
	public double getTargetRotate();

	public SwerveMode getMode();
}
