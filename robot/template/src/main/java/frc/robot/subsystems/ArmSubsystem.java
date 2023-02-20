package frc.robot.subsystems;

import com.ctre.phoenix.motorcontrol.TalonFXControlMode;
import com.ctre.phoenix.motorcontrol.TalonFXFeedbackDevice;
import com.ctre.phoenix.motorcontrol.can.TalonFX;

import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.Constants.ArmConstants;

public class ArmSubsystem extends SubsystemBase{
    
    private final TalonFX rotateMotor1;
    private final TalonFX rotateMotor2;
 
    private final int kPIDLoopIdx = 0;
    private final boolean kSensorPhase = true;
    private final double kP = 0.15;
    private final double kI = 0.0;
    private final double kD = 1.0;
    private final double kF = 0.0;
    private final int kIzone = 0;
    private final double kPeakOutput = 0.08;
    private final int kTimeoutMs = 30;

    private boolean m_dangerMode = false;

    public ArmSubsystem(){
        rotateMotor1 = new TalonFX(ArmConstants.kArmMotor1);
        rotateMotor2 = new TalonFX(ArmConstants.kArmMotor2);

        configMotor(rotateMotor1);
        configMotor(rotateMotor2);

        rotateMotor2.follow(rotateMotor1);
    }

    public void configMotor(TalonFX motor) {
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

    public void rotateArmTo(double encoderPosition) {
        rotateMotor1.set(TalonFXControlMode.Position, encoderPosition);
    }

    public double getArmRotationPosition(){
        return rotateMotor1.getSelectedSensorPosition();
    }

    public void toggleDangerMode() {
        if(m_dangerMode) {
            m_dangerMode = false;
        } else {
            m_dangerMode = true;
        }
    }


    public boolean getDangerMode() {
        return m_dangerMode;
    }

    @Override
    public void periodic(){
       SmartDashboard.putNumber("Sensor Position", rotateMotor1.getSelectedSensorPosition());
       SmartDashboard.putNumber("Sensor Velocity", rotateMotor1.getSelectedSensorVelocity());
       SmartDashboard.putBoolean("Danger Mode", getDangerMode());
    }
}






























