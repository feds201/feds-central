package frc.robot.subsystems.spindexer;

import com.ctre.phoenix6.BaseStatusSignal;
import com.ctre.phoenix6.StatusSignal;
import com.ctre.phoenix6.configs.TalonFXConfiguration;
import com.ctre.phoenix6.controls.VoltageOut;
import com.ctre.phoenix6.hardware.ParentDevice;
import com.ctre.phoenix6.hardware.TalonFX;
import com.ctre.phoenix6.signals.InvertedValue;
import com.ctre.phoenix6.signals.NeutralModeValue;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.AngularVelocity;
import edu.wpi.first.units.measure.Current;
import edu.wpi.first.units.measure.Temperature;
import edu.wpi.first.units.measure.Voltage;
import frc.robot.RobotMap.SpindexerConstants;
import frc.robot.utils.PhoenixUtil;

public class SpindexerIOTalonFX implements SpindexerIO {

  private final TalonFX spindexerMotor;
  private final StatusSignal<Angle> spindexerMotorPosition;
  private final StatusSignal<AngularVelocity> spindexerMotorVelocity;
  private final StatusSignal<Voltage> spindexerMotorAppliedVoltage;
  private final StatusSignal<Current> spindexerMotorCurrent;
  private final StatusSignal<Temperature> spindexerMotorTemp;

  private final TalonFXConfiguration config;
  private final VoltageOut vOut = new VoltageOut(0);

  public SpindexerIOTalonFX() {
    spindexerMotor = new TalonFX(SpindexerConstants.kSpindexerMotorId);
    spindexerMotorPosition = spindexerMotor.getPosition();
    spindexerMotorVelocity = spindexerMotor.getVelocity();
    spindexerMotorAppliedVoltage = spindexerMotor.getMotorVoltage();
    spindexerMotorCurrent = spindexerMotor.getStatorCurrent();
    spindexerMotorTemp = spindexerMotor.getDeviceTemp();

    config = new TalonFXConfiguration();
    config.MotorOutput.NeutralMode = NeutralModeValue.Coast;
    config.MotorOutput.Inverted = InvertedValue.Clockwise_Positive;
    config.CurrentLimits.StatorCurrentLimit = 40;
    PhoenixUtil.tryUntilOk(5, () -> spindexerMotor.getConfigurator().apply(config, .25));

    BaseStatusSignal.setUpdateFrequencyForAll(50, spindexerMotorPosition, spindexerMotorVelocity,
        spindexerMotorAppliedVoltage, spindexerMotorCurrent, spindexerMotorTemp);
    ParentDevice.optimizeBusUtilizationForAll(spindexerMotor);
  }

  @Override
  public void updateInputs(SpindexerIOInputs inputs) {
    BaseStatusSignal.refreshAll(spindexerMotorPosition, spindexerMotorVelocity,
        spindexerMotorAppliedVoltage, spindexerMotorCurrent, spindexerMotorTemp);

    inputs.spindexerMotorPosition = spindexerMotorPosition.getValue();

    inputs.spindexerMotorVelocity = spindexerMotorVelocity.getValue();

    inputs.spindexerMotorAppliedVoltage = spindexerMotorAppliedVoltage.getValue();

    inputs.spindexerMotorCurrent = spindexerMotorCurrent.getValue();

    inputs.spindexerMotorTemp = spindexerMotorTemp.getValue();
  }

  @Override
  public void setVoltage(Voltage volts) {
    spindexerMotor.setControl(vOut.withOutput(volts));
  }

  @Override
  public void stop() {
    spindexerMotor.setControl(vOut.withOutput(0));
  }

  // TODO: implement sysid routine for spindexer
  @Override
  public void runSysIdRoutine(Voltage volts) {
    spindexerMotor.setControl(new VoltageOut(0));
  }

  @Override
  public TalonFX getSpindexerMotor() {
    return spindexerMotor;
  }
}
