package frc.robot.subsystems;

import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.constants.IntakeConstants;

import com.ctre.phoenix.motorcontrol.ControlMode;
import com.ctre.phoenix.motorcontrol.TalonFXControlMode;
import com.ctre.phoenix.motorcontrol.can.*;

public class IntakeSubsystem extends SubsystemBase {

    private final TalonFX intakeDeployMotor;
    private final TalonFX intakeWheelMotor;

    public IntakeSubsystem() {
        intakeDeployMotor = new TalonFX(IntakeConstants.kIntakeBlueLeftDeployMotor);
        intakeWheelMotor = new TalonFX(IntakeConstants.kIntakeBlueLeftWheelMotor);
        IntakeConstants.configIntakeMotor(intakeDeployMotor);
        IntakeConstants.configWheelMotor(intakeWheelMotor);
    }

    public double getPositionEncoderCounts() {
        return intakeDeployMotor.getSelectedSensorPosition();
    }

    public void rotateIntakeForwards() {
        intakeDeployMotor.set(TalonFXControlMode.PercentOutput, IntakeConstants.kIntakeDeploySpeed);
    }

    public void rotateIntakeBackwards() {
        intakeDeployMotor.set(TalonFXControlMode.PercentOutput, IntakeConstants.kIntakeRetractSpeed);
    }

    public void stopIntakeRotation() {
        intakeDeployMotor.set(TalonFXControlMode.PercentOutput, 0);
    }

    public void runIntakeWheelsIn() {
        intakeWheelMotor.set(TalonFXControlMode.PercentOutput, IntakeConstants.kIntakeWheelSpeed);
    }

    public void runIntakeWheelsOut() {
        intakeWheelMotor.set(TalonFXControlMode.PercentOutput, -IntakeConstants.kIntakeWheelSpeed);
    }

    public void stopIntakeWheels() {
        intakeWheelMotor.set(TalonFXControlMode.PercentOutput, 0);
    }

    public void setIntakePosition(double position){
        intakeDeployMotor.set(ControlMode.MotionMagic, position);
    }

    public boolean hitSoftLimit(){
        return (getPositionEncoderCounts() > IntakeConstants.kIntakeForwardSoftLimit || getPositionEncoderCounts() < IntakeConstants.kIntakeRetractSoftLimit);
    }
}
