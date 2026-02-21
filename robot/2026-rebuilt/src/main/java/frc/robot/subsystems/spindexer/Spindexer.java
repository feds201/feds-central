// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.subsystems.spindexer;

import static edu.wpi.first.units.Units.Volts;

import com.ctre.phoenix6.configs.TalonFXConfiguration;
import com.ctre.phoenix6.controls.VoltageOut;
import com.ctre.phoenix6.hardware.TalonFX;
import com.ctre.phoenix6.signals.InvertedValue;
import com.ctre.phoenix6.signals.NeutralModeValue;

import edu.wpi.first.epilogue.Logged;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.Voltage;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.RobotMap.SpindexerConstants;
import frc.robot.utils.DeviceTempReporter;
import frc.robot.utils.SubsystemStatusManager;

@Logged
public class Spindexer extends SubsystemBase {

  //subsystem states 
  public enum spindexer_state {
    RUN(Volts.of(3)),
    STOP(Volts.of(0));

    private final Voltage targetPosition;

    spindexer_state(Voltage targetPosition) {
      this.targetPosition = targetPosition;
    }

    public Voltage getVoltage() {
      return targetPosition;
    }
  }

  //susbsytem components
private final TalonFX spindexerMotor;
private final TalonFXConfiguration config;
private final VoltageOut vOut = new VoltageOut(0);
private spindexer_state currentState = spindexer_state.STOP;

  public Spindexer() {
    spindexerMotor = new TalonFX(SpindexerConstants.kSpindexerMotorId);

    config = new TalonFXConfiguration();
    config.MotorOutput.NeutralMode = NeutralModeValue.Coast;
    config.MotorOutput.Inverted = InvertedValue.Clockwise_Positive;
    config.CurrentLimits.StatorCurrentLimit = 20;
    for (int i = 0; i < 2; ++i){
      var status = spindexerMotor.getConfigurator().apply(config);
      if(status.isOK()) break;
    }

    SubsystemStatusManager.addSubsystem(getName(), spindexerMotor);
    DeviceTempReporter.addDevices(spindexerMotor);
   }

   
  @Override
  public void periodic() {
  }

  // subsystem getters
public Angle getPosition(){
    return spindexerMotor.getPosition().getValue();
  }
  
public Voltage getAppliedVoltage() {
  return spindexerMotor.getMotorVoltage().getValue();
}

public Voltage getTargetVoltage(){
  return currentState.getVoltage();
}

  //subsystem setters
public void setVoltage(Voltage voltage)
{
  spindexerMotor.setControl(vOut.withOutput(voltage));
}

public void setState(spindexer_state state)
{
  setVoltage(state.getVoltage());
  currentState = state;
}

  //move to state commands
  public Command moveToState(spindexer_state state){
    return new InstantCommand(() -> setState(state));
  }

  public Command commandRun(){
    return new InstantCommand(() -> setState(spindexer_state.RUN));
  }

  public Command commandStop(){
    return new InstantCommand(() -> setState(spindexer_state.STOP));
  }
}
