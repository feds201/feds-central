package frc.robot.subsystems.shooter.wheels;

import static edu.wpi.first.units.Units.Fahrenheit;
import com.ctre.phoenix6.controls.CoastOut;
import com.ctre.phoenix6.controls.PositionVoltage;
import com.ctre.phoenix6.controls.VelocityVoltage;
import com.ctre.phoenix6.controls.VoltageOut;
import com.ctre.phoenix6.hardware.TalonFX;
import com.ctre.phoenix6.sim.ChassisReference;
import com.ctre.phoenix6.sim.TalonFXSimState;
import com.ctre.phoenix6.sim.TalonFXSimState.MotorType;
import edu.wpi.first.math.system.plant.DCMotor;
import edu.wpi.first.math.system.plant.LinearSystemId;
import edu.wpi.first.units.measure.AngularVelocity;
import edu.wpi.first.units.measure.Voltage;
import edu.wpi.first.wpilibj.simulation.DCMotorSim;
import frc.robot.RobotMap;
import frc.robot.RobotMap.ShooterConstants;
import frc.robot.utils.PhoenixUtil;

public class FlywheelIOSim implements FlywheelIO {
  /** Shooter wheel MOI (kg·m²). 0.5 × mass × radius² for a solid cylinder. */
  private static final double SHOOTER_MOI = 0.5 * 2.0 * 0.05 * 0.05;

  /** Shooter gear ratio (motor rot / wheel rot). 36T motor gear -> 24T axle gear (overdrive). */
  private static final double SHOOTER_GEAR_RATIO = 24.0 / 36.0;

  private final DCMotor flywheelMotorType = DCMotor.getKrakenX60(4);
  private final DCMotorSim flywheelDcMotorSim = new DCMotorSim(
      LinearSystemId.createDCMotorSystem(flywheelMotorType, SHOOTER_MOI, SHOOTER_GEAR_RATIO),
      flywheelMotorType);
  private final TalonFX flywheelTalonFX = new TalonFX(RobotMap.ShooterConstants.ShooterRightTop);
  private final VelocityVoltage velocityVoltage = new VelocityVoltage(0);

  public FlywheelIOSim() {
    velocityVoltage.Acceleration = 200;

    PhoenixUtil.tryUntilOk(5, () -> flywheelTalonFX.getConfigurator()
        .apply(ShooterConstants.getShooterWheelsConfiguration(), .25));

    TalonFXSimState ctreFlywheelSimState = flywheelTalonFX.getSimState();
    ctreFlywheelSimState.Orientation = ChassisReference.Clockwise_Positive;
    ctreFlywheelSimState.setMotorType(MotorType.KrakenX60);
  }

  @Override
  public void updateInputs(FlywheelIOInputs inputs) {
    TalonFXSimState ctreFlywheelSimState = flywheelTalonFX.getSimState();
    PhoenixUtil.updateTalonSimState(flywheelDcMotorSim, ctreFlywheelSimState, SHOOTER_GEAR_RATIO);
    inputs.flywheelMotorAppliedVoltage = ctreFlywheelSimState.getMotorVoltageMeasure();
    inputs.flywheelMotorCurrent = ctreFlywheelSimState.getSupplyCurrentMeasure();
    inputs.flywheelMotorPosition = flywheelTalonFX.getPosition().getValue();
    inputs.flywheelMotorTemp = Fahrenheit.of(75);
    inputs.flywheelMotorVelocity = flywheelTalonFX.getVelocity().getValue();
  }

  @Override
  public void setVelocity(AngularVelocity velocity) {
    flywheelTalonFX.setControl(velocityVoltage.withVelocity(velocity));
  }

  @Override
  public void runSysidRoutine(Voltage volts) {
    flywheelTalonFX.setControl(new VoltageOut(volts));
  }

  @Override
  public void setCoast() {
    flywheelTalonFX.setControl(new CoastOut());
  }
}
