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
import frc.robot.constants.ArmConstants;
import frc.robot.constants.TelescopeConstants;
import frc.robot.utils.DriveFunctions;

public class ArmSubsystem3 extends SubsystemBase {
    private final TalonFX m_armMain = new TalonFX(ArmConstants.kArmMotor1);
    private final TalonFX m_armFollower = new TalonFX(ArmConstants.kArmMotor2);
    private final Constraints m_rotationConstraints = new Constraints(ArmConstants.cruiseVelocityAccelDown,
            ArmConstants.cruiseVelocityAccelDown); // FIXME: fix this
    private final PIDController m_rotationPIDController = new PIDController(ArmConstants.kPUp, ArmConstants.kIUp,
            ArmConstants.kDUp);
    private ArmFeedforward m_rotationFF = new ArmFeedforward(ArmConstants.kS, ArmConstants.kG, ArmConstants.kV,
            ArmConstants.kA);

    private double angleSetpointRadians;
    private boolean isOpenLoopRotation;

    public ArmSubsystem3() {
        m_armMain.configFactoryDefault();
        m_armFollower.configFactoryDefault();

        m_rotationPIDController.enableContinuousInput(0, 2 * Math.PI);
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
            m_armMain.set(ControlMode.PercentOutput, percent);
        }
    }

    public Command rotateToCommand(Rotation2d angle) {
        return run(() -> setAngleSetpointRadians(angle.getRadians()));
    }

    public boolean isRotationAtSetpoint() {
        return m_rotationPIDController.atSetpoint();
    }

    public void rotateClosedLoop(double velocity) {
        if (getArmAngleRadians() > Units.degreesToRadians(ArmConstants.kForwardSoftLimit)){
            velocity = 0;
        }
        isOpenLoopRotation = false;
        SmartDashboard.putNumber("OUTPUT", velocity);
        double feedForward = m_rotationFF.calculate(getArmAngleRadians(),velocity);
        SmartDashboard.putNumber("FeedForward", feedForward);
        SmartDashboard.putNumber("Voltage", DriveFunctions.voltageToPercentOutput(feedForward));
        m_armMain.set(ControlMode.PercentOutput, DriveFunctions.voltageToPercentOutput(feedForward));
    }

    public double getArmAngleRadians() {
        return Units.degreesToRadians(
                Conversions.falconToDegrees(m_armMain.getSelectedSensorPosition(), ArmConstants.kArmGearRatio));
    }

    public double getAngleSetpointRadians() {
        return angleSetpointRadians;
    }

    public void setAngleSetpointRadians(double angleSetpoint) {
        this.angleSetpointRadians = angleSetpoint;
    }

    public void holdAngle() {
        rotateClosedLoop(0);
    }

    @Override
    public void periodic() {
        SmartDashboard.putNumber("Arm Angle", Units.radiansToDegrees(getArmAngleRadians()));
        if (isOpenLoopRotation) {
        //     m_rotationPIDController.reset();
        } else {
            SmartDashboard.putNumber("Setpoint", getAngleSetpointRadians());
            SmartDashboard.putNumber("Measurement", getArmAngleRadians());
            SmartDashboard.putNumber("Error", getAngleSetpointRadians() - getArmAngleRadians());
        //     m_rotationPIDController.setSetpoint(getAngleSetpointRadians());
        //     rotateClosedLoop(m_rotationPIDController.calculate(getArmAngleRadians()));
        }
    }
}
