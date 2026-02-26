// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.subsystems.feeder;

import static edu.wpi.first.units.Units.Second;
import static edu.wpi.first.units.Units.Volts;

import com.ctre.phoenix6.SignalLogger;
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
import edu.wpi.first.wpilibj2.command.sysid.SysIdRoutine;
import frc.robot.RobotMap.SpindexerConstants;
import frc.robot.subsystems.shooter.ShooterHood.shooterhood_state;
import frc.robot.utils.DeviceTempReporter;
import frc.robot.utils.SubsystemStatusManager;

@Logged
public class Feeder extends SubsystemBase {

  //subsystem states 
  public enum feeder_state {
    RUN(Volts.of(3)),
    STOP(Volts.of(0));

    private final Voltage targetPosition;

    feeder_state(Voltage targetPosition) {
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
private feeder_state currentState = feeder_state.STOP;
private final SysIdRoutine m_feederSysId;


  public Feeder() {
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

    m_feederSysId = new SysIdRoutine(
    new SysIdRoutine.Config(
      Volts.of(0.5).per(Second),                // default ramp (or Volts.of(x).per(Second) if you want custom)
      Volts.of(3),          // dynamic step voltage: start with something conservative (4-6 V)
      null,                // default timeout
      state -> SignalLogger.writeString("SysId_Feeder_State", state.toString()) // log state string
    ),
    new SysIdRoutine.Mechanism(
      // apply voltage request -> set CTRE motor VoltageOut
      voltsMeasure -> {
        // voltsMeasure is a Measure<Voltage>
        double volts = voltsMeasure.in(Volts); // numeric voltage (e.g. 0..12)
        // phoenix6: setControl with VoltageOut (applies volts to motor)
        spindexerMotor.setControl(new VoltageOut(volts));
        // if you have follower motors, set them appropriately (use followers or set same request for each)
         SignalLogger.writeDouble("Rotational_Rate", voltsMeasure.in(Volts));
      },
      // logging callback: when using CTRE SignalLogger set this to null (CTRE logs motor signals automatically)
      null,
      this // subsystem for command requirements
    )
  );
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

public feeder_state getCurrentState() {
  return currentState;
}

public void setState(feeder_state state)
{
  setVoltage(state.getVoltage());
  currentState = state;
}
public Command setStateCommand(feeder_state state) {
    return runOnce(() -> setState(state));
  } 
  //move to state commands
  public Command moveToState(feeder_state state){
    return new InstantCommand(() -> setState(state));
  }

  public Command commandRun(){
    return new InstantCommand(() -> setState(feeder_state.RUN));
  }

  public Command commandStop(){
    return new InstantCommand(() -> setState(feeder_state.STOP));
  }
}
