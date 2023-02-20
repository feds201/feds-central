package frc.robot.subsystems;

import com.ctre.phoenix.motorcontrol.TalonFXControlMode;
import com.ctre.phoenix.motorcontrol.TalonFXFeedbackDevice;
import com.ctre.phoenix.motorcontrol.can.TalonFX;

import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.Constants.ClawConstants;

public class ClawSubsystem extends SubsystemBase{
    private final int kPIDLoopIdx = 0;
    private final boolean kSensorPhase = true;
    private final double kP = 0.15;
    private final double kI = 0;
    private final double kD = 1.0;
    private final double kF = 0.0;
    private final int kIzone = 0;
    private final double kPeakOutput = 0.20;
    private final int kTimeoutMs = 30;

    private final TalonFX m_clawMotor;

    private final double kOpenClawPosition = 480;
    private final double kBallClawPosition = 254;
    private final double kConeClawPosition = 100;

    public ClawSubsystem(){
        m_clawMotor = new TalonFX(ClawConstants.kClawMotor);

        configMotor(m_clawMotor);
          
    }

    private void configMotor(TalonFX motor) {
        motor.configFactoryDefault();
        motor.configSelectedFeedbackSensor(TalonFXFeedbackDevice.IntegratedSensor, kPIDLoopIdx, kTimeoutMs);

        motor.setSensorPhase(kSensorPhase);

        motor.configNominalOutputForward(0, kTimeoutMs);
        motor.configNominalOutputReverse(0, kTimeoutMs);

        motor.configPeakOutputForward(kPeakOutput, kTimeoutMs);
        motor.configPeakOutputReverse(-kPeakOutput, kTimeoutMs);

        motor.configAllowableClosedloopError(0, kPIDLoopIdx, kTimeoutMs);

        motor.config_kF(kPIDLoopIdx, kF, kTimeoutMs);
        motor.config_kP(kPIDLoopIdx, kP, kTimeoutMs);
        motor.config_kI(kPIDLoopIdx, kI, kTimeoutMs);
        motor.config_kD(kPIDLoopIdx, kD, kTimeoutMs);
    }

    public void openClaw() {
        m_clawMotor.set(TalonFXControlMode.Position, kOpenClawPosition);
    }

    public void holdBall() {
        m_clawMotor.set(TalonFXControlMode.Position, kBallClawPosition);
    }

    public void holdCone() {
        m_clawMotor.set(TalonFXControlMode.Position, kConeClawPosition);
    }

    public void stopClaw() {
        m_clawMotor.set(TalonFXControlMode.PercentOutput, 0);
    }

    public double getClawPosition(){
        return m_clawMotor.getSelectedSensorPosition();
    }

    @Override
    public void periodic() {
        SmartDashboard.putNumber("Claw Encoder Count", getClawPosition());
    }
}
