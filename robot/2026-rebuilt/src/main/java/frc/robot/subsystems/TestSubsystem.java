package frc.robot.subsystems;

import static edu.wpi.first.units.Units.Rotations;
import static edu.wpi.first.units.Units.RotationsPerSecond;
import static edu.wpi.first.units.Units.Volts;

import com.ctre.phoenix6.StatusSignal;
import com.ctre.phoenix6.configs.TalonFXConfiguration;
import com.ctre.phoenix6.controls.PositionVoltage;
import com.ctre.phoenix6.controls.VoltageOut;
import com.ctre.phoenix6.hardware.TalonFX;
import com.ctre.phoenix6.sim.TalonFXSimState;

import edu.wpi.first.math.system.LinearSystem;
import edu.wpi.first.math.system.plant.DCMotor;
import edu.wpi.first.math.system.plant.LinearSystemId;
import edu.wpi.first.units.measure.Voltage;
import edu.wpi.first.wpilibj.simulation.DCMotorSim;
import edu.wpi.first.wpilibj.simulation.DIOSim;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import edu.wpi.first.wpilibj2.command.sysid.SysIdRoutine;
import edu.wpi.first.wpilibj2.command.sysid.SysIdRoutine.Direction;

public class TestSubsystem extends SubsystemBase {

  private final TalonFX motor;
  private final DCMotor motorSim = DCMotor.getKrakenX60(1);
  private DCMotorSim sim;
  private SysIdRoutine sysID;

  public TestSubsystem() {
    var plant = LinearSystemId.createDCMotorSystem(motorSim, 0.000000000001, 1);
    motor = new TalonFX(23);
    sim = new DCMotorSim(plant, DCMotor.getKrakenX60(1), 1.0, 0.02);
    
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
  }


  public Command quatsiCommand(Direction direction) {
      return sysID.quasistatic(direction);
  } 

  public Command dyanmicCommand(Direction direction) {
      return sysID.dynamic(direction);
  } 



  public Command testCommand() {
    return run(()-> motor.setControl(new PositionVoltage(0).withPosition(6)));
  }

  @Override
  public void periodic() {

    super.periodic();
  }

  @Override
  public void simulationPeriodic() {
    TalonFXSimState simState = motor.getSimState();
    simState.setSupplyVoltage(12.0);
    sim.setInput(12 * motor.get());
    sim.update(0.02);
    simState.setRawRotorPosition(sim.getAngularPosition().in(Rotations));
    simState.setRotorVelocity(sim.getAngularVelocity().in(RotationsPerSecond));
  }

  public void setmotorSpeed(double speed) {
    motor.set(speed);
  }

  public void stopmotor() {
    motor.stopMotor();
  }
}
