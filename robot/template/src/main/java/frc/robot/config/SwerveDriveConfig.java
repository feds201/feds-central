package frc.robot.config;

import com.ctre.phoenix.motorcontrol.can.SlotConfiguration;

public class SwerveDriveConfig {

	public SwerveModuleConfig moduleConfig;
	public double gyroFactor;

	public double width;
	public double length;
	public double wheelDistance;

	public double maxLinearAccel;
	public double maxRotateAccel;

	public SwerveDriveConfig() {
		moduleConfig = new SwerveModuleConfig();
		moduleConfig.pid = new SlotConfiguration();
		moduleConfig.pid.closedLoopPeriod = 1;
		moduleConfig.pid.kP = 0.1;
		moduleConfig.pid.kI = 0;
		moduleConfig.pid.integralZone = 0;
		moduleConfig.pid.kF = 0;
		moduleConfig.pid.maxIntegralAccumulator = 0;
		moduleConfig.pid.kD = 0;


		moduleConfig.maxRamp = 0;
		moduleConfig.reverseThreshold = 0.3;
		moduleConfig.steerBrake = false;

		moduleConfig.steerCurrentLimitEnabled = true;
		moduleConfig.steerCurrentLimit = 25;
		moduleConfig.steerCurrentLimitTime = 0.5;

		moduleConfig.driveCurrentLimitEnabled = true;
		moduleConfig.driveCurrentLimit = 25;
		moduleConfig.driveCurrentLimitTime = 1;

		gyroFactor = 0.03;

		width = 21.5;
		length = 25.5;
		wheelDistance = 12.566;

		maxLinearAccel = 2;
		maxRotateAccel = 2;


	}

	
}
