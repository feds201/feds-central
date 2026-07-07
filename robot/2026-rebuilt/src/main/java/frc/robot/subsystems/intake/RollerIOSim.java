package frc.robot.subsystems.intake;

import static edu.wpi.first.units.Units.Amps;
import static edu.wpi.first.units.Units.Fahrenheit;
import static edu.wpi.first.units.Units.Volts;
import com.ctre.phoenix6.hardware.TalonFX;
import edu.wpi.first.math.system.plant.DCMotor;
import edu.wpi.first.math.system.plant.LinearSystemId;
import edu.wpi.first.units.measure.Voltage;
import edu.wpi.first.wpilibj.simulation.DCMotorSim;

public class RollerIOSim implements RollerIO {

  /** Intake roller MOI (kg·m²). TODO update placeholder */
  private static final double INTAKE_ROLLER_MOI = 0.001;

  /**
   * Intake roller gear ratio (motor rotations / mechanism rotations). 3:1 on each of two motors in
   * parallel.
   */
  private static final double INTAKE_ROLLER_GEAR_RATIO = 3.0;

  private final DCMotor rollerMotorType = DCMotor.getKrakenX60(2);
  private final DCMotorSim rollerSim =
      new DCMotorSim(LinearSystemId.createDCMotorSystem(rollerMotorType, INTAKE_ROLLER_MOI,
          INTAKE_ROLLER_GEAR_RATIO), rollerMotorType);

  private Voltage rollerAppliedVoltage = Volts.of(0);

  @Override
  public void updateInputs(RollerIOInputs inputs) {
    rollerSim.setInputVoltage(rollerAppliedVoltage.in(Volts));
    rollerSim.update(.02);

    inputs.rollerMotorAppliedVoltage = rollerAppliedVoltage;

    inputs.rollerMotorCurrent = Amps.of(rollerSim.getCurrentDrawAmps());

    inputs.rollerMotorPosition = rollerSim.getAngularPosition();

    inputs.rollerMotorVelocity = rollerSim.getAngularVelocity();

    inputs.rollerMotorTemp = Fahrenheit.of(75); // we dont really care about temp in sim, 75 should
                                                // be somewhat reasonable
  }

  @Override
  public void set(double percent) {
    rollerAppliedVoltage = Volts.of(percent * 12.0);
  }

  @Override
  public void stop() {
    rollerAppliedVoltage = Volts.of(0);
  }

  // TODO: implement sysid routine for roller
  @Override
  public void runSysIdRoutine(Voltage volts) {}

  @Override
  public TalonFX getRollerMotorLeader() {
    return null;
  }

  @Override
  public TalonFX getRollerMotorFollower() {
    return null;
  }
}
