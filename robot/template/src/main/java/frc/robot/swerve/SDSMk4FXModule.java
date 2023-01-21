package frc.robot.swerve;

import com.ctre.phoenix.motorcontrol.ControlMode;
import com.ctre.phoenix.motorcontrol.FeedbackDevice;
import com.ctre.phoenix.motorcontrol.NeutralMode;
import com.ctre.phoenix.motorcontrol.RemoteSensorSource;
import com.ctre.phoenix.motorcontrol.StatusFrameEnhanced;
import com.ctre.phoenix.motorcontrol.SupplyCurrentLimitConfiguration;
import com.ctre.phoenix.motorcontrol.can.FilterConfiguration;
import com.ctre.phoenix.motorcontrol.can.TalonFX;
import com.ctre.phoenix.motorcontrol.can.TalonFXConfiguration;
import com.ctre.phoenix.sensors.SensorVelocityMeasPeriod;

import frc.robot.config.SwerveModuleConfig;

public class SDSMk4FXModule implements ISwerveModule {

	public static final double DRIVE_ENCODER_COUNTS = 8.41 * 2048;
	public static final double STEER_CENTRAL_ENCODER_COUNTS = 4096;
	public static final double STEER_MOTOR_ENCODER_COUNTS = 2048 * 12.8;

	public static final int RELATIVE_INIT_DELAY = 1000;

	private final TalonFX steer;
	private final TalonFX drive;
	private final int encoderChannel;
	private double angleOffset;
	private double reverseThreshold;

	private long initTime;
	private boolean initialized = false;

	private double targetAngle = 0;
	private double targetSpeed = 0;
	private double realCurrentAngle = 0;
	private double effectiveCurrentAngle = 0;
	private double currentSpeed = 0;
	private boolean reversed = false;

	public SDSMk4FXModule(int steerChannel, int driveChannel, int encoderChannel,
							double angleOffset, SwerveModuleConfig config) {
		steer = new TalonFX(steerChannel);
		drive = new TalonFX(driveChannel);
		this.encoderChannel = encoderChannel;
		this.angleOffset = angleOffset;

		configure(config);
	}

	@Override
	public void setTargetVelocity(double angle, double speed) {
		targetAngle = (angle % 1 + 1) % 1;
		targetSpeed = speed;
	}

	// Written by Michael Kaatz (2022)
	@Override
	public void tick() {
		if (!initialized && System.currentTimeMillis() > initTime + RELATIVE_INIT_DELAY) {
			steer.setSelectedSensorPosition(steer.getSelectedSensorPosition(1) *
											STEER_MOTOR_ENCODER_COUNTS / STEER_CENTRAL_ENCODER_COUNTS);
			initialized = true;
		}
		if (initialized) {
			realCurrentAngle = steer.getSelectedSensorPosition() / STEER_MOTOR_ENCODER_COUNTS;
			effectiveCurrentAngle = ((realCurrentAngle - angleOffset) % 1 + (reversed ? 0.5 : 0) + 1) % 1;
			currentSpeed = drive.getSelectedSensorVelocity() / DRIVE_ENCODER_COUNTS * 10 * (reversed ? -1 : 1);

			// We don't want to move the wheels if we don't have to.
			if (targetSpeed != 0) {
				// The loop error is just the negative opposite of the continous error.
				double errorContinous = -(effectiveCurrentAngle - targetAngle);
				double errorLoop = -(1 - Math.abs(errorContinous)) * Math.signum(errorContinous);

				// Sign is preserved since it is used to determine which way we need to turn the wheel.
				double targetError;
				if (Math.abs(errorContinous) < Math.abs(errorLoop))
					targetError = errorContinous;
				else
					targetError = errorLoop;

				// In some cases it is better to reverse the direction of the drive wheel rather than spinning all the way around.
				if (Math.abs(targetError) > reverseThreshold) {
					reversed = !reversed;
					// Quick way to recalculate the offset of the new angle from the target.
					targetError = -Math.signum(targetError) * (0.5 - Math.abs(targetError));
				}

				steer.set(ControlMode.Position, (realCurrentAngle + targetError) * STEER_MOTOR_ENCODER_COUNTS);
				drive.set(ControlMode.PercentOutput, targetSpeed * (reversed ? -1 : 1));
			} else {
				steer.neutralOutput();
				drive.neutralOutput();
			}
		}
	}

	@Override
	public void configure(SwerveModuleConfig config) {
		TalonFXConfiguration steerConfig = new TalonFXConfiguration();
		steerConfig.neutralDeadband = 0.001;
		steerConfig.remoteFilter0 = new FilterConfiguration();
		steerConfig.remoteFilter0.remoteSensorDeviceID = encoderChannel;
		steerConfig.remoteFilter0.remoteSensorSource = RemoteSensorSource.TalonSRX_SelectedSensor;
		steerConfig.primaryPID.selectedFeedbackSensor = FeedbackDevice.IntegratedSensor;
		steerConfig.auxiliaryPID.selectedFeedbackSensor = FeedbackDevice.RemoteSensor0;
		steerConfig.feedbackNotContinuous = false;
		steerConfig.slot0 = config.pid;
		steerConfig.supplyCurrLimit = new SupplyCurrentLimitConfiguration();
		steerConfig.supplyCurrLimit.enable = config.steerCurrentLimitEnabled;
		steerConfig.supplyCurrLimit.currentLimit = config.steerCurrentLimit;
		steerConfig.supplyCurrLimit.triggerThresholdTime = config.steerCurrentLimitTime;
		steer.configAllSettings(steerConfig);
		steer.selectProfileSlot(0, 0);
		steer.setInverted(true);
		steer.setNeutralMode(config.steerBrake ? NeutralMode.Brake : NeutralMode.Coast);
		steer.setStatusFramePeriod(StatusFrameEnhanced.Status_1_General, 255);
		steer.setStatusFramePeriod(StatusFrameEnhanced.Status_2_Feedback0, 10);
		steer.setStatusFramePeriod(StatusFrameEnhanced.Status_3_Quadrature, 255);
		steer.setStatusFramePeriod(StatusFrameEnhanced.Status_4_AinTempVbat, 255);
		steer.setStatusFramePeriod(StatusFrameEnhanced.Status_8_PulseWidth, 255);
		steer.setStatusFramePeriod(StatusFrameEnhanced.Status_10_Targets, 255);
		steer.setStatusFramePeriod(StatusFrameEnhanced.Status_12_Feedback1, 255);
		steer.setStatusFramePeriod(StatusFrameEnhanced.Status_13_Base_PIDF0, 255);
		steer.setStatusFramePeriod(StatusFrameEnhanced.Status_14_Turn_PIDF1, 255);
		steer.setStatusFramePeriod(StatusFrameEnhanced.Status_Brushless_Current, 255);

		TalonFXConfiguration driveConfig = new TalonFXConfiguration();
		driveConfig.neutralDeadband = 0.001;
		driveConfig.openloopRamp = config.maxRamp;
		driveConfig.primaryPID.selectedFeedbackSensor = FeedbackDevice.IntegratedSensor;
		driveConfig.velocityMeasurementPeriod = SensorVelocityMeasPeriod.Period_20Ms;
		driveConfig.velocityMeasurementWindow = 1;
		driveConfig.voltageCompSaturation = 12;
		driveConfig.supplyCurrLimit = new SupplyCurrentLimitConfiguration();
		driveConfig.supplyCurrLimit.enable = config.driveCurrentLimitEnabled;
		driveConfig.supplyCurrLimit.currentLimit = config.driveCurrentLimit;
		driveConfig.supplyCurrLimit.triggerThresholdTime = config.driveCurrentLimitTime;
		drive.configAllSettings(driveConfig);
		drive.setInverted(true);
		drive.setNeutralMode(NeutralMode.Brake);
		drive.enableVoltageCompensation(true);
		drive.setStatusFramePeriod(StatusFrameEnhanced.Status_1_General, 255);
		drive.setStatusFramePeriod(StatusFrameEnhanced.Status_2_Feedback0, 10);
		drive.setStatusFramePeriod(StatusFrameEnhanced.Status_3_Quadrature, 255);
		drive.setStatusFramePeriod(StatusFrameEnhanced.Status_4_AinTempVbat, 255);
		drive.setStatusFramePeriod(StatusFrameEnhanced.Status_8_PulseWidth, 255);
		drive.setStatusFramePeriod(StatusFrameEnhanced.Status_10_Targets, 255);
		drive.setStatusFramePeriod(StatusFrameEnhanced.Status_12_Feedback1, 255);
		drive.setStatusFramePeriod(StatusFrameEnhanced.Status_13_Base_PIDF0, 255);
		drive.setStatusFramePeriod(StatusFrameEnhanced.Status_14_Turn_PIDF1, 255);
		drive.setStatusFramePeriod(StatusFrameEnhanced.Status_Brushless_Current, 255);

		reverseThreshold = config.reverseThreshold;

		reversed = false;
		initialized = false;
		initTime = System.currentTimeMillis();
	}

	@Override
	public double getAngleOffset() {
		return angleOffset;
	}

	@Override
	public void setAngleOffsetAbsolute(double offset) {
		angleOffset = offset;
		angleOffset = (angleOffset % 1 + 1) % 1;
	}

	@Override
	public void setAngleOffsetRelative(double offset) {
		angleOffset += offset;
		angleOffset = (angleOffset % 1 + 1) % 1;
	}

	@Override
	public void align() {
		angleOffset = realCurrentAngle;
		angleOffset = (angleOffset % 1 + 1) % 1;
	}

	@Override
	public double getCurrentAngle() {
		return effectiveCurrentAngle;
	}

	@Override
	public double getCurrentSpeed() {
		return currentSpeed;
	}

	@Override
	public double getTargetAngle() {
		return targetAngle;
	}

	@Override
	public double getTargetSpeed() {
		return targetSpeed;
	}
}
