package frc.robot.subsystems;

import com.ctre.phoenix.motorcontrol.ControlMode;
import com.ctre.phoenix.motorcontrol.InvertType;
import com.ctre.phoenix.motorcontrol.StatusFrameEnhanced;
import com.ctre.phoenix.motorcontrol.TalonFXControlMode;
import com.ctre.phoenix.motorcontrol.TalonFXFeedbackDevice;
import com.ctre.phoenix.motorcontrol.TalonFXInvertType;
import com.ctre.phoenix.motorcontrol.can.TalonFX;

import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.constants.ClawConstants;

public class ClawSubsystem extends SubsystemBase{
    private final TalonFX m_clawMotor;
    private final TalonFX m_clawMotor2;


    public ClawSubsystem(){
        m_clawMotor = new TalonFX(ClawConstants.kClawMotorMain);
        m_clawMotor2 = new TalonFX(ClawConstants.kClawMotorFollow);
        ClawConstants.configMotor(m_clawMotor); 
        ClawConstants.configMotor(m_clawMotor2);

        m_clawMotor2.follow(m_clawMotor);
        m_clawMotor2.setInverted(InvertType.OpposeMaster);
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
