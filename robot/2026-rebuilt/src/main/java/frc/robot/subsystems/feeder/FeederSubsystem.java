package frc.robot.subsystems.feeder;

import static edu.wpi.first.units.Units.Second;
import static edu.wpi.first.units.Units.Seconds;
import static edu.wpi.first.units.Units.Volts;

import com.ctre.phoenix6.SignalLogger;
import com.ctre.phoenix6.hardware.TalonFX;
import org.littletonrobotics.junction.Logger;

import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.AngularVelocity;
import edu.wpi.first.units.measure.Current;
import edu.wpi.first.units.measure.Voltage;
import edu.wpi.first.wpilibj.Timer;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import edu.wpi.first.wpilibj2.command.sysid.SysIdRoutine;
import frc.robot.RobotMap.indexingConstants;
import frc.robot.utils.DeviceTempReporter;
import frc.robot.utils.SubsystemStatusManager;

public class FeederSubsystem extends SubsystemBase {

  public enum feeder_state {
    RUN(Volts.of(8.5)), PRUN(Volts.of(8.5)), REVERSE(Volts.of(-8.5)), PREVERSE(
        Volts.of(-8.5)), STOP(Volts.of(0));

    private final Voltage targetVoltage;

    feeder_state(Voltage targetVoltage) {
      this.targetVoltage = targetVoltage;
    }

    public Voltage getVoltage() {
      return targetVoltage;
    }
  }

  private final FeederIO io;
  private final FeederIOInputsAutoLogged inputs = new FeederIOInputsAutoLogged();

  private feeder_state currentState = feeder_state.STOP;
  private final SysIdRoutine m_feederSysId;
  private final Timer timer = new Timer();

  public FeederSubsystem(FeederIO io) {
    this.io = io;

    m_feederSysId = new SysIdRoutine(
        new SysIdRoutine.Config(Volts.of(0.5).per(Second), Volts.of(3), Seconds.of(5),
            state -> SignalLogger.writeString("SysId_Feeder_State", state.toString())),
        new SysIdRoutine.Mechanism(io::runSysIdRoutine, null, this));
  }

  @Override
  public void periodic() {
    io.updateInputs(inputs);
    Logger.processInputs("Feeder", inputs);

    Logger.recordOutput("Robot/Shooter/FeederOn", currentState != feeder_state.STOP);
    Logger.recordOutput("Robot/Shooter/FeederState", currentState.toString());
    Logger.recordOutput("Robot/Feeder/TargetVolts", currentState.getVoltage().in(Volts));

    switch (currentState) {
      case RUN:
        if (timer.hasElapsed(indexingConstants.forwardTime)) {
          setState(feeder_state.REVERSE);
        }
        break;

      case REVERSE:
        if (timer.hasElapsed(indexingConstants.reverseTime)) {
          setState(feeder_state.RUN);
        }
        break;

      default:
        break;
    }
  }

  public Angle getPosition() {
    return inputs.feederMotorPosition;
  }

  public AngularVelocity getFeederVelocity() {
    return inputs.feederMotorVelocity;
  }

  public Voltage getAppliedVoltage() {
    return inputs.feederMotorAppliedVoltage;
  }

  public Current getCurrent() {
    return inputs.feederMotorCurrent;
  }

  public Voltage getTargetVoltage() {
    return currentState.getVoltage();
  }

  public feeder_state getCurrentState() {
    return currentState;
  }

  public void setVoltage(Voltage voltage) {
    io.setVoltage(voltage);
  }

  public void setState(feeder_state state) {
    if (currentState != state) {
      timer.reset();
      timer.start();
    }

    setVoltage(state.getVoltage());
    currentState = state;
  }

  public Command setStateCommand(feeder_state state) {
    return runOnce(() -> setState(state));
  }

  public Command commandRun() {
    return new InstantCommand(() -> setState(feeder_state.RUN));
  }

  public Command commandStop() {
    return new InstantCommand(() -> setState(feeder_state.STOP));
  }

  public Command feederSysIdQuasistatic(SysIdRoutine.Direction dir) {
    return m_feederSysId.quasistatic(dir);
  }

  public Command feederSysIdDynamic(SysIdRoutine.Direction dir) {
    return m_feederSysId.dynamic(dir);
  }
}
