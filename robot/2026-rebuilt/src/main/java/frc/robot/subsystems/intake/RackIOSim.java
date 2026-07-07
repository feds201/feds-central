package frc.robot.subsystems.intake;

import static edu.wpi.first.units.Units.Amps;
import static edu.wpi.first.units.Units.Fahrenheit;
import static edu.wpi.first.units.Units.Radians;
import static edu.wpi.first.units.Units.Rotations;
import static edu.wpi.first.units.Units.Volts;
import com.ctre.phoenix6.controls.VoltageOut;
import com.ctre.phoenix6.hardware.TalonFX;
import edu.wpi.first.math.system.LinearSystem;
import edu.wpi.first.math.system.plant.DCMotor;
import edu.wpi.first.math.system.plant.LinearSystemId;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.Voltage;
import edu.wpi.first.wpilibj.simulation.DCMotorSim;
import edu.wpi.first.wpilibj.simulation.DIOSim;
import frc.robot.RobotMap.IntakeSubsystemConstants;

public class RackIOSim implements RackIO {
  /**
   * Intake deploy MOI (kg·m²). Sim tuning knob, not measured from CAD yet. May need retuning now
   * that the gear ratio is physical.
   */
  private static final double INTAKE_DEPLOY_MOI = 0.01;

  /**
   * Intake deploy gear ratio (motor rotations / mechanism rotations). Two 3:1 stages in series =
   * 9:1.
   */
  private static final double INTAKE_DEPLOY_GEAR_RATIO = 9.0; // 9.0

  private boolean hasMotorBeenPosResetThisCycle = false;

  private final DCMotor rackMotorType = DCMotor.getKrakenX60(1);
  private final DCMotorSim rackSim =
      new DCMotorSim(LinearSystemId.createDCMotorSystem(rackMotorType, INTAKE_DEPLOY_MOI,
          INTAKE_DEPLOY_GEAR_RATIO), rackMotorType);
  private final DIOSim limitSwitch = new DIOSim(IntakeSubsystemConstants.klimit_switchID);

  private Voltage rackAppliedVoltage = Volts.of(0);

  @Override
  public void updateInputs(RackIOInputs inputs) {
    rackSim.setInputVoltage(rackAppliedVoltage.in(Volts));
    rackSim.update(0.02);
    limitSwitch.setValue(
        inputs.rackMotorPosition.in(Rotations) < IntakeSubsystemConstants.extendedRotations);

    inputs.rackLimitSwitch = limitSwitch.getValue();
    inputs.rackMotorAppliedVoltage = rackAppliedVoltage;
    inputs.rackMotorTemp = Fahrenheit.of(75); // In sim we don't really care about temp this is
                                              // pretty realistic i think maybe
    inputs.rackMotorPosition = rackSim.getAngularPosition();
    inputs.rackMotorCurrent = Amps.of(rackSim.getCurrentDrawAmps());
    inputs.rackMotorVelocity = rackSim.getAngularVelocity();
    inputs.hasMotorBeenPosResetThisCycle = this.hasMotorBeenPosResetThisCycle;
  }

  @Override
  public void limitSwitchExtensionControl() {
    if (!limitSwitch.getValue()) {
      rackAppliedVoltage = Volts.of(0);
      if (!hasMotorBeenPosResetThisCycle) {
        rackSim.setAngle(Rotations.of(IntakeSubsystemConstants.extendedRotations).in(Radians));
        hasMotorBeenPosResetThisCycle = true;
      }
    } else {
      rackAppliedVoltage = Volts.of(7);
      hasMotorBeenPosResetThisCycle = false;
    }
  }

  @Override
  public void setPosition(Angle position) {
    rackSim.setAngle(position.in(Radians));
  }

  @Override
  public void zeroEncoder(Angle position) {
    rackSim.setAngle(position.in(Radians));
  }

  @Override
  public void stop() {
    rackAppliedVoltage = Volts.of(0);
  }

  @Override
  public void set(double percent) {
    rackAppliedVoltage = Volts.of(percent * 12.0);
  }

  // TODO: implement sysid routine for rack
  @Override
  public void runSysIdRoutine(Voltage volts) {}

  @Override
  public TalonFX getIntakeMotor() {
    return null;
  }
}
