// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.subsystems.testing;

import com.ctre.phoenix6.hardware.TalonFX;

import edu.wpi.first.wpilibj.motorcontrol.Talon;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.subsystems.feeder.Feeder.feeder_state;
import frc.robot.subsystems.intake.IntakeSubsystem.RollerState;

public class Testing extends SubsystemBase {
  /** Creates a new Terting. */
  private final TalonFX motor;

  public enum MotorState {
    ON,
    OFF
  }
  
  private MotorState currentMotorState = MotorState.OFF;
    
  public void setState(MotorState targetState){
    switch (targetState) {
      case OFF -> {
        currentMotorState = MotorState.OFF;
      }
      case ON -> {
        currentMotorState = MotorState.ON;
      }
    }
    
  } 

  public Testing() {
    motor = new TalonFX(42);
  }

  public Command setStateCommand(MotorState state) {
    return runOnce(() -> setState(state));
  }
 
  public TalonFX getMotor(){
    return motor;
  }

  public MotorState getState() {
    return currentMotorState;
  }

  @Override
  public void periodic() {
    switch (currentMotorState) {
      case ON:
        motor.set(0.2);
        break;
      case OFF:
        motor.set(0);
        break;
    }
  }
}
