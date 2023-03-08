package frc.robot.subsystems;

import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.Constants;

import com.ctre.phoenix.motorcontrol.ControlMode;
import com.ctre.phoenix.motorcontrol.NeutralMode;
import com.ctre.phoenix.motorcontrol.TalonFXControlMode;
import com.ctre.phoenix.motorcontrol.can.*;

public class IntakeSubsystem extends SubsystemBase {

    private final TalonFX intakeDeployMotor;
    private final TalonFX intakeWheelMotor;
    private final boolean invert;

    public IntakeSubsystem(int intakeDeployID, int intakeWheelID, boolean invert) {
        intakeDeployMotor = new TalonFX(intakeDeployID);
        intakeWheelMotor = new TalonFX(intakeWheelID);
        intakeDeployMotor.configVoltageCompSaturation(12);
        intakeWheelMotor.configVoltageCompSaturation(12);
        intakeDeployMotor.enableVoltageCompensation(true);
        intakeWheelMotor.enableVoltageCompensation(true);

        intakeDeployMotor.setNeutralMode(NeutralMode.Brake);
        this.invert = invert;
    }

    public double getPositionEncoderCounts() {
        return intakeDeployMotor.getSelectedSensorPosition();
    }

    public void rotateIntakeForwards() {
        if(invert) {
            intakeDeployMotor.set(TalonFXControlMode.PercentOutput, -Constants.IntakeConstants.kIntakeDeploySpeed);
        } else {
            intakeDeployMotor.set(TalonFXControlMode.PercentOutput, Constants.IntakeConstants.kIntakeDeploySpeed);
        }
    }

    public void rotateIntakeBackwards() {
        if(invert) {
            intakeDeployMotor.set(TalonFXControlMode.PercentOutput, -Constants.IntakeConstants.kIntakeRetractSpeed);
        } else {
            intakeDeployMotor.set(TalonFXControlMode.PercentOutput, Constants.IntakeConstants.kIntakeRetractSpeed);
        }
    }

    public void stopIntakeRotation() {
        intakeDeployMotor.set(TalonFXControlMode.PercentOutput, 0);
    }

    public void runIntakeWheelsIn() {
        intakeWheelMotor.set(TalonFXControlMode.PercentOutput, Constants.IntakeConstants.kIntakeWheelSpeed);
    }

    public void runIntakeWheelsOut() {
        intakeWheelMotor.set(TalonFXControlMode.PercentOutput, -Constants.IntakeConstants.kIntakeWheelSpeed);
    }

    public void stopIntakeWheels() {
        intakeWheelMotor.set(TalonFXControlMode.PercentOutput, 0);
    }
}
