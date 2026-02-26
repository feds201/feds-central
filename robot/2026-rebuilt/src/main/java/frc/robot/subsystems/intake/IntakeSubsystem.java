package frc.robot.subsystems.intake;

import com.ctre.phoenix6.configs.TalonFXConfiguration;
import com.ctre.phoenix6.controls.PositionVoltage;
import com.ctre.phoenix6.controls.VoltageOut;
import com.ctre.phoenix6.hardware.TalonFX;
import edu.wpi.first.units.Units;
import edu.wpi.first.wpilibj.DigitalInput;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import edu.wpi.first.wpilibj2.command.sysid.SysIdRoutine;
import frc.robot.RobotMap;
import frc.robot.subsystems.intake.RollersSubsystem.RollerState;
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
  private final DigitalInput limit_switch_r;
  private final DigitalInput limit_switch_l;
  private final RollersSubsystem rollers; 
  private final SysIdRoutine sysID;
  private final double wheelRadius = 2.0; 
  private final double extendedLength = 14.43; 

  // Simulation + Visualization values (only initialized when running in sim, can't be final)
  private DCMotorSim motorSim;
  private DIOSim limitSwitchRSim;
  private DIOSim limitSwitchLSim;
  private Mechanism2d mech2d;
  private MechanismRoot2d mechRoot;
  private MechanismLigament2d intakeLigament;

  public enum IntakeState {
    EXTENDED, 
    DEFAULT
  }
  private IntakeState currentState = IntakeState.DEFAULT;
  private IntakeState targetState = IntakeState.DEFAULT;

  public void setState(IntakeState targetState) { // -> Extended
    this.targetState = targetState; 
    this.currentState = targetState;
  }

  public Command extendIntake(){
    return run(()-> motor.setControl(new PositionVoltage(0).withPosition(extendedLength/(wheelRadius*2*Math.PI))));
  }

  public Command retractIntake() {
     return run(()-> motor.setControl(new PositionVoltage(0).withPosition(0)));
    }

  

  public IntakeState getState() {
    return this.currentState;
  }

  public Command setIntakeStateCommand(IntakeState targState){ // -> Extended 
    return run(() -> setState(targState)); // -> Extended
  }



  public IntakeSubsystem() {
    motor = new TalonFX(RobotMap.IntakeSubsystemConstants.kMotorID, "rio");
    limit_switch_r = new DigitalInput(RobotMap.IntakeSubsystemConstants.kLimit_switch_rID);
    limit_switch_l = new DigitalInput(RobotMap.IntakeSubsystemConstants.kLimit_switch_lID);
    rollers = RollersSubsystem.getInstance();

    var config = new TalonFXConfiguration();
    config.Slot0.kP = 0.1;
    config.Slot0.kI = 0.0;
    config.Slot0.kD = 0.0;
    motor.getConfigurator().apply(config);

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
    limitSwitchRSim = new DIOSim(limit_switch_r);
    limitSwitchLSim = new DIOSim(limit_switch_l);

    // Default limit switch state (True = Not Pressed for most switches)
    limitSwitchRSim.setValue(true);
    limitSwitchLSim.setValue(true);

    mech2d = new Mechanism2d(3, 3);
    mechRoot = mech2d.getRoot("IntakeRoot", 1.5, 1.5);
    intakeLigament = mechRoot.append(
        new MechanismLigament2d("Intake", 1, 90, 6, new Color8Bit(Color.kOrange)));
  }

  @Override
  public void periodic() {

    if (LimelightHelpers.getTV("limelight-one")) {
      System.out.println("Limelight found target.");
      rollers.setState(RollerState.ON);
    }

    else {
      rollers.setState(RollerState.OFF);
    }

    switch(targetState) { // -> Extended
      case EXTENDED: extendIntake();
        break;
      
        
      case DEFAULT: retractIntake();
      break; 
    }


    
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
  }



  public void stopmotor() {
    motor.stopMotor();
  }

  public double getmotorVelocity() {
    return motor.getVelocity().getValue().in(Units.RotationsPerSecond);
  }

  public boolean testIntakeExtend() {
     extendIntake();

     if (limit_switch_l.get()) {
      return true;
     }
    return false; 
    }

}

