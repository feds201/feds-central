package frc.robot.subsystems.intake;

import static edu.wpi.first.units.Units.Rotations;
import org.littletonrobotics.junction.Logger;
import com.ctre.phoenix6.hardware.TalonFX;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.AngularVelocity;
import edu.wpi.first.units.measure.Current;
import edu.wpi.first.units.measure.Voltage;
import edu.wpi.first.wpilibj.DigitalInput;
import edu.wpi.first.wpilibj.Timer;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.Commands;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.RobotMap.IntakeSubsystemConstants;

public class Intake extends SubsystemBase {
  public enum IntakeState {
    DEFAULT, // Retracted, assumed to be starting state
    EXTENDED, // Fully extended
    INTAKING, // Fully extended with rollers on, used for actively intaking fuel

    // State loop 1: Agitate
    AGITATE_IN, // Inwards portion of the agitate state-loop, intake will toggle between the
                // agitates on a timer
                // when set to one of these states
    AGITATE_OUT, // Agitation causes the intake to move outwards, then inwards back to default in
                 // order to agitate
                 // the fuel in the full hopper

    // State loop 2: Close Agitation
    CLOSE_AGITATION_IN, // Inwards portion of the close agitation state-loop, intake will toggle
                        // between the close agitates
                        // on a timer when set to one of these states
    CLOSE_AGITATION_OUT, // Close agitation causes the intake to move outwards, then inwards about
                         // halfway to extended in
                         // order to agitate the close half of the hopper

    FAR_AGITATION_IN, // Inwards portion of the far agitation state-loop, intake will toggle between
                      // the far agitates on a
                      // timer when set to one of these states
    FAR_AGITATION_OUT, // Far agitation causes the intake to move outwards

    // State loop 3: Dither Agitation (experimental, may not be used)
    DITHERIN_AGITATION, // Inwards portion of dithering state-loop, intake will toggle between the
                        // dithers on a timer when
                        // set to one of these states
    DITHEROUT_AGITATION // Dithering causes the intake to move inwards, then outwards half as much
                        // in order to slowly bring
                        // in the intake while also agitating
  }

  public enum RollerState {
    ON, AGITATEON, OFF, REVERSE,
  }

  private final RackIO rackIO;
  private final RollerIO rollerIO;
  private final RackIOInputsAutoLogged rackInputs = new RackIOInputsAutoLogged();
  private final RollerIOInputsAutoLogged rollerInputs = new RollerIOInputsAutoLogged();

  private IntakeState currentState = IntakeState.DEFAULT;
  private RollerState currentRollerState = RollerState.OFF;
  private final Timer timer = new Timer();

  public Intake(RackIO rackIO, RollerIO rollerIO) {
    this.rackIO = rackIO;
    this.rollerIO = rollerIO;
  }


  @Override
  public void periodic() {
    rackIO.updateInputs(rackInputs);
    rollerIO.updateInputs(rollerInputs);

    Logger.processInputs("Intake Rack", rackInputs);
    Logger.processInputs("Intake Roller", rollerInputs);
    switch (currentState) {
      case AGITATE_IN:
        if (timer.hasElapsed(IntakeSubsystemConstants.agitateCycleConstant)) {
          setRackState(IntakeState.AGITATE_OUT);
        }
        break;

      case AGITATE_OUT:
        if (timer.hasElapsed(IntakeSubsystemConstants.agitateCycleConstant)) {
          setRackState(IntakeState.AGITATE_IN);
        }
        break;

      case FAR_AGITATION_IN:
        if (timer.hasElapsed(.2)) {
          setRackState(IntakeState.FAR_AGITATION_OUT);
        }
        break;

      case FAR_AGITATION_OUT:
        if (timer.hasElapsed(.2)) {
          setRackState(IntakeState.FAR_AGITATION_IN);
        }
        break;

      case CLOSE_AGITATION_OUT:
        if (timer.hasElapsed(0.2)) {
          setRackState(IntakeState.CLOSE_AGITATION_IN); // really close to default
        }
        break;

      case CLOSE_AGITATION_IN:
        if (timer.hasElapsed(0.2)) {
          setRackState(IntakeState.CLOSE_AGITATION_OUT); // about halfway from bumper to extended
        }
        break;

      case DITHERIN_AGITATION:
        rackIO.set(-0.3);

        if (timer.hasElapsed(0.3)) {
          setRackState(IntakeState.DITHEROUT_AGITATION);
        }
        break;

      case DITHEROUT_AGITATION:
        rackIO.set(0.3);

        if (timer.hasElapsed(0.1)) {
          setRackState(IntakeState.DITHERIN_AGITATION); // small retract from extended
        }
        break;

      case INTAKING:
        rackIO.limitSwitchExtensionControl();
        break;

      case EXTENDED:
        rackIO.limitSwitchExtensionControl();
        break;
    }


    switch (currentRollerState) {
      case ON:
        rollerIO.set(IntakeSubsystemConstants.ROLLER_OUTPUT);
        break;
      case AGITATEON:
        rollerIO.set(IntakeSubsystemConstants.AGITATE_OUTPUT);
        break;
      case REVERSE:
        rollerIO.set(-IntakeSubsystemConstants.ROLLER_OUTPUT);
        break;
      case OFF:
      default:
        rollerIO.stop();
        break;
    }

    Logger.recordOutput("Robot/Intake/State", currentState.toString());
    Logger.recordOutput("Robot/Intake/Extended", currentState != IntakeState.DEFAULT);
    Logger.recordOutput("Robot/Intake/ExtensionPct", Math.round(100.0
        * rackInputs.rackMotorPosition.in(Rotations) / IntakeSubsystemConstants.extendedRotations));
    Logger.recordOutput("Robot/Intake/PositionRotations",
        rackInputs.rackMotorPosition.in(Rotations));
    // //TODO: make a better solution for this; will cause code crash in sim
    // Logger.recordOutput("Robot/Intake/TargetPositionRotations",
    // rackIO.getIntakeMotor().getClosedLoopReference().getValueAsDouble());
    Logger.recordOutput("Robot/IntakeRoller/State", currentRollerState.toString());

    super.periodic();
  }

  public void setRackState(IntakeState targetState) {
    if (!currentState.equals(targetState)) {
      timer.reset();
      timer.stop();
      timer.start();
    }
    this.currentState = targetState;
    switch (targetState) {
      case DEFAULT -> {
        setPosition(IntakeSubsystemConstants.retractedRotations);
      }
      case EXTENDED -> {
        rackIO.limitSwitchExtensionControl();
        setRollerState(RollerState.OFF);
      }
      case CLOSE_AGITATION_IN -> {
        setPosition(0.0);
      }
      case INTAKING -> {
        rackIO.limitSwitchExtensionControl();
        setRollerState(RollerState.ON);
      }
      case AGITATE_IN -> {
        setPosition(IntakeSubsystemConstants.retractedRotations);
      }
      case AGITATE_OUT -> {
        setPosition(IntakeSubsystemConstants.extendedRotations);
      }
      case CLOSE_AGITATION_OUT -> {
        setPosition(IntakeSubsystemConstants.burstAgitation);
      }
      case FAR_AGITATION_IN -> {
        setPosition(IntakeSubsystemConstants.burstAgitation);
      }
      case FAR_AGITATION_OUT -> {
        setPosition(IntakeSubsystemConstants.extendedRotations);
      }
      case DITHERIN_AGITATION, DITHEROUT_AGITATION -> {
        // No position command — dither uses duty-cycle motor.set() in periodic
      }
    }

  }

  public void setRollerState(RollerState desiredState) {
    // Safety rule: rollers must never run when intake is stowed (DEFAULT).
    // Allow rollers when the intake is EXTENDED, INTAKING, or AGITATE.
    // if (desiredState != RollerState.OFF && this.currentState == IntakeState.DEFAULT) {
    // Ignore requests to run rollers while stowed; keep them OFF.
    // this.currentRollerState = RollerState.OFF;
    // return;
    // }
    this.currentRollerState = desiredState;
  }

  public RollerState getRollerState() {
    return this.currentRollerState;
  }

  public Angle getRollerPosition() {
    return rollerInputs.rollerMotorPosition;
  }

  public Angle getRackPosition() {
    return rackInputs.rackMotorPosition;
  }

  public boolean getLimitSwitchValue() {
    return rackInputs.rackLimitSwitch;
  }

  public Voltage getRackAppliedVoltage() {
    return rackInputs.rackMotorAppliedVoltage;
  }

  public Voltage getRollerAppliedVoltage() {
    return rollerInputs.rollerMotorAppliedVoltage;
  }

  public AngularVelocity getRackAngularVelocity() {
    return rackInputs.rackMotorVelocity;
  }

  public AngularVelocity getRollerAngularVelocity() {
    return rollerInputs.rollerMotorVelocity;
  }

  public Current getRackAppliedCurrent() {
    return rackInputs.rackMotorCurrent;
  }

  public TalonFX getRackMotor() {
    return rackIO.getIntakeMotor();
  }

  public TalonFX getRollerMotor() {
    return rollerIO.getRollerMotorLeader();
  }

  public DigitalInput getLimitSwitch() {
    return rackIO.getLimitSwitch();
  }

  /**
   * Current is multiplied by 2 to give representation for both motors
   */
  public Current getRollerAppliedCurrent() {
    return rollerInputs.rollerMotorCurrent.times(2);
  }

  public Command setRollerStateCommand(RollerState desiredState) {
    return Commands.runOnce(() -> setRollerState(desiredState));
  }

  public Command resetIntakeEncoder() {
    return Commands.runOnce(() -> rackIO.zeroEncoder(Rotations.of(0)));
  }

  public Command extendIntake() {
    return Commands.runOnce(() -> setRackState(IntakeState.EXTENDED));
  }

  public Command retractIntake() {
    return Commands.runOnce(() -> setRackState(IntakeState.DEFAULT));
  }

  public IntakeState getState() {
    return this.currentState;
  }

  public Command setIntakeStateCommand(IntakeState targState) {
    return Commands.runOnce(() -> setRackState(targState));
  }

  public void setPosition(Double rotations) {
    // Use MotionMagic with an Angle position to get proper units and controller behavior
    rackIO.setPosition(Rotations.of(rotations));
  }


}
