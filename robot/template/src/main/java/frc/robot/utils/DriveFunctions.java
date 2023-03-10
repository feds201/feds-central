package frc.robot.utils;

import edu.wpi.first.math.MathUtil;
import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.wpilibj.PowerDistribution;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import frc.robot.RobotContainer;
import frc.robot.Constants.SwerveConstants;

public class DriveFunctions {
	public final static double deadzone(double input, double threshold) {
		if (Math.abs(input) < threshold)
			return 0;
		return Math.signum(input) * (Math.abs(input) - threshold) / (1 - threshold);
	}

	public static double voltageToPercentOutput(double voltage) {
		return MathUtil.clamp(voltage / Math.min(12, RobotContainer.m_PowerDistribution.getVoltage()), -1, 1);
	}

	public static Pose2d accelerationControls(double targetX, double targetY, double currentX, double currentY) {
		double translatedTargetX = targetX - currentX;
		double translatedTargetY = targetX - currentX;

		double vectorAngleFromComponents = Math.atan2(translatedTargetY, translatedTargetX);
		double deltaX = Math.cos(vectorAngleFromComponents) * SwerveConstants.kMaxLinearAccel * SwerveConstants.kDeltaSecs;
		double deltaY = Math.sin(vectorAngleFromComponents) * SwerveConstants.kMaxLinearAccel * SwerveConstants.kDeltaSecs;

		currentX += Math.signum(translatedTargetX) * Math.min(Math.abs(deltaX), Math.abs(translatedTargetX));
		currentY += Math.signum(translatedTargetY) * Math.min(Math.abs(deltaY), Math.abs(translatedTargetY));

		double changeAngle = Math.atan2(currentY, currentX);

		Pose2d pose = new Pose2d(currentX, currentY, Rotation2d.fromRadians(changeAngle));
	
		SmartDashboard.putNumber("current X", currentX);			
		SmartDashboard.putNumber("current Y", currentY);
		SmartDashboard.putNumber("Rotation2d", changeAngle);			

		return pose;
	}
}
