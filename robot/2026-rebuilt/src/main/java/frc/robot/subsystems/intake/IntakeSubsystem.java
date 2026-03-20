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
import edu.wpi.first.math.system.plant.LinearSystemId;
import edu.wpi.first.math.system.plant.DCMotor;
import edu.wpi.first.wpilibj.simulation.DCMotorSim;
import edu.wpi.first.wpilibj.simulation.DIOSim;
import edu.wpi.first.wpilibj.smartdashboard.Mechanism2d;
import edu.wpi.first.wpilibj.smartdashboard.MechanismLigament2d;
import edu.wpi.first.wpilibj.smartdashboard.MechanismRoot2d;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj.util.Color;
import edu.wpi.first.wpilibj.util.Color8Bit;
import edu.wpi.first.wpilibj.RobotBase;
import edu.wpi.first.wpilibj.Timer;
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
  private final double extendedRotations = 15.4;
  private final double retractedRotations = 0.1;
  private final double agitateOut = 5.0;
  // Desired motion timing: target to complete extend/retract in under 1s
  private static final double MOVE_TARGET_SECONDS = .45;
  // Aggressive acceleration multiplier requested (20x faster than default)
  private static final double MOTION_MAGIC_ACCEL_MULTIPLIER = 40.0;
  private static final double ROLLER_OUTPUT = 0.90; //90% for rollers, 70% originally;
  private final Timer timer = new Timer();



  // MotionMagic helper (create once and reuse)
  private final MotionMagicVoltage positionOut = new MotionMagicVoltage(Rotations.of(0));


  // Simulation + Visualization values (only initialized when running in sim, can't be final)
  private DCMotorSim motorSim;
  private DCMotorSim rollerMotorSim;
  private DIOSim limitSwitchRSim;
  private DIOSim limitSwitchLSim;
  private Mechanism2d intakeMech2d;
  private MechanismRoot2d intakeMechRoot;
  private MechanismLigament2d intakeLigament;
  private Mechanism2d rollerMech2d;
  private MechanismRoot2d rollerMechRoot;
  private MechanismLigament2d rollerLigament;

  public enum IntakeState {
    DEFAULT,
    EXTENDED,
    CLOSE_RETRACTED, // 2
    INTAKING,
    AGITATE,
    AGITATE_IN,
    AGITATE_OUT,
    CLOSE_AGITATION,
   
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
        moveIntakeWithPosition(extendedRotations);
        setRollerState(RollerState.OFF);
      }
      case CLOSE_RETRACTED -> {
        moveIntakeWithPosition(2.0);
        
      }
      case INTAKING -> {
        moveIntakeWithPosition(extendedRotations);
        setRollerState(RollerState.ON);
      }
      case AGITATE_IN -> {
        moveIntakeWithPosition(retractedRotations);
      }
      case AGITATE_OUT -> {
        moveIntakeWithPosition(extendedRotations);
      }
      case CLOSE_AGITATION -> {
        moveIntakeWithPosition(IntakeSubsystemConstants.burstAgitation);
      }
    }

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
      // Allow rollers when the intake is EXTENDED, INTAKING, or AGITATE.
      // if (desiredState != RollerState.OFF && this.currentState == IntakeState.DEFAULT) {
        // Ignore requests to run rollers while stowed; keep them OFF.
      //   this.currentRollerState = RollerState.OFF;
      //   return;
      // }
      this.currentRollerState = desiredState;
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
      config.Slot0.kP = 3.0;
    config.Slot0.kS = 0.3;
    config.Slot0.kI = 0.0;
    config.Slot0.kD = 0.0;
      // config.CurrentLimits.SupplyCurrentLimit = 40.0;
      config.CurrentLimits.StatorCurrentLimit = 40.0;
      config.CurrentLimits.SupplyCurrentLimitEnable = true;
  
  
      // Configure MotionMagic cruise velocity and acceleration so moves complete
      // near our desired MOVE_TARGET_SECONDS. Units: motor rotations / sec and
      // rotations / sec^2 respectively.
      double delta = Math.abs(extendedRotations - retractedRotations);
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
  
  
  
      if (RobotBase.isSimulation()) {
        initSimulation();
      }
    }
  
    private void initSimulation() {
      var intakePlant = LinearSystemId.createDCMotorSystem(DCMotor.getKrakenX60(1), 0.004, 100.0);
      motorSim = new DCMotorSim(intakePlant, DCMotor.getKrakenX60(1));
      var rollerPlant = LinearSystemId.createDCMotorSystem(DCMotor.getKrakenX60(1), 0.001, 1.0);
      rollerMotorSim = new DCMotorSim(rollerPlant, DCMotor.getKrakenX60(1));
      limitSwitchRSim = new DIOSim(limit_switch_r);
      limitSwitchLSim = new DIOSim(limit_switch_l);
  
      // Default limit switch state (True = Not Pressed for most switches)
      limitSwitchRSim.setValue(true);
      limitSwitchLSim.setValue(true);
  
    intakeMech2d = new Mechanism2d(3, 3);
    intakeMechRoot = intakeMech2d.getRoot("IntakeRoot", 1.5, 1.5);
    intakeLigament = intakeMechRoot.append(
      new MechanismLigament2d("Intake", 1, 90, 6, new Color8Bit(Color.kOrange)));
  
    rollerMech2d = new Mechanism2d(3, 3);
    rollerMechRoot = rollerMech2d.getRoot("RollerRoot", 1.5, 1.5);
    rollerLigament = rollerMechRoot.append(
      new MechanismLigament2d("Roller", 1, 0, 6, new Color8Bit(Color.kBlue)));
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
      
        break;
      }

        case CLOSE_AGITATION: 
          if(!timer.isRunning()){
            timer.start();
          }
          if(timer.hasElapsed(0.25)){
            setState(IntakeState.CLOSE_RETRACTED); // really close to default
            timer.stop();
            timer.reset();
          }

          case CLOSE_RETRACTED  : 
          if(!timer.isRunning()){
            timer.start();
          }

          if(timer.hasElapsed(0.25)){
            setState(IntakeState.CLOSE_AGITATION); // about halfway from bumper to extended
            timer.stop();
            timer.reset();
          
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

    Logger.recordOutput("Robot/Intake/Extended", currentState != IntakeState.DEFAULT);
    Logger.recordOutput("Robot/Intake/RollerState", currentRollerState.toString());
    Logger.recordOutput("Robot/Intake/FuelDetected", fuelDetected);
    Logger.recordOutput("Robot/Limelights/limelight-one/TV", fuelDetected);
    Logger.recordOutput("Robot/Limelights/limelight-one/TX", LimelightHelpers.getTX("limelight-one"));
    Logger.recordOutput("Robot/Limelights/limelight-one/TY", LimelightHelpers.getTY("limelight-one"));
    Logger.recordOutput("Robot/Limelights/limelight-one/TA", LimelightHelpers.getTA("limelight-one"));
    super.periodic();}
  }
  

  @Override
  public void simulationPeriodic() {
    // 1. Physics: Apply motor voltage to simulation
    motorSim.setInput(motor.get() * 12.0);
    motorSim.update(0.02);

    // 2. Update CTRE device from physics
    motor.getSimState().setRawRotorPosition(motorSim.getAngularPosition().in(Units.Rotations));
    motor.getSimState().setRotorVelocity(motorSim.getAngularVelocity().in(Units.RotationsPerSecond));

    // 3. Visualization
    // Assume 0 is stowed (90 degrees up) and rotating moves it down
    double angleDegrees = motorSim.getAngularPosition().in(Units.Degrees);
    intakeLigament.setAngle(90 - angleDegrees);

    // 4. Limit Switch Simulation
    // Logic extracted from extendIntake/retractIntake usage:
    // limit_switch_l seems to be the "Extended" limit.
    // When > 45 degrees, we press limit_switch_l (make it false)
    if (angleDegrees > 45) {
      limitSwitchLSim.setValue(false); // Pressing switch
    } else {
      limitSwitchLSim.setValue(true);  // Released
    }
    
    // Assume limit_switch_r is "Retracted" (stowed) limit
    if (angleDegrees < 0) {
      limitSwitchRSim.setValue(false);
    } else {
      limitSwitchRSim.setValue(true);
    }

    if (rollerMotorSim != null) {
      rollerMotorSim.setInput(rollerMotor.get() * 12.0);
      rollerMotorSim.update(0.02);
      rollerMotor.getSimState().setRawRotorPosition(rollerMotorSim.getAngularPosition().in(Units.Rotations));
      rollerMotor.getSimState().setRotorVelocity(rollerMotorSim.getAngularVelocity().in(Units.RotationsPerSecond));
      rollerLigament.setAngle(rollerMotorSim.getAngularPosition().in(Units.Degrees));
    }

    SmartDashboard.putData(rollerMech2d);
    SmartDashboard.putData(intakeMech2d);
  }



  public void stopmotor() {
    motor.stopMotor();
    rollerMotor.stopMotor();
  }

  public double getmotorVelocity() {
    return motor.getVelocity().getValue().in(Units.RotationsPerSecond);
  }

  public boolean testIntakeExtend() {
     setState(IntakeState.EXTENDED);
     return limit_switch_l.get();
    }

}

