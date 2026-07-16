package frc.robot.subsystems.spindexer;

import static edu.wpi.first.units.Units.Second;
import static edu.wpi.first.units.Units.Volts;
import org.littletonrobotics.junction.Logger;
import com.ctre.phoenix6.SignalLogger;
import com.ctre.phoenix6.hardware.TalonFX;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.AngularVelocity;
import edu.wpi.first.units.measure.Current;
import edu.wpi.first.units.measure.Temperature;
import edu.wpi.first.units.measure.Voltage;
import edu.wpi.first.wpilibj.Timer;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import edu.wpi.first.wpilibj2.command.sysid.SysIdRoutine;
import frc.robot.RobotMap.indexingConstants;

public class SpindexerSubsystem extends SubsystemBase {

  // subsystem states
  public enum spindexer_state {
    RUN(Volts.of(8)), REVERSE(Volts.of(-8)), PREVERSE(Volts.of(-8)), PFORWARD(Volts.of(8)), STOP(
        Volts.of(0));

    private final Voltage targetPosition;

    spindexer_state(Voltage targetPosition) {
      this.targetPosition = targetPosition;
    }

    public Voltage getVoltage() {
      return targetPosition;
    }
  }

  private spindexer_state currentState = spindexer_state.STOP;
  private final SysIdRoutine m_spindexerSysId;
  private Timer timer = new Timer();
  private final SpindexerIO spindexerIO;
  private final SpindexerIOInputsAutoLogged inputs = new SpindexerIOInputsAutoLogged();

  public SpindexerSubsystem(SpindexerIO spindexerIO) {
    this.spindexerIO = spindexerIO;

    m_spindexerSysId = new SysIdRoutine(new SysIdRoutine.Config(Volts.of(0.5).per(Second), // default
        // ramp
        // (or
        // Volts.of(x).per(Second)
        // if you
        // want
        // custom)
        Volts.of(3), // dynamic step voltage: start with something conservative (4-6 V)
        null, // default timeout
        state -> SignalLogger.writeString("SysId_Spindexer_State", state.toString()) // log state
    // string
    ), new SysIdRoutine.Mechanism(
        // apply voltage request -> set CTRE motor VoltageOut
        voltsMeasure -> {
          // phoenix6: setControl with VoltageOut (applies volts to motor)
          spindexerIO.runSysIdRoutine(voltsMeasure);
          // if you have follower motors, set them appropriately (use followers or set same request
          // for each)
          SignalLogger.writeDouble("Rotational_Rate", voltsMeasure.in(Volts));
        },
        // logging callback: when using CTRE SignalLogger set this to null (CTRE logs motor signals
        // automatically)
        null, this // subsystem for command requirements
    ));
  }

  @Override
  public void periodic() {

    spindexerIO.updateInputs(inputs);

    Logger.processInputs("Spindexer", inputs);

    Logger.recordOutput("Robot/Shooter/SpindexerOn", currentState != spindexer_state.STOP);

    Logger.recordOutput("Robot/Shooter/SpindexerState", currentState.toString());

    Logger.recordOutput("Robot/Spindexer/TargetVolts", currentState.getVoltage().in(Volts));

    switch (currentState) {

      case RUN:

        if (timer.hasElapsed(indexingConstants.forwardTime))
          setState(spindexer_state.REVERSE);

        break;

      case REVERSE:

        if (timer.hasElapsed(indexingConstants.reverseTime))
          setState(spindexer_state.RUN);

        break;

      default:
        break;
    }
  }

  public Angle getPosition() {
    return inputs.spindexerMotorPosition;
  }

  public Voltage getAppliedVoltage() {
    return inputs.spindexerMotorAppliedVoltage;
  }

  public Current getCurrent() {
    return inputs.spindexerMotorCurrent;
  }

  public AngularVelocity getVelocity() {
    return inputs.spindexerMotorVelocity;
  }

  public Temperature getTemperature() {
    return inputs.spindexerMotorTemp;
  }

  public Angle getTargetPosition() {
    return inputs.spindexerMotorPosition;
  }

  public spindexer_state getCurrentState() {
    return currentState;
  }

  public Voltage getTargetVoltage() {
    return currentState.getVoltage();
  }

  public void setVoltage(Voltage voltage) {
    spindexerIO.setVoltage(voltage);
  }

  public void setState(spindexer_state state) {
    if (!currentState.equals(state)) {
      timer.reset();
      timer.stop();
      timer.start();
    }
    setVoltage(state.getVoltage());
    currentState = state;
  }

  public Command setStateCommand(spindexer_state state) {
    return runOnce(() -> setState(state));
  }
}
