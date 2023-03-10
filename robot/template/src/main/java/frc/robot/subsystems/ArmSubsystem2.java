package frc.robot.subsystems;

import com.ctre.phoenix.motorcontrol.ControlMode;
import com.ctre.phoenix.motorcontrol.NeutralMode;
import com.ctre.phoenix.motorcontrol.StatusFrameEnhanced;
import com.ctre.phoenix.motorcontrol.SupplyCurrentLimitConfiguration;
import com.ctre.phoenix.motorcontrol.TalonFXInvertType;
import com.ctre.phoenix.motorcontrol.can.TalonFX;

import edu.wpi.first.math.controller.ArmFeedforward;
import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.trajectory.TrapezoidProfile.Constraints;
import edu.wpi.first.math.util.Units;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.lib.math.Conversions;
import frc.robot.Constants.ArmConstants;
import frc.robot.Constants.TelescopeConstants;
import frc.robot.utils.DriveFunctions;
import frc.robot.RobotContainer;

public class ArmSubsystem2 extends SubsystemBase {
    private final TalonFX m_armMain = new TalonFX(ArmConstants.kArmMotor1);
    private final TalonFX m_armFollower = new TalonFX(ArmConstants.kArmMotor2);
    private final TalonFX m_telescopeMotor = new TalonFX(TelescopeConstants.kTelescopeMotor);
    // private final ConeDetection coneDetector;

    // private boolean settingArmPositionUp = false;
    // private boolean armDoneRotating = false;
    // private double targetArmPosition = ArmConstants.kArmHome;

    private final PIDController m_extensionPIDController = new PIDController(TelescopeConstants.kP,
            TelescopeConstants.kI, TelescopeConstants.kD);
    private final Constraints m_rotationConstraints = new Constraints(ArmConstants.cruiseVelocityAccelDown,
            ArmConstants.cruiseVelocityAccelDown); // FIXME: fix this
    private final PIDController m_rotationPIDController = new PIDController(ArmConstants.kPUp, ArmConstants.kIUp,
            ArmConstants.kDUp);
    private ArmFeedforward m_rotationFF = new ArmFeedforward(ArmConstants.kS, ArmConstants.kG, ArmConstants.kV,
            ArmConstants.kA);

    private double angleSetpointRadians;
    private boolean isOpenLoopRotation = true;
    private boolean isOpenLoopExtension = true;
    private double extensionSetpoint;

    public ArmSubsystem2() {
        m_armMain.configFactoryDefault();
        m_armFollower.configFactoryDefault();

        m_rotationPIDController.enableContinuousInput(0, 2 * Math.PI);
        m_telescopeMotor.configFactoryDefault();
        m_telescopeMotor.setNeutralMode(NeutralMode.Brake);
        setAngleSetpointRadians(getArmAngleRadians());
        m_rotationPIDController.setTolerance(TelescopeConstants.kThreshold.getRadians());
        isOpenLoopRotation = false;
        SmartDashboard.putData("Arm Rotation PID Controller", m_rotationPIDController);

        m_armMain.configForwardSoftLimitThreshold(Conversions.degreesToFalcon(130, ArmConstants.kArmGearRatio),
                0);
        m_armMain.configReverseSoftLimitThreshold(Conversions.degreesToFalcon(-130, ArmConstants.kArmGearRatio), 0);
        m_armMain.configForwardSoftLimitEnable(true, 0);
        m_armMain.configReverseSoftLimitEnable(true, 0);

        m_armMain.setSelectedSensorPosition(0);

        m_armFollower.follow(m_armMain);
        m_armFollower.setInverted(TalonFXInvertType.FollowMaster);

        m_armMain.setInverted(TalonFXInvertType.CounterClockwise);
        m_armMain.setNeutralMode(NeutralMode.Brake);
        m_armFollower.setNeutralMode(NeutralMode.Brake);

        m_armMain.configVoltageCompSaturation(12);
        m_armFollower.configVoltageCompSaturation(12);
        m_armMain.enableVoltageCompensation(true);
        m_armFollower.enableVoltageCompensation(true);

        m_armMain.setStatusFramePeriod(StatusFrameEnhanced.Status_1_General, 10);
        m_armMain.setStatusFramePeriod(StatusFrameEnhanced.Status_2_Feedback0, 10);
        m_armMain.setStatusFramePeriod(StatusFrameEnhanced.Status_3_Quadrature, 255);
        m_armMain.setStatusFramePeriod(StatusFrameEnhanced.Status_4_AinTempVbat, 255);
        m_armMain.setStatusFramePeriod(StatusFrameEnhanced.Status_8_PulseWidth, 255);
        m_armMain.setStatusFramePeriod(StatusFrameEnhanced.Status_10_Targets, 255);
        m_armMain.setStatusFramePeriod(StatusFrameEnhanced.Status_12_Feedback1, 255);
        m_armMain.setStatusFramePeriod(StatusFrameEnhanced.Status_13_Base_PIDF0, 255);
        m_armMain.setStatusFramePeriod(StatusFrameEnhanced.Status_14_Turn_PIDF1, 255);
        m_armMain.setStatusFramePeriod(StatusFrameEnhanced.Status_Brushless_Current, 255);

        m_armFollower.setStatusFramePeriod(StatusFrameEnhanced.Status_1_General, 10);
        m_armFollower.setStatusFramePeriod(StatusFrameEnhanced.Status_2_Feedback0, 10);
        m_armFollower.setStatusFramePeriod(StatusFrameEnhanced.Status_3_Quadrature, 255);
        m_armFollower.setStatusFramePeriod(StatusFrameEnhanced.Status_4_AinTempVbat, 255);
        m_armFollower.setStatusFramePeriod(StatusFrameEnhanced.Status_8_PulseWidth, 255);
        m_armFollower.setStatusFramePeriod(StatusFrameEnhanced.Status_10_Targets, 255);
        m_armFollower.setStatusFramePeriod(StatusFrameEnhanced.Status_12_Feedback1, 255);
        m_armFollower.setStatusFramePeriod(StatusFrameEnhanced.Status_13_Base_PIDF0, 255);
        m_armFollower.setStatusFramePeriod(StatusFrameEnhanced.Status_14_Turn_PIDF1, 255);
        m_armFollower.setStatusFramePeriod(StatusFrameEnhanced.Status_Brushless_Current, 255);

        SupplyCurrentLimitConfiguration rotateArmMainCurrentLimit = new SupplyCurrentLimitConfiguration();
        rotateArmMainCurrentLimit.currentLimit = 40;

        m_armMain.configSupplyCurrentLimit(rotateArmMainCurrentLimit);
    }

    public double getExtensionSetpoint() {
        return extensionSetpoint;
    }

    public void setExtensionSetpoint(double setpoint) {
        this.extensionSetpoint = setpoint;
    }

    public PIDController getExtensionPIDController() {
        return this.m_extensionPIDController;
    }

    public PIDController getRotationPIDController() {
        return this.m_rotationPIDController;
    }

    public void rotate(double percent) {
        if (percent == 0.0) {
            if (isOpenLoopRotation) {
                holdAngle();
            }
        } else {
            isOpenLoopRotation = true;
        }
    }

    public Command extendToCommand(double length) {
        m_extensionPIDController.setTolerance(length);
        return run(() -> setExtensionSetpoint(length))
                .until(m_extensionPIDController::atSetpoint)
                .andThen(runOnce(() -> holdExtension()));
    }

    public Command extendAndRotateCommand(Rotation2d angle, double length) {
        m_extensionPIDController.setTolerance(length);
        return run(() -> setExtensionAndRotation(angle.getRadians(), length))
                .until(this::isExtenstionAndRotationAtSetpoint)
                .andThen(runOnce(() -> holdExtension()));
    }

    public void setExtensionAndRotation(double angle, double length) {
        setExtensionSetpoint(length);
        setAngleSetpointRadians(angle);
    }

    public boolean isExtenstionAndRotationAtSetpoint() {
        return m_extensionPIDController.atSetpoint() && m_rotationPIDController.atSetpoint();
    }

    public void extend(double percent) {
        if (percent == 0.0) {
            if (isOpenLoopExtension) {
                holdExtension();
            }
        } else {
            isOpenLoopExtension = true;
            m_telescopeMotor.set(ControlMode.PercentOutput, percent);
        }

    }

    public void extendClosedLoop(double velocity) {
        isOpenLoopExtension = false;
        double feedForward = 0; // calculate feed forward
        m_telescopeMotor.set(ControlMode.PercentOutput, DriveFunctions.voltageToPercentOutput(feedForward));
    }

    public void rotateClosedLoop(double velocity) {
        isOpenLoopRotation = false;
        SmartDashboard.putNumber("OUTPUT", velocity);
        double feedForward = m_rotationFF.calculate(getArmAngleRadians(), velocity);
        SmartDashboard.putNumber("FeedForward", feedForward);
        SmartDashboard.putNumber("Voltage", DriveFunctions.voltageToPercentOutput(feedForward));
        m_armMain.set(ControlMode.PercentOutput, DriveFunctions.voltageToPercentOutput(feedForward));
    }

    public double getArmAngleRadians() {
        return Units.degreesToRadians(Conversions.falconToDegrees(m_armMain.getSelectedSensorPosition(), ArmConstants.kArmGearRatio));
    }

    public double getAngleSetpointRadians() {
        return angleSetpointRadians;
    }

    public void setAngleSetpointRadians(double angleSetpoint) {
        this.angleSetpointRadians = angleSetpoint;
    }

    public void holdAngle() {
        setAngleSetpointRadians(getArmAngleRadians());
        isOpenLoopRotation = false;
    }

    public void holdExtension() {
        setExtensionSetpoint(getCurrentExtension());
        isOpenLoopExtension = false;
    }

    @Override
    public void periodic() {
        SmartDashboard.putNumber("Arm Angle", Units.radiansToDegrees(getArmAngleRadians()));
        if (isOpenLoopRotation) {
            m_rotationPIDController.reset();
        } else {
            SmartDashboard.putNumber("Setpoint", getAngleSetpointRadians());
            SmartDashboard.putNumber("Measurement", getArmAngleRadians());
            SmartDashboard.putNumber("Error", getAngleSetpointRadians() - getArmAngleRadians());
            m_rotationPIDController.setSetpoint(getAngleSetpointRadians());
            rotateClosedLoop(m_rotationPIDController.calculate(getArmAngleRadians()));
        }

        if (isOpenLoopExtension) {
            m_extensionPIDController.reset();
        } else {
            m_extensionPIDController.setSetpoint(getExtensionSetpoint());
            extendClosedLoop(m_extensionPIDController.calculate(getCurrentExtension()));
        }
    }

    public double getCurrentExtension() {
        return m_telescopeMotor.getSelectedSensorPosition();
    }
}
