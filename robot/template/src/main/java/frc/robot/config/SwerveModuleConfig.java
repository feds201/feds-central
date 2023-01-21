package frc.robot.config;

import com.ctre.phoenix.motorcontrol.can.SlotConfiguration;

public class SwerveModuleConfig {

	public SlotConfiguration pid;
	public double maxRamp;
	public double reverseThreshold;
	public boolean steerBrake;

	public boolean steerCurrentLimitEnabled;
	public double steerCurrentLimit;
	public double steerCurrentLimitTime;

	public boolean driveCurrentLimitEnabled;
	public double driveCurrentLimit;
	public double driveCurrentLimitTime;
}
