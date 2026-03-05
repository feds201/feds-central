package frc.robot.subsystems.intake;

import com.ctre.phoenix6.controls.PositionVoltage;
import com.ctre.phoenix6.configs.TalonFXConfiguration;
import com.ctre.phoenix6.controls.VoltageOut;
import com.ctre.phoenix6.hardware.TalonFX;
import edu.wpi.first.units.Units;
import edu.wpi.first.wpilibj.DigitalInput;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import edu.wpi.first.wpilibj2.command.sysid.SysIdRoutine;
import org.littletonrobotics.junction.Logger;
import frc.robot.RobotMap;
import frc.robot.subsystems.led.LedsSubsystem;
import frc.robot.utils.LimelightHelpers;
import edu.wpi.first.math.system.plant.LinearSystemId;
import edu.wpi.first.math.system.plant.DCMotor;
import edu.wpi.first.wpilibj.simulation.DCMotorSim;
import edu.wpi.first.wpilibj.simulation.DIOSim;
import edu.wpi.first.wpilibj.smartdashboard.Mechanism2d;
import edu.wpi.first.wpilibj.smartdashboard.MechanismLigament2d;
import edu.wpi.first.wpilibj.smartdashboard.MechanismRoot2d;
import edu.wpi.first.wpilibj.util.Color;
import edu.wpi.first.wpilibj.util.Color8Bit;
import edu.wpi.first.wpilibj.RobotBase;

public class IntakeSubsystem extends SubsystemBase {

  private final TalonFX motor;
  private final TalonFX rollerMotor;
  private final DigitalInput limit_switch_r;
  private final DigitalInput limit_switch_l;
  private final SysIdRoutine sysID;
  private final LedsSubsystem leds = LedsSubsystem.getInstance();
  private final double extendedRotations = 78.0;
  private final double retractedRotations = 0.0;
  private static final double ROLLER_OUTPUT = 0.5;


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
    INTAKING
  }

  public enum RollerState {
    ON,
    OFF,
    REVERSE
  }
  private IntakeState currentState = IntakeState.DEFAULT;
  private RollerState currentRollerState = RollerState.OFF;
  

  public void setState(IntakeState targetState) {
    this.currentState = targetState;
    switch (targetState) {
      case DEFAULT -> {
        moveIntakeWithPosition(retractedRotations);
        setRollerState(RollerState.OFF);
      }
      case EXTENDED -> {
        moveIntakeWithPosition(extendedRotations);
        setRollerState(RollerState.OFF);
      }
      case INTAKING -> {
        moveIntakeWithPosition(extendedRotations);
        setRollerState(RollerState.ON);
      }
    }
  }

  public Command extendIntake(){
    return runOnce(() -> setState(IntakeState.EXTENDED));
  }

  public Command retractIntake() {
    return runOnce(() -> setState(IntakeState.DEFAULT));
  }

  public IntakeState getState() {
    return this.currentState;
  }

  public Command setIntakeStateCommand(IntakeState targState){
    return runOnce(() -> setState(targState));
  }

  public void moveIntakeWithPosition(double rotations) {
    motor.setControl(new PositionVoltage(rotations));
  }

  public void setMotorVoltage(double voltage) {
    motor.setControl(new VoltageOut(voltage));
  }

  public void setRollerState(RollerState desiredState) {
    this.currentRollerState = desiredState;
  }

  public Command emergencyStop() {
    return runOnce(() -> {
      setState(IntakeState.DEFAULT);
      setRollerState(RollerState.OFF);
    });
  }

  public RollerState getRollerState() {
    return this.currentRollerState;
  }

  public Command setRollerStateCommand(RollerState desiredState) {
    return runOnce(() -> setRollerState(desiredState));
  }

  public Command resetIntakeEncoder() {
    return runOnce(() -> motor.setPosition(0));
  }



  public IntakeSubsystem() {
    motor = new TalonFX(RobotMap.IntakeSubsystemConstants.kMotorID);
    rollerMotor = new TalonFX(RobotMap.IntakeSubsystemConstants.kRollerMotorID);
    limit_switch_r = new DigitalInput(RobotMap.IntakeSubsystemConstants.kLimit_switch_rID);
    limit_switch_l = new DigitalInput(RobotMap.IntakeSubsystemConstants.kLimit_switch_lID);
    var config = new TalonFXConfiguration();
    config.Slot0.kP = 50;
    config.Slot0.kI = .0;
    config.Slot0.kD = 0.0;

    motor.getConfigurator().apply(config);

    motor.setPosition(0);

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
    super.periodic();
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

