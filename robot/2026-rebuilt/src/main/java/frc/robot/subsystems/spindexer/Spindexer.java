// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.subsystems.spindexer;

import static edu.wpi.first.units.Units.Meters;
import static edu.wpi.first.units.Units.RotationsPerSecond;
import static edu.wpi.first.units.Units.Second;
import static edu.wpi.first.units.Units.Volts;

import com.ctre.phoenix6.SignalLogger;
import com.ctre.phoenix6.configs.TalonFXConfiguration;
import com.ctre.phoenix6.controls.VoltageOut;
import com.ctre.phoenix6.hardware.TalonFX;
import com.ctre.phoenix6.signals.InvertedValue;
import com.ctre.phoenix6.signals.NeutralModeValue;

import org.littletonrobotics.junction.Logger;
import edu.wpi.first.epilogue.Logged;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.Voltage;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import com.ctre.phoenix6.controls.MotionMagicVelocityVoltage;
import com.ctre.phoenix6.controls.VoltageOut;
import frc.robot.RobotMap.SpindexerConstants;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.utils.DeviceTempReporter;
import frc.robot.utils.SubsystemStatusManager;
import edu.wpi.first.wpilibj2.command.sysid.SysIdRoutine;



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
  private final SysIdRoutine m_spindexerSysId;

  // private final SysIdRoutine m_SpindexerSysId;



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

     m_spindexerSysId = new SysIdRoutine(
    new SysIdRoutine.Config(
      Volts.of(0.5).per(Second),                // default ramp (or Volts.of(x).per(Second) if you want custom)
      Volts.of(3),          // dynamic step voltage: start with something conservative (4-6 V)
      null,                // default timeout
      state -> SignalLogger.writeString("SysId_Spindexer_State", state.toString()) // log state string
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
    Logger.recordOutput("Robot/Shooter/SpindexerOn", currentState == spindexer_state.RUN);
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

public spindexer_state getCurrentState() {
  return currentState;
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

  // public Command SpindexerSysIdQuasistatic(SysIdRoutine.Direction dir) { return m_SpindexerSysId.quasistatic(dir); }
  // public Command SpinfexerSysIdDynamic(SysIdRoutine.Direction dir) { return m_SpindexerSysId.dynamic(dir); }

  public Command commandRun(){
    return new InstantCommand(() -> setState(spindexer_state.RUN));
  }

  public Command commandStop(){
    return new InstantCommand(() -> setState(spindexer_state.STOP));
  }

  
public Command setStateCommand(spindexer_state state) {
    return runOnce(() -> setState(state));
}
}
