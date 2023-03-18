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

public class ArmSubsystem4 extends SubsystemBase {
    private final TalonFX m_armMain = new TalonFX(ArmConstants.kArmMotor1);

    private double angleSetpointRadians;
    private boolean isOpenLoopRotation;

    public ArmSubsystem4() {
        m_armMain.configFactoryDefault();
        setAngleSetpointRadians(getArmAngleRadians());
        isOpenLoopRotation = false;

        m_armMain.configForwardSoftLimitThreshold(Conversions.degreesToFalcon(130, ArmConstants.kArmGearRatio),
                0);
        m_armMain.configReverseSoftLimitThreshold(Conversions.degreesToFalcon(-130, ArmConstants.kArmGearRatio), 0);
        m_armMain.configForwardSoftLimitEnable(true, 0);
        m_armMain.configReverseSoftLimitEnable(true, 0);

        m_armMain.setSelectedSensorPosition(0);


        m_armMain.setInverted(TalonFXInvertType.CounterClockwise);
        m_armMain.setNeutralMode(NeutralMode.Brake);

        m_armMain.configVoltageCompSaturation(12);
        m_armMain.enableVoltageCompensation(true);

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

        SupplyCurrentLimitConfiguration rotateArmMainCurrentLimit = new SupplyCurrentLimitConfiguration();
        rotateArmMainCurrentLimit.currentLimit = 40;

        m_armMain.configSupplyCurrentLimit(rotateArmMainCurrentLimit);
    }


    public Command rotateToCommand(Rotation2d angle) {
        return run(() -> setAngleSetpointRadians(angle.getRadians()));
    }


    public void rotateClosedLoop(double velocity) {
        if (getArmAngleRadians() > Units.degreesToRadians(ArmConstants.kForwardSoftLimit)){
            velocity = 0;
        }
        isOpenLoopRotation = false;
        SmartDashboard.putNumber("OUTPUT", velocity);
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

    public void manualArmRotate(double rotateSpeed){
        m_armMain.set(ControlMode.PercentOutput, rotateSpeed * ArmConstants.kRotateArmMultiplier);
    }

    @Override
    public void periodic() {
        SmartDashboard.putNumber("Arm Angle", Units.radiansToDegrees(getArmAngleRadians()));
        if (isOpenLoopRotation) {
        } else {
            SmartDashboard.putNumber("Setpoint", getAngleSetpointRadians());
            SmartDashboard.putNumber("Measurement", getArmAngleRadians());
            SmartDashboard.putNumber("Error", getAngleSetpointRadians() - getArmAngleRadians());
        }
    }
}
