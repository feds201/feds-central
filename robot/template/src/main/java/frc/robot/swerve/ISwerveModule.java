package frc.robot.swerve;

import frc.robot.config.SwerveModuleConfig;

public interface ISwerveModule {

	public void setTargetVelocity(double angle, double speed);

	public double getAngleOffset();
	public void setAngleOffsetAbsolute(double offset);
	public void setAngleOffsetRelative(double offset);
	public void align();

	public void configure(SwerveModuleConfig config);

	public double getTargetAngle();
	public double getTargetSpeed();
	public double getCurrentAngle();
	public double getCurrentSpeed();

	public default void tick() {}
}
