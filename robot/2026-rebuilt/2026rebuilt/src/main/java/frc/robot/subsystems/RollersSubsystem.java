package frc.robot.subsystems;

// Removed VelocityVoltage usage; using simple motor set calls instead
import com.ctre.phoenix6.hardware.TalonFX;

import edu.wpi.first.wpilibj.simulation.DCMotorSim;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import edu.wpi.first.math.numbers.N1;
import edu.wpi.first.math.numbers.N2  ;
import edu.wpi.first.math.system.LinearSystem;
import edu.wpi.first.math.system.plant.DCMotor;
import edu.wpi.first.math.system.plant.LinearSystemId;
import edu.wpi.first.wpilibj.smartdashboard.Mechanism2d;
import edu.wpi.first.wpilibj.smartdashboard.MechanismLigament2d;
import edu.wpi.first.wpilibj.smartdashboard.MechanismRoot2d;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj.util.Color;
import edu.wpi.first.wpilibj.util.Color8Bit;
import edu.wpi.first.units.Units;

public class RollersSubsystem extends SubsystemBase {

  private static RollersSubsystem instance;
  private RollerState currentState = RollerState.OFF;
  private final TalonFX motor;
  private final LinearSystem<N2, N1, N2> plant;
  private final DCMotorSim motorSim;
  LedsSubsystem leds = LedsSubsystem.getInstance();
  // Visualization
  private final Mechanism2d mech2d = new Mechanism2d(3, 3);
  private final MechanismRoot2d mechRoot = mech2d.getRoot("RollerRoot", 1.5, 1.5);
  private final MechanismLigament2d rollerLigament = mechRoot.append(
      new MechanismLigament2d("Roller", 1, 0, 6, new Color8Bit(Color.kBlue)));

  public static RollersSubsystem getInstance() { 
  if (instance == null) {
      instance = new RollersSubsystem();
    }
    return instance;
  }

  public enum RollerState {
    ON, OFF
  }

  private RollersSubsystem() {
    motor = new TalonFX(23, "rio");
    plant = LinearSystemId.createDCMotorSystem(DCMotor.getKrakenX60(1), 0.001, 1.0);
    motorSim = new DCMotorSim(plant, DCMotor.getKrakenX60(1));
    
    // Publish mechanism to SmartDashboard
    SmartDashboard.putData("Rollers Sim", mech2d);
  }

  public void setState(RollerState targetState) {
    this.currentState = targetState;
    switch (targetState) {
      case ON:
        motor.set(0.1);
        motorSim.setInput(0.1);
        leds.intakeSignal();
        break;
      case OFF:
        motor.stopMotor();
        motorSim.setInput(0.0);
        break;
    }
  }

  
  
  public RollerState getState() {
    return this.currentState;
  }


  public Command RollersCommand(RollerState desiredState) {
      return run(() -> setState(desiredState));
  }

  @Override
  public void periodic() {
    super.periodic();
  }

  @Override
  public void simulationPeriodic() {
    // Update simulation inputs based on motor applied output (approx 12V battery)
    motorSim.setInput(motor.get() * 12.0);
    motorSim.update(0.02);

    // Update the visualizer
    // Convert to degrees for the dashboard.
    // getAngularPosition() returns an Angle object in 2026+, so we use .in(Units.Degrees)
    rollerLigament.setAngle(motorSim.getAngularPosition().in(Units.Degrees));

    // Update the CTRE simulated device so other simulation-aware code works
    // CTRE SimState expects Rotations
    motor.getSimState().setRawRotorPosition(motorSim.getAngularPosition().in(Units.Rotations));
  }
}
