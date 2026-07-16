package frc.robot.subsystems.spindexer;

import static edu.wpi.first.units.Units.Amps;
import static edu.wpi.first.units.Units.Fahrenheit;
import static edu.wpi.first.units.Units.Volts;
import com.ctre.phoenix6.hardware.TalonFX;
import edu.wpi.first.math.system.plant.DCMotor;
import edu.wpi.first.math.system.plant.LinearSystemId;
import edu.wpi.first.units.measure.Voltage;
import edu.wpi.first.wpilibj.simulation.DCMotorSim;

public class SpindexerIOSim implements SpindexerIO {
  private static final double moi = 8e-4; // kg*m^2
  private static final double gearRatio = 1.0 / 1.0; // 1:1
  private static final DCMotor spindexerMotorModel = DCMotor.getKrakenX60(1);
  private static final DCMotorSim spindexerSim = new DCMotorSim(
      LinearSystemId.createDCMotorSystem(spindexerMotorModel, moi, gearRatio), spindexerMotorModel);

  private Voltage spindexerAppliedVoltage = Volts.of(0);

  @Override
  public void updateInputs(SpindexerIOInputs inputs) {

    spindexerSim.setInputVoltage(spindexerAppliedVoltage.in(Volts));
    spindexerSim.update(0.02);

    inputs.spindexerMotorPosition = spindexerSim.getAngularPosition();

    inputs.spindexerMotorVelocity = spindexerSim.getAngularVelocity();

    inputs.spindexerMotorAppliedVoltage = spindexerAppliedVoltage;

    inputs.spindexerMotorCurrent = Amps.of(spindexerSim.getCurrentDrawAmps());

    inputs.spindexerMotorTemp = Fahrenheit.of(75); // We don't particularly care about temperature
                                                   // in simulation, so just set it to a constant
                                                   // value
  }

  @Override
  /**
   * Set sim voltage, between -12 and 12 volts.
   */
  public void setVoltage(Voltage volts) {
    spindexerAppliedVoltage = volts;
  }

  @Override
  public void stop() {
    spindexerAppliedVoltage = Volts.of(0);
  }

  @Override
  public void runSysIdRoutine(Voltage volts) {}

}
