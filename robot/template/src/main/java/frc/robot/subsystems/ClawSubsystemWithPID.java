package frc.robot.subsystems;

import com.ctre.phoenix.motorcontrol.TalonFXControlMode;
import com.ctre.phoenix.motorcontrol.TalonFXFeedbackDevice;
import com.ctre.phoenix.motorcontrol.can.TalonFX;

import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.lib.math.Conversions;
import frc.robot.constants.ClawConstants;

public class ClawSubsystemWithPID extends SubsystemBase{

    private final TalonFX m_clawMotor;


    public ClawSubsystemWithPID(){
        m_clawMotor = new TalonFX(ClawConstants.kClawMotor);
        ClawConstants.configPIDMotor(m_clawMotor);
    }

    public void openClaw() {
        m_clawMotor.set(TalonFXControlMode.Position, ClawConstants.kOpenClawPosition);
    }

    public void kickOutClaw(){
        m_clawMotor.set(TalonFXControlMode.Position, ClawConstants.kKickClawPosition);
    }

    public void stopClaw() {
        m_clawMotor.set(TalonFXControlMode.PercentOutput, 0);
    }

    public void closeClaw() {
        m_clawMotor.set(TalonFXControlMode.PercentOutput, ClawConstants.kClosePower);
    }

    public double getClawPosition(){
        return m_clawMotor.getSelectedSensorPosition();
    }

    @Override
    public void periodic() {
        SmartDashboard.putNumber("Claw Encoder Count", getClawPosition());
    }
}
