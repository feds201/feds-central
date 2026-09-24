package frc.robot.subsystems.feeder;

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
import frc.robot.RobotMap.FeederConstants;
import frc.robot.utils.PhoenixUtil;

public class FeederIOTalonFX implements FeederIO {

  private final TalonFX feederMotor;
  private final StatusSignal<Angle> feederMotorPosition;
  private final StatusSignal<AngularVelocity> feederMotorVelocity;
  private final StatusSignal<Voltage> feederMotorAppliedVoltage;
  private final StatusSignal<Current> feederMotorCurrent;
  private final StatusSignal<Temperature> feederMotorTemp;

  private final TalonFXConfiguration config;
  private final VoltageOut vOut = new VoltageOut(0);

  public FeederIOTalonFX() {
    feederMotor = new TalonFX(FeederConstants.kFeederKickerMotorId);
    feederMotorPosition = feederMotor.getPosition();
    feederMotorVelocity = feederMotor.getVelocity();
    feederMotorAppliedVoltage = feederMotor.getMotorVoltage();
    feederMotorCurrent = feederMotor.getStatorCurrent();
    feederMotorTemp = feederMotor.getDeviceTemp();

    config = new TalonFXConfiguration();
    config.MotorOutput.NeutralMode = NeutralModeValue.Coast;
    config.MotorOutput.Inverted = InvertedValue.Clockwise_Positive;
    config.CurrentLimits.StatorCurrentLimitEnable = true;
    config.CurrentLimits.StatorCurrentLimit = 60;

    PhoenixUtil.tryUntilOk(5, () -> feederMotor.getConfigurator().apply(config, .25));

    BaseStatusSignal.setUpdateFrequencyForAll(50, feederMotorPosition, feederMotorVelocity,
        feederMotorAppliedVoltage, feederMotorCurrent, feederMotorTemp);
    ParentDevice.optimizeBusUtilizationForAll(feederMotor);
  }

  @Override
  public void updateInputs(FeederIOInputs inputs) {
    BaseStatusSignal.refreshAll(feederMotorPosition, feederMotorVelocity, feederMotorAppliedVoltage,
        feederMotorCurrent, feederMotorTemp);

    inputs.feederMotorPosition = feederMotorPosition.getValue();

    inputs.feederMotorVelocity = feederMotorVelocity.getValue();

    inputs.feederMotorAppliedVoltage = feederMotorAppliedVoltage.getValue();

    inputs.feederMotorCurrent = feederMotorCurrent.getValue();

    inputs.feederMotorTemp = feederMotorTemp.getValue();
  }

  @Override
  public void setVoltage(Voltage volts) {
    feederMotor.setControl(vOut.withOutput(volts));
  }

  @Override
  public void stop() {
    feederMotor.setControl(vOut.withOutput(0));
  }

  @Override
  public void runSysIdRoutine(Voltage volts) {
    feederMotor.setControl(new VoltageOut(0));
  }

}
