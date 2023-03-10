package frc.robot.subsystems;

import com.ctre.phoenix.motorcontrol.ControlMode;
import com.ctre.phoenix.motorcontrol.StatusFrameEnhanced;
import com.ctre.phoenix.motorcontrol.TalonFXControlMode;
import com.ctre.phoenix.motorcontrol.TalonFXFeedbackDevice;
import com.ctre.phoenix.motorcontrol.can.TalonFX;

import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.Constants.ClawConstants;

public class ClawSubsystem extends SubsystemBase{
    private final TalonFX m_clawMotor;


    public ClawSubsystem(){
        m_clawMotor = new TalonFX(ClawConstants.kClawMotor);

        m_clawMotor.configFactoryDefault();
        m_clawMotor.configSelectedFeedbackSensor(TalonFXFeedbackDevice.IntegratedSensor, 0, 30);

        m_clawMotor.setSelectedSensorPosition(0);

        m_clawMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_1_General, 255);
		m_clawMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_2_Feedback0, 10);
		m_clawMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_3_Quadrature, 255);
		m_clawMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_4_AinTempVbat, 255);
		m_clawMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_8_PulseWidth, 255);
		m_clawMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_10_Targets, 255);
		m_clawMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_12_Feedback1, 255);
		m_clawMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_13_Base_PIDF0, 255);
		m_clawMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_14_Turn_PIDF1, 255);
		m_clawMotor.setStatusFramePeriod(StatusFrameEnhanced.Status_Brushless_Current, 255);

        m_clawMotor.configVoltageCompSaturation(12);
        m_clawMotor.enableVoltageCompensation(true);
        m_clawMotor.configForwardSoftLimitThreshold(1000);
        m_clawMotor.configReverseSoftLimitThreshold(-1000);
        m_clawMotor.configForwardSoftLimitEnable(true, 0);
        m_clawMotor.configReverseSoftLimitEnable(true, 0);
    }


    public void openClaw() {
        m_clawMotor.set(ControlMode.PercentOutput, -ClawConstants.kExtendSpeed);
    }

    // public void holdBall() {
    //     m_clawMotor.set(ControlMode.PercentOutput, ClawConstants.kHoldBallSpeed);
    // }

    // public void holdCone() {
    //     m_clawMotor.set(ControlMode.PercentOutput, ClawConstants.kHoldConeSpeed);
    // }

    public void stopClaw() {
        m_clawMotor.set(TalonFXControlMode.PercentOutput, 0);
    }

    // public double getClawPosition() {
    //     return m_clawMotor.getSelectedSensorPosition();
    // }

    @Override
    public void periodic() {
        // SmartDashboard.putNumber("Claw Encoder Count", getClawPosition());
    }
}
