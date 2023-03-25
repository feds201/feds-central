package frc.robot.subsystems;

import com.ctre.phoenix.motorcontrol.NeutralMode;
import com.ctre.phoenix.motorcontrol.TalonFXControlMode;
import com.ctre.phoenix.motorcontrol.can.TalonFX;

import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.constants.IntakeConstants;

public class WheelSubsystem extends SubsystemBase{
    private final TalonFX intakeWheelMotor;

    public WheelSubsystem(){
        intakeWheelMotor = new TalonFX(IntakeConstants.kIntakeBlueLeftWheelMotor);

        IntakeConstants.configWheelMotor(intakeWheelMotor);
    }
    
    public void runIntakeWheelsIn() {
        intakeWheelMotor.set(TalonFXControlMode.PercentOutput, IntakeConstants.kIntakeWheelSpeed);
    }

    public void runIntakeWheelsOut() {
        intakeWheelMotor.set(TalonFXControlMode.PercentOutput, -IntakeConstants.kIntakeWheelSpeed);
    }

    public void stopIntakeWheels() {
        intakeWheelMotor.set(TalonFXControlMode.PercentOutput, 0);
        intakeWheelMotor.setNeutralMode(NeutralMode.Brake);
    }
}
