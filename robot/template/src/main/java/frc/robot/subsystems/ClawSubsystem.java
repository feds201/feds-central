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

    public void intakeCone() {
        m_clawMotor.set(ControlMode.PercentOutput, ClawConstants.kIntakeConePercent);
    }

    public void outtakeCone() {
        m_clawMotor.set(ControlMode.PercentOutput, ClawConstants.kOuttakeConePercent);
    }

    public void stopClaw() {
        m_clawMotor.set(ControlMode.PercentOutput, 0);
    }

    // @Override
    // public void periodic() {
    // }
}
