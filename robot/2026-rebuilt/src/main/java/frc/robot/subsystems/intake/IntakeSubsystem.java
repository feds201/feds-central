package frc.robot.subsystems.intake;
import com.ctre.phoenix6.controls.PositionVoltage;
import com.ctre.phoenix6.configs.TalonFXConfiguration;
import com.ctre.phoenix6.controls.VoltageOut;
import com.ctre.phoenix6.hardware.TalonFX;
import com.fasterxml.jackson.databind.ser.std.StdKeySerializers.Default;

import frc.robot.commands.intake.AgitateWhileHeldTimeCommand;
import frc.robot.commands.intake.AgitateWhileHeldRotationsCommand;
import static edu.wpi.first.units.Units.Rotations;
import edu.wpi.first.units.Units;
import edu.wpi.first.wpilibj.DigitalInput;

import java.io.ObjectInputFilter.Config;
import java.util.ArrayList;
import java.util.Set;
import java.util.List;

import org.littletonrobotics.junction.Logger;

import com.ctre.phoenix6.controls.MotionMagicVelocityDutyCycle;
import com.ctre.phoenix6.controls.MotionMagicVoltage;

import frc.robot.RobotMap;
import frc.robot.RobotMap.IntakeSubsystemConstants;
import frc.robot.subsystems.led.LedsSubsystem;
import frc.robot.subsystems.shooter.ShooterWheels.shooter_state;
import frc.robot.utils.LimelightHelpers;
import edu.wpi.first.networktables.GenericEntry;
import edu.wpi.first.wpilibj.Timer;
import edu.wpi.first.wpilibj.shuffleboard.BuiltInLayouts;
import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardLayout;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardTab;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import edu.wpi.first.wpilibj2.command.WaitCommand;
import edu.wpi.first.wpilibj2.command.WaitUntilCommand;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.Commands;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.sysid.SysIdRoutine;
public class IntakeSubsystem extends SubsystemBase {

  private final TalonFX motor;
  private final TalonFX rollerMotor;
  private final DigitalInput limit_switch_r;
  private final DigitalInput limit_switch_l;
  private final SysIdRoutine sysID;
  private final LedsSubsystem leds = LedsSubsystem.getInstance();
  public static final double EXTENDED_ROTATIONS = 18.0; //TUNE on new intake
  private final double retractedRotations = 0.39;
  private final double closeAgitationRotations = 9.0; // about halfway from bumper to extended, used for agitating the close half of the hopper
  private final double farAgitationRotations = 13.5; // about three-quarters from bumper to extended, used for agitating the far half of the hopper
  public final double burstAgitation = EXTENDED_ROTATIONS / 2.0;
  // Desired motion timing: target to complete extend/retract in under 1s
  private static final double MOVE_TARGET_SECONDS = .45;
  // Aggressive acceleration multiplier requested (20x faster than default)
  private static final double MOTION_MAGIC_ACCEL_MULTIPLIER = 40.0;
  private static final double ROLLER_OUTPUT = 0.90; //90% for rollers, 70% originally;
  private final Timer timer = new Timer();

  private final ShuffleboardTab pitTab;
  private final ShuffleboardLayout intakeLayout;
  private final GenericEntry intakeConnectedEntry;
  private final GenericEntry intakePoweredEntry;
  private final GenericEntry rollerConnectedEntry;
  private final GenericEntry rollerPoweredEntry;



  // MotionMagic helper (create once and reuse)
  private final MotionMagicVoltage positionOut = new MotionMagicVoltage(Rotations.of(0));


  public enum IntakeState {
    DEFAULT, //Retracted, assumed to be starting state
    EXTENDED, //Fully extended
    INTAKING, //Fully extended with rollers on, used for actively intaking fuel

    //State loop 1: Agitate
    AGITATE_IN, //Inwards portion of the agitate state-loop, intake will toggle between the agitates on a timer when set to one of these states
    AGITATE_OUT, //Agitation causes the intake to move outwards, then inwards back to default in order to agitate the fuel in the full hopper

    //State loop 2: Close Agitation
    CLOSE_AGITATION_IN, //Inwards portion of the close agitation state-loop, intake will toggle between the close agitates on a timer when set to one of these states
    CLOSE_AGITATION_OUT, //Close agitation causes the intake to move outwards, then inwards about halfway to extended in order to agitate the close half of the hopper

    FAR_AGITATION_IN, //Inwards portion of the far agitation state-loop, intake will toggle between the far agitates on a timer when set to one of these states
    FAR_AGITATION_OUT, //Far agitation causes the intake to move outwards

    //State loop 3: Dither Agitation (experimental, may not be used)
    DITHERIN_AGITATION, //Inwards portion of dithering state-loop, intake will toggle between the dithers on a timer when set to one of these states
    DITHEROUT_AGITATION //Dithering causes the intake to move inwards, then outwards half as much in order to slowly bring in the intake while also agitating
  }

  public enum RollerState {
    ON,
    OFF,
    REVERSE,
  }

  

  private IntakeState currentState = IntakeState.DEFAULT;
  private RollerState currentRollerState = RollerState.OFF;
 
  

  public void setState(IntakeState targetState) {
    this.currentState = targetState;
    switch (targetState) {
      case DEFAULT -> {
        moveIntakeWithPosition(retractedRotations);
      }
      case EXTENDED -> {
        moveIntakeWithPosition(EXTENDED_ROTATIONS);
        setRollerState(RollerState.OFF);
      }
      case CLOSE_AGITATION_IN -> {
        moveIntakeWithPosition(0.0);
        
      }
      case INTAKING -> {
        moveIntakeWithPosition(EXTENDED_ROTATIONS);
        setRollerState(RollerState.ON);
      }
      case AGITATE_IN -> {
        moveIntakeWithPosition(retractedRotations);
      }
      case AGITATE_OUT -> {
        moveIntakeWithPosition(EXTENDED_ROTATIONS);
      }
      case CLOSE_AGITATION_OUT -> {
        moveIntakeWithPosition(burstAgitation);
      }
      case FAR_AGITATION_IN -> {
        moveIntakeWithPosition(burstAgitation);
      }
      case FAR_AGITATION_OUT -> {
        moveIntakeWithPosition(EXTENDED_ROTATIONS);
      }
    }

    }
  

  public Command extendIntake(){
    return Commands.runOnce(() -> setState(IntakeState.EXTENDED));
  }

  public Command retractIntake() {
    return Commands.runOnce(() -> setState(IntakeState.DEFAULT));
  }

  public IntakeState getState() {
    return this.currentState;
  }

  public Command setIntakeStateCommand(IntakeState targState){
      return Commands.runOnce(() -> setState(targState));
    }
  
    public void moveIntakeWithPosition(double rotations) {
      // Use MotionMagic with an Angle position to get proper units and controller behavior
      motor.setControl(positionOut.withPosition(Rotations.of(rotations)));
    }
  
    @SuppressWarnings("unused")
    private void setMotorVoltage(double voltage) {
      motor.setControl(new VoltageOut(voltage));
    }
  
    public void setRollerState(RollerState desiredState) {
      // Safety rule: rollers must never run when intake is stowed (DEFAULT).
      // Allow rollers when the intake is EXTENDED, INTAKING, or AGITATE.
      // if (desiredState != RollerState.OFF && this.currentState == IntakeState.DEFAULT) {
        // Ignore requests to run rollers while stowed; keep them OFF.
      //   this.currentRollerState = RollerState.OFF;
      //   return;
      // }
      this.currentRollerState = desiredState;
    }
    public void agitateTimed() {
  
  
      for(int i = 0; i < 20; i++){
        extendIntake().withTimeout(2);
        retractIntake().withTimeout(2);
      } 
            setState(IntakeState.DEFAULT);
  
    }
  
    /**
     * Build a non-blocking Command that pulses the intake between EXTENDED and DEFAULT.
     * @param pulses number of extend/retract cycles
     * @param extendSeconds how long to hold EXTENDED each pulse
     * @param retractSeconds how long to hold DEFAULT between pulses
     */
    public Command agitateCommand(int pulses, double extendSeconds, double retractSeconds) {
      List<Command> steps = new ArrayList<>();
      for (int i = 0; i < pulses; ++i) {
        // extend, wait, retract, wait
        steps.add(extendIntake());
        steps.add(new WaitCommand(extendSeconds));
        steps.add(retractIntake());
        // don't add final retract wait on last pulse (optional)
        if (i < pulses - 1) {
          steps.add(new WaitCommand(retractSeconds));
        }
      }
  // ensure we finish in DEFAULT state
  steps.add(Commands.runOnce(() -> setState(IntakeState.DEFAULT)));
      return Commands.sequence(steps.toArray(new Command[steps.size()]));
    }
  
    /**
     * Pulse the intake (extend -> run roller -> retract -> pause) repeatedly until the Command
     * is canceled. Use this with button.whileTrue(...).
     * This variant uses time durations for each phase.
     * @param extendSeconds seconds to hold EXTENDED while rollers run
     * @param retractSeconds seconds to hold DEFAULT between pulses
     */
    public Command agitateWhileHeldTime(double extendSeconds, double retractSeconds) {
      return new AgitateWhileHeldTimeCommand(this, extendSeconds, retractSeconds);
    }
  
    /**
     * Pulse the intake repeatedly until the Command is canceled. Each extend phase runs the
     * roller for a target number of rotations before retracting.
     * @param rotationsPerPulse roller rotations to run during each extend phase
     */
    /*public Command agitateWhileHeldRotations(double rotationsPerPulse) {
      return new AgitateWhileHeldRotationsCommand(this, rotationsPerPulse);
    }
  
    /**
     * Run the roller motor until it has turned the requested number of rotations.
     * This Command requires the intake subsystem while running.
     */
    public Command runRollerForRotations(double rotations) {
      // Use an array to capture start position in lambdas
      double[] start = new double[1];
    return Commands.sequence(
      // Record start position
      Commands.runOnce(() -> start[0] = rollerMotor.getPosition().getValue().in(Units.Rotations)),
      // start roller
      Commands.runOnce(() -> rollerMotor.set(ROLLER_OUTPUT)),
      // wait until requested rotations completed
      new WaitUntilCommand(() -> Math.abs(rollerMotor.getPosition().getValue().in(Units.Rotations) - start[0]) >= Math.abs(rotations)),
      // stop roller
      Commands.runOnce(() -> rollerMotor.stopMotor())
    );
    }
  
    /**
     * Run the roller motor until it reaches an absolute encoder target, choosing direction
     * automatically from the current position.
     * This is useful for oscillating between fixed bounds like 0 and 5 rotations.
     */
    public Command moveRollerToPosition(double targetRotations) {
      return Commands.defer(() -> {
        double currentPosition = getRollerPosition();
        double delta = targetRotations - currentPosition;
  
        if (Math.abs(delta) < 0.05) {
          return Commands.runOnce(this::stopRoller);
        }
  
        double direction = Math.signum(delta);
    return Commands.sequence(
      Commands.runOnce(() -> rollerMotor.set(direction * ROLLER_OUTPUT)),
      new WaitUntilCommand(() -> {
              double position = getRollerPosition();
              return direction > 0
                  ? position >= targetRotations
                  : position <= targetRotations;
            }),
      Commands.runOnce(this::stopRoller));
      }, Set.of(this));
    }
  
    /**
     * Build an agitate sequence that uses roller rotations rather than timing.
     * @param pulses number of extend/retract cycles
     * @param rotationsPerPulse roller rotations to run during each extend
     */
    public Command agitateByRotations(int pulses, double rotationsPerPulse) {
      List<Command> steps = new ArrayList<>();
      for (int i = 0; i < pulses; ++i) {
        steps.add(extendIntake());
        steps.add(runRollerForRotations(rotationsPerPulse));
        steps.add(retractIntake());
      }
  // ensure we finish in DEFAULT state
  steps.add(Commands.runOnce(() -> setState(IntakeState.DEFAULT)));
      return Commands.sequence(steps.toArray(new Command[steps.size()]));
    }
  
    // --- Roller helpers for external Commands (encapsulate direct motor access) ---
    /** Start the roller at the configured ROLLER_OUTPUT. */
    public void startRoller() {
      rollerMotor.set(ROLLER_OUTPUT);
    }
  
    /** Stop the roller motor immediately. */
    public void stopRoller() {
      rollerMotor.stopMotor();
    }
  
    /**
     * Get the roller encoder position in rotations.
     * @return current roller position (rotations)
     */
    public double getRollerPosition() {
      return rollerMotor.getPosition().getValue().in(Units.Rotations);
    }
  
  
    public Command emergencyStop() {
      return Commands.runOnce(() -> {
        setState(IntakeState.DEFAULT);
        setRollerState(RollerState.OFF);
      });
    }
  
    public RollerState getRollerState() {
      return this.currentRollerState;
    }
  
    public Command setRollerStateCommand(RollerState desiredState) {
        return Commands.runOnce(() -> setRollerState(desiredState));
      }
  
    public Command resetIntakeEncoder() {
        return Commands.runOnce(() -> motor.setPosition(0));
      }
  
  
  
  
    public IntakeSubsystem() {
      motor = new TalonFX(RobotMap.IntakeSubsystemConstants.kMotorID);
      rollerMotor = new TalonFX(RobotMap.IntakeSubsystemConstants.kRollerMotorID);
      limit_switch_r = new DigitalInput(RobotMap.IntakeSubsystemConstants.kLimit_switch_rID);
      limit_switch_l = new DigitalInput(RobotMap.IntakeSubsystemConstants.kLimit_switch_lID);

      var rollerConfig = new TalonFXConfiguration();
    rollerConfig.CurrentLimits.StatorCurrentLimit = 40.0;
    rollerConfig.CurrentLimits.StatorCurrentLimitEnable = true;

    for (int i = 0; i < 2; ++i) {
      var status = motor.getConfigurator().apply(rollerConfig);
      if (status.isOK()) break;
    }

      var config = new TalonFXConfiguration();
      config.Slot0.kP = 4;
    config.Slot0.kS = 0.42; //TUNE on new intake
    config.Slot0.kI = 0.0;
    config.Slot0.kD = 0.0;
      // config.CurrentLimits.SupplyCurrentLimit = 40.0;
      config.CurrentLimits.StatorCurrentLimit = 45.0;
      config.CurrentLimits.SupplyCurrentLimitEnable = true;
  
  
      // Configure MotionMagic cruise velocity and acceleration so moves complete
      // near our desired MOVE_TARGET_SECONDS. Units: motor rotations / sec and
      // rotations / sec^2 respectively.
      double delta = Math.abs(EXTENDED_ROTATIONS - retractedRotations);
      double cruise = delta / MOVE_TARGET_SECONDS; // rotations per second
    double accel = cruise * 4.0; // base accel to reach cruise quickly
    // Apply user-requested multiplier to increase acceleration aggressively
    accel = accel * MOTION_MAGIC_ACCEL_MULTIPLIER;
    config.MotionMagic.MotionMagicCruiseVelocity = cruise;
    config.MotionMagic.MotionMagicAcceleration = accel;
  
      // Apply config; repeat to ensure application (some hardware requires it)
      for (int i = 0; i < 2; ++i) {
        var status = motor.getConfigurator().apply(config);
        if (status.isOK()) break;
      }
  
      sysID = new SysIdRoutine(
        new SysIdRoutine.Config(), new SysIdRoutine.Mechanism((voltage)-> motor.setControl(new VoltageOut(0).withOutput(voltage)), (log)-> {
          log.motor("motor1")
          .voltage(motor.getMotorVoltage().asSupplier().get())
          .angularVelocity(motor.getVelocity().asSupplier().get())
          .angularPosition(motor.getPosition().asSupplier().get());
        }, this));
  
  
  
    pitTab = Shuffleboard.getTab("Pit Testing");
    intakeLayout = pitTab.getLayout("intake Health", BuiltInLayouts.kList).withSize(2,2).withPosition(4, 0);
    intakeConnectedEntry = intakeLayout.add("intake Motor is Connected", false).getEntry();
    intakePoweredEntry = intakeLayout.add("intake Motor is Powered", false).getEntry();
    rollerConnectedEntry = intakeLayout.add("roller Motor is Connected", false).getEntry();
    rollerPoweredEntry = intakeLayout.add("roller Motor is Powered", false).getEntry();
    }
  
  @Override
  public void periodic() {

    
    switch (currentState) {
      case AGITATE_IN:
       if(! timer.isRunning()){
          timer.start();  
       }
       if(timer.hasElapsed(IntakeSubsystemConstants.agitateCycleConstant)){
        setState(IntakeState.AGITATE_OUT);
        timer.stop();
        timer.reset();
       }
        break;

        case AGITATE_OUT:
           if(! timer.isRunning()){
          timer.start();  
       }
        if(timer.hasElapsed(IntakeSubsystemConstants.agitateCycleConstant)){
        setState(IntakeState.AGITATE_IN);
        timer.stop();
        timer.reset();
      }
      break;

      case FAR_AGITATION_IN:
       if(! timer.isRunning()){
          timer.start();  
       }
       if(timer.hasElapsed(.2)){
        setState(IntakeState.FAR_AGITATION_OUT);
        timer.stop();
        timer.reset();
       }
        break;

        case FAR_AGITATION_OUT:
           if(! timer.isRunning()){
          timer.start();  
       }
        if(timer.hasElapsed(.2)){
        setState(IntakeState.FAR_AGITATION_IN);
        timer.stop();
        timer.reset();
      }
      break;


        case CLOSE_AGITATION_OUT: 
          if(!timer.isRunning()){
            timer.start();
          }
          if(timer.hasElapsed(0.2)){
            setState(IntakeState.CLOSE_AGITATION_IN); // really close to default
            timer.stop();
            timer.reset();
          }
          break;

          case CLOSE_AGITATION_IN: 
          if(!timer.isRunning()){
            timer.start();
          }

          if(timer.hasElapsed(0.2)){
            setState(IntakeState.CLOSE_AGITATION_OUT); // about halfway from bumper to extended
            timer.stop();
            timer.reset();
        }
          break;

        case DITHERIN_AGITATION:
        if(!timer.isRunning()){
          timer.start();
      }
        motor.set(-0.3); 

        if(timer.hasElapsed(0.3)){
            setState(IntakeState.DITHEROUT_AGITATION);
            timer.stop();
            timer.reset();
        }
          break;

        case DITHEROUT_AGITATION:
        if(!timer.isRunning()){
          timer.start();
      }
        motor.set(0.3); 

        if(timer.hasElapsed(0.1)){
            setState(IntakeState.DITHERIN_AGITATION); // small retract from extended
            timer.stop();
            timer.reset();
         

        }
          break;
      }


    switch (currentRollerState) {
      case ON:
        rollerMotor.set(ROLLER_OUTPUT);
        leds.intakeSignal();
        break;
      case REVERSE:
        rollerMotor.set(-ROLLER_OUTPUT);
        break;
      case OFF:
      default:
        rollerMotor.stopMotor();
        break;
    }

    boolean fuelDetected = LimelightHelpers.getTV("limelight-one");

    Logger.recordOutput("Robot/Intake/ExtensionPct", Math.min(100.0, Math.max(0.0, motor.getPosition().getValue().in(Units.Rotations) / EXTENDED_ROTATIONS * 100.0)));
    Logger.recordOutput("Robot/Intake/RollerState", currentRollerState.toString());
    Logger.recordOutput("Robot/Intake/FuelDetected", fuelDetected);
    Logger.recordOutput("Robot/Limelights/limelight-one/TV", fuelDetected);
    Logger.recordOutput("Robot/Limelights/limelight-one/TX", LimelightHelpers.getTX("limelight-one"));
    Logger.recordOutput("Robot/Limelights/limelight-one/TY", LimelightHelpers.getTY("limelight-one"));
    Logger.recordOutput("Robot/Limelights/limelight-one/TA", LimelightHelpers.getTA("limelight-one"));
    Logger.recordOutput("Robot/Intake/Intake Stator Current", motor.getStatorCurrent().getValue());
    super.periodic();

    intakeConnectedEntry.setBoolean(motor.isConnected());
  intakePoweredEntry.setBoolean(motor.getSupplyVoltage().getValueAsDouble() > RobotMap.PitConstants.kPoweredThresholdVolts);
  rollerConnectedEntry.setBoolean(rollerMotor.isConnected());
  rollerPoweredEntry.setBoolean(rollerMotor.getSupplyVoltage().getValueAsDouble() > RobotMap.PitConstants.kPoweredThresholdVolts);
  }
  
  
  

  public void stopmotor() {
    motor.stopMotor();
    rollerMotor.stopMotor();
  }

  public double getmotorVelocity() {
    return motor.getVelocity().getValue().in(Units.RotationsPerSecond);
  }

  // ////////////////////////////////////////////////////////////////////////
  // SIMULATION SUPPORT — Code below is used only by the simulator
  // ////////////////////////////////////////////////////////////////////////

  /**
   * Returns the TalonFX sim state for the deployment motor.
   * Used by RebuiltSimManager to drive the deploy DCMotorSim.
   * Sim use only.
   */
  public com.ctre.phoenix6.sim.TalonFXSimState getDeployMotorSimState() {
      return motor.getSimState();
  }

  /**
   * Returns the TalonFX sim state for the roller motor.
   * Used by RebuiltSimManager to drive the roller DCMotorSim.
   * Sim use only.
   */
  public com.ctre.phoenix6.sim.TalonFXSimState getRollerMotorSimState() {
      return rollerMotor.getSimState();
  }

  /**
   * Returns the deployment motor rotor position in rotations.
   * Used by RebuiltSimManager to determine whether the intake is extended far enough
   * to activate the intake zone (compared against IntakeSubsystem.EXTENDED_ROTATIONS).
   * Sim use only.
   */
  public double getDeployMotorPositionRotations() {
      return motor.getPosition().getValue().in(Units.Rotations);
  }

  /**
   * Returns the roller motor velocity in rotations per second.
   * Used by RebuiltSimManager to determine whether the roller is spinning fast enough
   * to count as actively intaking (compared against INTAKE_ROLLER_VELOCITY_THRESHOLD_RPS).
   * Sim use only.
   */
  public double getRollerMotorVelocityRPS() {
      return rollerMotor.getVelocity().getValue().in(Units.RotationsPerSecond);
  }

  /**
   * Returns the roller motor rotor position in rotations.
   * Used by RebuiltSimManager to drive the roller wheel animation in AdvantageScope.
   * Sim use only.
   */
  public double getRollerMotorPositionRotations() {
      return rollerMotor.getPosition().getValue().in(Units.Rotations);
  }

  // ////////////////////////////////////////////////////////////////////////
  // END SIMULATION SUPPORT
  // ////////////////////////////////////////////////////////////////////////

  public boolean testIntakeExtend() {
     setState(IntakeState.EXTENDED);
     return limit_switch_l.get();
    }

}

