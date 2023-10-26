package frc.robot.utils;

public class DriveFunctions {
	public final static double deadzone(double input, double threshold) {
		if (Math.abs(input) < threshold)
			return 0;
		return Math.signum(input) * (Math.abs(input) - threshold) / (1 - threshold);
	}

	public static double voltageToPercentOutput(double voltage) {
		return voltage;
	}
}
