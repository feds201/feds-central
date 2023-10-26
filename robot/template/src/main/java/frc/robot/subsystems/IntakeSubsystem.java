package frc.robot.subsystems;

import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.constants.IntakeConstants;

import com.ctre.phoenix.motorcontrol.ControlMode;
import com.ctre.phoenix.motorcontrol.can.*;

public class IntakeSubsystem extends SubsystemBase {

    private final TalonFX intakeDeployMotor;

    public IntakeSubsystem() {
        intakeDeployMotor = new TalonFX(IntakeConstants.kIntakeBlueLeftDeployMotor);
        IntakeConstants.configIntakeMotor(intakeDeployMotor);
        intakeDeployMotor.setSelectedSensorPosition(0);
    }

    public double getPositionEncoderCounts() {
        return intakeDeployMotor.getSelectedSensorPosition();
    }

    public void setIntakePosition(double position){
        intakeDeployMotor.set(ControlMode.MotionMagic, position);
    }

    public void rotateIntakeManual(double power){
        intakeDeployMotor.set(ControlMode.PercentOutput, power);
    }

    public boolean hitForwardSoftLimit(){
        return getPositionEncoderCounts() >= IntakeConstants.kIntakeForwardSetpoint;
    }
    
    public boolean hitReverseSoftLimit(){
        return getPositionEncoderCounts() <= IntakeConstants.kIntakeRetractSetpoint;
    }
}
