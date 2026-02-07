package frc.robot.subsystems;

import com.ctre.phoenix6.controls.Follower;
import com.ctre.phoenix6.controls.VelocityDutyCycle;
import com.ctre.phoenix6.controls.VoltageOut;
import com.ctre.phoenix6.hardware.TalonFX;
import com.ctre.phoenix6.signals.MotorAlignmentValue;

import edu.wpi.first.units.Units;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.RunCommand;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import frc.robot.RobotMap;

public class IntakeSubsystem extends SubsystemBase {

  private final TalonFX intakeMasterMotor;
  private final TalonFX intakeSlaveMotor;

  public IntakeSubsystem() {
    intakeMasterMotor = new TalonFX(RobotMap.IntakeSubsystemConstants.kIntakeMasterMotorID, "rio");
    intakeSlaveMotor = new TalonFX(RobotMap.IntakeSubsystemConstants.kIntakeSlaveMotorID, "rio");
    intakeSlaveMotor.setControl(new Follower(intakeMasterMotor.getDeviceID(), MotorAlignmentValue.Opposed));
  }

  @Override
  public void periodic() {
    // This method will be called once per scheduler run
    super.periodic();
  }



  public void setintakeMasterMotorSpeed(double speed) {
    intakeMasterMotor.set(speed);
  }

  public void stopintakeMasterMotor() {
    intakeMasterMotor.stopMotor();
  }

  public double getintakeMasterMotorVelocity() {
    return intakeMasterMotor.getVelocity().getValue().in(Units.RotationsPerSecond);
  }

  public void setintakeMasterMotorVoltage(double volts) {
    intakeMasterMotor.setVoltage(volts);
  }

  public double getintakeMasterMotorTemp() {
    return intakeMasterMotor.getDeviceTemp().getValue().in(Units.Celsius);
  }


  public void stopAllMotors() {
    stopintakeMasterMotor();
  }

  public void setAllMotorSpeed(double speed){
    intakeMasterMotor.setControl(new VoltageOut(0.5));
  }
  public Command runIntakeMotors () {
    return new RunCommand(()->setAllMotorSpeed(0.05), this);
  }
  public Command runIntakeMasterMotors () {
    return new RunCommand(()->setintakeMasterMotorSpeed(0.05), this);
  }
  public Command stopIntakeMotors () {
    return new RunCommand(()->stopAllMotors(), this);

  }
}
