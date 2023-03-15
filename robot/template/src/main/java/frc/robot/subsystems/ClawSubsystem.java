package frc.robot.subsystems;

import com.ctre.phoenix.motorcontrol.ControlMode;
import com.ctre.phoenix.motorcontrol.StatusFrameEnhanced;
import com.ctre.phoenix.motorcontrol.TalonFXControlMode;
import com.ctre.phoenix.motorcontrol.TalonFXFeedbackDevice;
import com.ctre.phoenix.motorcontrol.can.TalonFX;

import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.constants.ClawConstants;

public class ClawSubsystem extends SubsystemBase{
    private final TalonFX m_clawMotor;


    public ClawSubsystem(){
        m_clawMotor = new TalonFX(ClawConstants.kClawMotor);

        ClawConstants.configMotor(m_clawMotor);
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
