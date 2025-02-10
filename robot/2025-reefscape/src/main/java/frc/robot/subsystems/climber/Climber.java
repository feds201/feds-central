// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.subsystems.climber;

import com.ctre.phoenix6.hardware.CANcoder;
import com.ctre.phoenix6.hardware.TalonFX;
import com.ctre.phoenix6.controls.DutyCycleOut;
import com.ctre.phoenix6.controls.Follower;
import edu.wpi.first.wpilibj.DigitalInput;
import edu.wpi.first.wpilibj.motorcontrol.Talon;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.constants.RobotMap.ClimberMap;
import frc.robot.constants.RobotMap.CurrentLimiter;

public class Climber extends SubsystemBase {
  /** Creates a new Climber. */
  private DigitalInput leftSwitch;
  private DigitalInput rightSwitch;
  private TalonFX climberMotorLeader;
  private TalonFX climberMotorFollower;
  private CANcoder climberEncoder;

  public Climber() {
    climberMotorLeader = new TalonFX(ClimberMap.CLIMBER_LEADER_MOTOR);
    climberMotorLeader.getConfigurator()
        .apply(CurrentLimiter.getCurrentLimitConfiguration(ClimberMap.CLIMBER_CURRENT_LIMIT));
    climberMotorFollower = new TalonFX(ClimberMap.CLIMBER_FOLLOWER_MOTOR);
    climberMotorFollower.getConfigurator()
        .apply(CurrentLimiter.getCurrentLimitConfiguration(ClimberMap.CLIMBER_CURRENT_LIMIT));
    climberMotorFollower.setControl(new Follower(climberMotorLeader.getDeviceID(), false));
    leftSwitch = new DigitalInput(ClimberMap.CLIMBER_LEFT_DI);
    rightSwitch = new DigitalInput(ClimberMap.CLIMBER_RIGHT_DI);
    climberEncoder = new CANcoder(ClimberMap.CLIMBER_ENCODER);

  }

  @Override
  public void periodic() {
    // This method will be called once per scheduler run
  }

  public void setRotateVoltage(double voltage) {
    DutyCycleOut angleVolts = new DutyCycleOut(0);
    climberMotorLeader.setControl(angleVolts.withOutput(voltage));
  }

  public void setPIDTarget(double targetAngle) {
    ClimberMap.climberPID.setSetpoint(targetAngle);
  }

  public double calculatePID(double angle) {
    return ClimberMap.climberPID.calculate(angle);
  }

  public boolean pidAtSetpoint(){
    return ClimberMap.climberPID.atSetpoint();
  }

  public void setPIDTolerance(double tolerance){
    ClimberMap.climberPID.setTolerance(tolerance);
  }

  public boolean getLeftValue() {
    return leftSwitch.get();
  }

  public boolean getRightValue() {
    return rightSwitch.get();
  }

  public double getEncoderValue() {
    return climberEncoder.getPosition().getValueAsDouble();
  }
}
