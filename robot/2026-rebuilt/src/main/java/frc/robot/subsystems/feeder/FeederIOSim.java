package frc.robot.subsystems.feeder;

import static edu.wpi.first.units.Units.Amps;
import static edu.wpi.first.units.Units.Fahrenheit;
import static edu.wpi.first.units.Units.Volts;
import com.ctre.phoenix6.hardware.TalonFX;
import edu.wpi.first.math.system.plant.DCMotor;
import edu.wpi.first.math.system.plant.LinearSystemId;
import edu.wpi.first.units.measure.Voltage;
import edu.wpi.first.wpilibj.simulation.DCMotorSim;

public class FeederIOSim implements FeederIO {
  /** Feeder motor moment of inertia (kg·m²). TODO update placeholder */
  private static final double FEEDER_MOI = 4 * 0.5 * 0.75 * 0.025 * 0.025; // 4 axles × 0.5 ×
                                                                           // mass(0.75kg) ×
                                                                           // radius²(0.025m) — TODO
                                                                           // update placeholder

  /** Feeder gear ratio (motor rotations / mechanism rotations). TODO update placeholder */
  private static final double FEEDER_GEAR_RATIO = 1.0;

  private static final DCMotor feederMotorModel = DCMotor.getKrakenX60(1);
  private static final DCMotorSim feederSim = new DCMotorSim(
      LinearSystemId.createDCMotorSystem(feederMotorModel, FEEDER_MOI, FEEDER_GEAR_RATIO),
      feederMotorModel);

  private Voltage feederAppliedVoltage = Volts.of(0);

  @Override
  public void updateInputs(FeederIOInputs inputs) {

    feederSim.setInputVoltage(feederAppliedVoltage.in(Volts));
    feederSim.update(0.02);

    inputs.feederMotorPosition = feederSim.getAngularPosition();

    inputs.feederMotorVelocity = feederSim.getAngularVelocity();
    inputs.feederMotorAppliedVoltage = feederAppliedVoltage;

    inputs.feederMotorCurrent = Amps.of(feederSim.getCurrentDrawAmps());

    inputs.feederMotorTemp = Fahrenheit.of(75); // We don't particularly care about temperature
                                                // in simulation, so just set it to a constant
                                                // value
  }

  @Override
  /**
   * Set sim voltage, between -12 and 12 volts.
   */
  public void setVoltage(Voltage volts) {
    feederAppliedVoltage = volts;
  }

  @Override
  public void stop() {
    feederAppliedVoltage = Volts.of(0);
  }

  @Override
  public void runSysIdRoutine(Voltage volts) {}

}
