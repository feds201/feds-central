package frc.robot.subsystems;

import com.ctre.phoenix6.hardware.TalonFX;
import edu.wpi.first.networktables.NetworkTable;
import edu.wpi.first.networktables.NetworkTableInstance;
import edu.wpi.first.units.Units;
import edu.wpi.first.wpilibj.DigitalInput;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.RobotMap;
import frc.robot.subsystems.RollersSubsystem.RollerState;
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

public class IntakeSubsystem extends SubsystemBase {

  private final TalonFX motor;
  private final DigitalInput limit_switch_r;
  private final DigitalInput limit_switch_l;
  private final RollersSubsystem rollers; 

  // Simulation
  private final DCMotorSim motorSim;
  private final DIOSim limitSwitchRSim;
  private final DIOSim limitSwitchLSim;
  
  // Visualization
  private final Mechanism2d mech2d = new Mechanism2d(3, 3);
  private final MechanismRoot2d mechRoot = mech2d.getRoot("IntakeRoot", 1.5, 1.5);
  private final MechanismLigament2d intakeLigament = mechRoot.append(
      new MechanismLigament2d("Intake", 1, 90, 6, new Color8Bit(Color.kOrange)));

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

  private void extendIntake(){
    if (limit_switch_l.get() == true) { //-> If the limit switch is pressed, extend the intake
      motor.set(0.1);
    } else {
      stopmotor();
    }
  }

  private void retractIntake() {
    if (limit_switch_l.get() == false) {
      motor.set(-0.1);
    }
      else {
        stopmotor(); 
      }
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

    // Simulation Setup
    var intakePlant = LinearSystemId.createDCMotorSystem(DCMotor.getKrakenX60(1), 0.004, 100.0);
    motorSim = new DCMotorSim(intakePlant, DCMotor.getKrakenX60(1)); 
    limitSwitchRSim = new DIOSim(limit_switch_r);
    limitSwitchLSim = new DIOSim(limit_switch_l);
    
    // Default limit switch state (True = Not Pressed for most switches)
    limitSwitchRSim.setValue(true);
    limitSwitchLSim.setValue(true);

    SmartDashboard.putData("Intake Sim", mech2d);
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
}

