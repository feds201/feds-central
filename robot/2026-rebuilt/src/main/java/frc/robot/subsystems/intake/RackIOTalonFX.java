package frc.robot.subsystems.intake;

import static edu.wpi.first.units.Units.Rotations;
import com.ctre.phoenix6.BaseStatusSignal;
import com.ctre.phoenix6.StatusSignal;
import com.ctre.phoenix6.configs.TalonFXConfiguration;
import com.ctre.phoenix6.controls.MotionMagicVoltage;
import com.ctre.phoenix6.controls.VoltageOut;
import com.ctre.phoenix6.hardware.ParentDevice;
import com.ctre.phoenix6.hardware.TalonFX;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.AngularVelocity;
import edu.wpi.first.units.measure.Current;
import edu.wpi.first.units.measure.Temperature;
import edu.wpi.first.units.measure.Voltage;
import edu.wpi.first.wpilibj.DigitalInput;
import frc.robot.RobotMap;
import frc.robot.RobotMap.IntakeSubsystemConstants;
import frc.robot.utils.PhoenixUtil;

public class RackIOTalonFX implements RackIO {
  private final TalonFX rackMotor;
  private final DigitalInput limitSwitch;
  private boolean hasMotorBeenPosResetThisCycle = false; // Track if we've reset the motor position
                                                         // during this command cycle

  private final StatusSignal<Angle> rackMotorPosition;
  private final StatusSignal<AngularVelocity> rackMotorVelocity;
  private final StatusSignal<Voltage> rackMotorAppliedVoltage;
  private final StatusSignal<Current> rackMotorCurrent;
  private final StatusSignal<Temperature> rackMotorTemp;

  private final MotionMagicVoltage positionOut = new MotionMagicVoltage(Rotations.of(0));

  public RackIOTalonFX() {
    this.rackMotor = new TalonFX(RobotMap.IntakeSubsystemConstants.kMotorID);

    this.limitSwitch = new DigitalInput(RobotMap.IntakeSubsystemConstants.klimit_switchID);

    PhoenixUtil.tryUntilOk(5, () -> rackMotor.getConfigurator()
        .apply(IntakeSubsystemConstants.getRackMotorConfig(), 0.25));


    this.rackMotorPosition = rackMotor.getPosition();
    this.rackMotorVelocity = rackMotor.getVelocity();
    this.rackMotorAppliedVoltage = rackMotor.getMotorVoltage();
    this.rackMotorCurrent = rackMotor.getStatorCurrent();
    this.rackMotorTemp = rackMotor.getDeviceTemp();

    BaseStatusSignal.setUpdateFrequencyForAll(50, rackMotorPosition, rackMotorVelocity,
        rackMotorAppliedVoltage, rackMotorCurrent, rackMotorTemp);
    ParentDevice.optimizeBusUtilizationForAll(rackMotor);
  }

  @Override
  public void updateInputs(RackIOInputs inputs) {
    BaseStatusSignal.refreshAll(rackMotorAppliedVoltage, rackMotorCurrent, rackMotorPosition,
        rackMotorTemp, rackMotorVelocity);
    inputs.rackMotorTemp = rackMotorTemp.getValue();
    inputs.rackMotorAppliedVoltage = rackMotorAppliedVoltage.getValue();
    inputs.rackMotorCurrent = rackMotorCurrent.getValue();
    inputs.rackMotorPosition = rackMotorPosition.getValue();
    inputs.rackMotorVelocity = rackMotorVelocity.getValue();
    inputs.rackLimitSwitch = limitSwitch.get();
    inputs.hasMotorBeenPosResetThisCycle = this.hasMotorBeenPosResetThisCycle;
  }

  @Override
  public void limitSwitchExtensionControl() {
    if (!limitSwitch.get()) {
      rackMotor.setControl(new VoltageOut(0));
      if (!hasMotorBeenPosResetThisCycle) {
        rackMotor.setPosition(IntakeSubsystemConstants.extendedRotations);
        hasMotorBeenPosResetThisCycle = true;
      }
    } else {
      rackMotor.setControl(new VoltageOut(7));
      hasMotorBeenPosResetThisCycle = false;
    }
  }

  @Override
  public void setPosition(Angle position) {
    rackMotor.setControl(positionOut.withPosition(position));
  }

  @Override
  public void zeroEncoder(Angle position) {
    rackMotor.setPosition(position);
  }

  @Override
  public void stop() {
    rackMotor.setControl(new VoltageOut(0));
  }

  @Override
  public void set(double percent) {
    rackMotor.set(percent);
  }

  // TODO: implement sysid routine for rack
  @Override
  public void runSysIdRoutine(Voltage volts) {
    rackMotor.setControl(new VoltageOut(0));
  }

  @Override
  public TalonFX getIntakeMotor() {
    return rackMotor;
  }

  @Override
  public DigitalInput getLimitSwitch() {
    return limitSwitch;
  }
}
