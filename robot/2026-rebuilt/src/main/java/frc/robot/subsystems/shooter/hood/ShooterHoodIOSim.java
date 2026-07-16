package frc.robot.subsystems.shooter.hood;

import static edu.wpi.first.units.Units.Fahrenheit;
import static edu.wpi.first.units.Units.Radians;
import com.ctre.phoenix6.controls.PositionVoltage;
import com.ctre.phoenix6.hardware.TalonFX;
import com.ctre.phoenix6.sim.ChassisReference;
import com.ctre.phoenix6.sim.TalonFXSimState;
import com.ctre.phoenix6.sim.TalonFXSimState.MotorType;
import edu.wpi.first.math.system.plant.DCMotor;
import edu.wpi.first.math.system.plant.LinearSystemId;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.wpilibj.simulation.DCMotorSim;
import edu.wpi.first.wpilibj.simulation.SingleJointedArmSim;
import frc.robot.RobotMap;
import frc.robot.RobotMap.ShooterConstants;
import frc.robot.utils.PhoenixUtil;

public class ShooterHoodIOSim implements ShooterHoodIO {

  /** Hood gear ratio (motor rot / mechanism rot). Derived from soft limit and angle range. */
  private static final double HOOD_GEAR_RATIO = 30.0 * 2 * Math.PI / Math.toRadians(67.4 - 35.5);

  /**
   * Hood mechanism moment of inertia (kg·m²), estimated via WPILib uniform-rod approximation. TODO
   * update placeholder: measure arm length and mass from CAD.
   */
  private static final double HOOD_MOI_KGM2 = SingleJointedArmSim.estimateMOI(0.23, 3.0); // 23cm
                                                                                          // arm,
                                                                                          // 3kg

  private final DCMotor rackMotorType = DCMotor.getKrakenX60(1);
  private final DCMotorSim hoodDcMotorSim = new DCMotorSim(
      LinearSystemId.createDCMotorSystem(rackMotorType, HOOD_MOI_KGM2, HOOD_GEAR_RATIO),
      rackMotorType);
  private final TalonFX hoodTalonFX = new TalonFX(RobotMap.ShooterConstants.ShooterHood);
  private final PositionVoltage positionVoltage = new PositionVoltage(0);
  private double hoodAngleMultiplier = 1.0;

  public ShooterHoodIOSim() {
    // Apply config; repeat to ensure application (some hardware requires it)
    PhoenixUtil.tryUntilOk(5, () -> hoodTalonFX.getConfigurator()
        .apply(ShooterConstants.getShooterHoodConfiguration(), 0.25));
    TalonFXSimState ctreHoodSimState = hoodTalonFX.getSimState();
    ctreHoodSimState.Orientation = ChassisReference.CounterClockwise_Positive;
    ctreHoodSimState.setMotorType(MotorType.KrakenX60);
  }

  @Override
  public void updateInputs(HoodIOInputs inputs) {
    TalonFXSimState ctreHoodSimstate = hoodTalonFX.getSimState();
    PhoenixUtil.updateTalonSimState(hoodDcMotorSim, ctreHoodSimstate, HOOD_GEAR_RATIO);
    inputs.hoodAngleMultiplier = this.hoodAngleMultiplier;
    inputs.hoodMotorAppliedVoltage = ctreHoodSimstate.getMotorVoltageMeasure();
    inputs.hoodMotorCurrent = ctreHoodSimstate.getSupplyCurrentMeasure();
    inputs.hoodMotorPosition = hoodTalonFX.getPosition().getValue();
    inputs.hoodMotorVelocity = hoodTalonFX.getVelocity().getValue();
    inputs.hoodmotorTemp = Fahrenheit.of(75); // we dont care about temp in sim, 75 F accurate
                                              // enough
  }

  @Override
  public void updateHoodAngleMultiplier(double toAdd) {
    if (hoodAngleMultiplier + toAdd > 1.2 || hoodAngleMultiplier + toAdd < 0.8) {
      return;
    } else {
      hoodAngleMultiplier += toAdd;
    }
  }

  @Override
  public void setPosition(Angle position) {
    hoodTalonFX.setControl(positionVoltage.withPosition(position));
  }

  @Override
  public void setDutyCycle(double percent) {
    hoodTalonFX.set(percent);
  }

  @Override
  public void stop() {
    hoodTalonFX.set(0);
  }

  @Override
  public void setEncoderAngle(Angle position) {
    hoodDcMotorSim.setAngle(position.in(Radians));
    hoodTalonFX.getSimState().setRawRotorPosition(position.times(HOOD_GEAR_RATIO));
  }
}
