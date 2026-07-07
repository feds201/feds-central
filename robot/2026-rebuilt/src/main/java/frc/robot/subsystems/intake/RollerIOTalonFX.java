package frc.robot.subsystems.intake;

import java.io.ObjectInputFilter.Status;
import com.ctre.phoenix6.BaseStatusSignal;
import com.ctre.phoenix6.StatusSignal;
import com.ctre.phoenix6.configs.TalonFXConfiguration;
import com.ctre.phoenix6.controls.Follower;
import com.ctre.phoenix6.controls.VoltageOut;
import com.ctre.phoenix6.hardware.ParentDevice;
import com.ctre.phoenix6.hardware.TalonFX;
import com.ctre.phoenix6.signals.InvertedValue;
import com.ctre.phoenix6.signals.MotorAlignmentValue;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.AngularVelocity;
import edu.wpi.first.units.measure.Current;
import edu.wpi.first.units.measure.Temperature;
import edu.wpi.first.units.measure.Voltage;
import edu.wpi.first.wpilibj.DigitalInput;
import edu.wpi.first.wpilibj.motorcontrol.Talon;
import frc.robot.RobotMap;
import frc.robot.utils.PhoenixUtil;

public class RollerIOTalonFX implements RollerIO {
  private final TalonFX rollerMotorLeader;
  private final TalonFX rollerMotorFollower;

  private final StatusSignal<Temperature> rollerMotorTemp;
  private final StatusSignal<Angle> rollerMotorPosition;
  private final StatusSignal<AngularVelocity> rollerMotorVelocity;
  private final StatusSignal<Current> rollerMotorCurrent;
  private final StatusSignal<Voltage> rollerMotorAppliedVoltage;

  public RollerIOTalonFX() {
    rollerMotorLeader = new TalonFX(RobotMap.IntakeSubsystemConstants.kRollerMotorID);
    rollerMotorFollower = new TalonFX(RobotMap.IntakeSubsystemConstants.kRollerMotorFollowerID);
    rollerMotorFollower
        .setControl(new Follower(rollerMotorLeader.getDeviceID(), MotorAlignmentValue.Opposed));

    var rollerConfig = new TalonFXConfiguration();
    rollerConfig.CurrentLimits.StatorCurrentLimit = 55.0;
    rollerConfig.CurrentLimits.StatorCurrentLimitEnable = true;
    rollerConfig.MotorOutput.Inverted = InvertedValue.CounterClockwise_Positive;

    PhoenixUtil.tryUntilOk(5, () -> rollerMotorLeader.getConfigurator().apply(rollerConfig, .25));
    PhoenixUtil.tryUntilOk(5, () -> rollerMotorFollower.getConfigurator().apply(rollerConfig, .25));

    this.rollerMotorAppliedVoltage = rollerMotorLeader.getMotorVoltage();
    this.rollerMotorCurrent = rollerMotorLeader.getStatorCurrent();
    this.rollerMotorPosition = rollerMotorLeader.getPosition();
    this.rollerMotorVelocity = rollerMotorLeader.getVelocity();
    this.rollerMotorTemp = rollerMotorLeader.getDeviceTemp();

    BaseStatusSignal.setUpdateFrequencyForAll(50, rollerMotorAppliedVoltage, rollerMotorCurrent,
        rollerMotorPosition, rollerMotorTemp, rollerMotorVelocity);

    ParentDevice.optimizeBusUtilizationForAll(rollerMotorLeader, rollerMotorFollower);
  }

  @Override
  public void updateInputs(RollerIOInputs inputs) {
    BaseStatusSignal.refreshAll(rollerMotorAppliedVoltage, rollerMotorCurrent, rollerMotorPosition,
        rollerMotorTemp, rollerMotorVelocity);

    inputs.rollerMotorAppliedVoltage = rollerMotorAppliedVoltage.getValue();
    inputs.rollerMotorCurrent = rollerMotorCurrent.getValue();
    inputs.rollerMotorPosition = rollerMotorPosition.getValue();
    inputs.rollerMotorTemp = rollerMotorTemp.getValue();
    inputs.rollerMotorVelocity = rollerMotorVelocity.getValue();
  }

  @Override
  public void set(double percent) {
    rollerMotorLeader.set(percent);
  }

  @Override
  public void stop() {
    rollerMotorLeader.setControl(new VoltageOut(0));
  }

  // TODO: implement sysid routine for roller
  @Override
  public void runSysIdRoutine(Voltage volts) {
    rollerMotorLeader.setControl(new VoltageOut(0));
  }

  @Override
  public TalonFX getRollerMotorLeader() {
    return rollerMotorLeader;
  }

  @Override
  public TalonFX getRollerMotorFollower() {
    return rollerMotorFollower;
  }
}
