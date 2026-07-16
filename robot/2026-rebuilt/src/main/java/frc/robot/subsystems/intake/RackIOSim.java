package frc.robot.subsystems.intake;

import static edu.wpi.first.units.Units.Fahrenheit;
import static edu.wpi.first.units.Units.Radians;
import static edu.wpi.first.units.Units.Rotations;
import static edu.wpi.first.units.Units.Volts;
import com.ctre.phoenix6.controls.DutyCycleOut;
import com.ctre.phoenix6.controls.MotionMagicVoltage;
import com.ctre.phoenix6.controls.VoltageOut;
import com.ctre.phoenix6.hardware.TalonFX;
import com.ctre.phoenix6.sim.ChassisReference;
import com.ctre.phoenix6.sim.TalonFXSimState;
import edu.wpi.first.math.system.plant.DCMotor;
import edu.wpi.first.math.system.plant.LinearSystemId;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.Voltage;
import edu.wpi.first.wpilibj.RobotController;
import edu.wpi.first.wpilibj.simulation.DCMotorSim;
import edu.wpi.first.wpilibj.simulation.DIOSim;
import frc.robot.RobotMap.IntakeSubsystemConstants;
import frc.robot.utils.PhoenixUtil;

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
  private final DCMotorSim rackDcMotorSim =
      new DCMotorSim(LinearSystemId.createDCMotorSystem(rackMotorType, INTAKE_DEPLOY_MOI,
          INTAKE_DEPLOY_GEAR_RATIO), rackMotorType);
  private final DIOSim limitSwitch = new DIOSim(IntakeSubsystemConstants.klimit_switchID);
  private final TalonFX rackTalonFX = new TalonFX(IntakeSubsystemConstants.kMotorID);


  private final MotionMagicVoltage positionOut = new MotionMagicVoltage(Rotations.of(0));
  private final VoltageOut voltageOut = new VoltageOut(0);
  private final DutyCycleOut dutyCycleOut = new DutyCycleOut(0);

  public RackIOSim() {

    // Apply config; repeat to ensure application (some hardware requires it)
    PhoenixUtil.tryUntilOk(5, () -> rackTalonFX.getConfigurator()
        .apply(IntakeSubsystemConstants.getRackMotorConfig(), 0.25));
    TalonFXSimState ctreRackSimState = rackTalonFX.getSimState();
    ctreRackSimState.Orientation = ChassisReference.CounterClockwise_Positive;
    ctreRackSimState.setMotorType(TalonFXSimState.MotorType.KrakenX60);
  }

  @Override
  public void updateInputs(RackIOInputs inputs) {
    TalonFXSimState ctreRackSimState = rackTalonFX.getSimState();
    PhoenixUtil.updateTalonSimState(rackDcMotorSim, ctreRackSimState, INTAKE_DEPLOY_GEAR_RATIO);

    limitSwitch.setValue(
        inputs.rackMotorPosition.in(Rotations) < IntakeSubsystemConstants.extendedRotations);

    inputs.rackLimitSwitch = limitSwitch.getValue();
    inputs.rackMotorAppliedVoltage = ctreRackSimState.getMotorVoltageMeasure();
    inputs.rackMotorTemp = Fahrenheit.of(75); // In sim we don't really care about temp this is
                                              // pretty realistic i think maybe
    inputs.rackMotorCurrent = ctreRackSimState.getSupplyCurrentMeasure();
    inputs.rackMotorPosition = rackTalonFX.getPosition().getValue();
    inputs.rackMotorVelocity = rackTalonFX.getVelocity().getValue();
    inputs.hasMotorBeenPosResetThisCycle = this.hasMotorBeenPosResetThisCycle;
  }

  @Override
  public void limitSwitchExtensionControl() {
    if (!limitSwitch.getValue()) {
      rackTalonFX.setControl(voltageOut.withOutput(0));
      if (!hasMotorBeenPosResetThisCycle) {
        setPosition(Rotations.of(IntakeSubsystemConstants.extendedRotations));
        hasMotorBeenPosResetThisCycle = true;
      }
    } else {
      rackTalonFX.setControl(voltageOut.withOutput(7));
      hasMotorBeenPosResetThisCycle = false;
    }
  }

  @Override
  public void setPosition(Angle position) {
    rackTalonFX.setControl(positionOut.withPosition(position));
  }

  @Override
  public void zeroEncoder(Angle position) {
    rackDcMotorSim.setAngle(position.in(Radians));
    rackTalonFX.getSimState().setRawRotorPosition(position.times(INTAKE_DEPLOY_GEAR_RATIO));
  }

  @Override
  public void stop() {
    rackTalonFX.setControl(voltageOut.withOutput(0));
  }

  @Override
  public void set(double percent) {
    rackTalonFX.setControl(dutyCycleOut.withOutput(percent));
  }

  // TODO: implement sysid routine for rack
  @Override
  public void runSysIdRoutine(Voltage volts) {}

}
