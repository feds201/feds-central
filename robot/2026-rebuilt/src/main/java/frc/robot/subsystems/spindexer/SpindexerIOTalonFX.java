package frc.robot.subsystems.spindexer;

import com.ctre.phoenix6.configs.TalonFXConfiguration;
import com.ctre.phoenix6.controls.VoltageOut;
import com.ctre.phoenix6.hardware.TalonFX;
import com.ctre.phoenix6.signals.InvertedValue;
import com.ctre.phoenix6.signals.NeutralModeValue;
import edu.wpi.first.units.measure.Voltage;
import frc.robot.RobotMap.SpindexerConstants;

public class SpindexerIOTalonFX implements SpindexerIO {

  private final TalonFX spindexerMotor;
  private final TalonFXConfiguration config;
  private final VoltageOut vOut = new VoltageOut(0);

  public SpindexerIOTalonFX() {
    spindexerMotor = new TalonFX(SpindexerConstants.kSpindexerMotorId);

    config = new TalonFXConfiguration();
    config.MotorOutput.NeutralMode = NeutralModeValue.Coast;
    config.MotorOutput.Inverted = InvertedValue.Clockwise_Positive;
    config.CurrentLimits.StatorCurrentLimit = 40;
    for (int i = 0; i < 2; ++i) {
      var status = spindexerMotor.getConfigurator().apply(config);
      if (status.isOK())
        break;
    }
  }

  @Override
  public void updateInputs(SpindexerIOInputs inputs) {

    inputs.spindexerMotorPosition = spindexerMotor.getPosition().getValue();

    inputs.spindexerMotorVelocity = spindexerMotor.getVelocity().getValue();

    inputs.spindexerMotorAppliedVoltage = spindexerMotor.getMotorVoltage().getValue();

    inputs.spindexerMotorCurrent = spindexerMotor.getStatorCurrent().getValue();

    inputs.spindexerMotorTemp = spindexerMotor.getDeviceTemp().getValue();
  }

  @Override
  public void setVoltage(Voltage volts) {
    spindexerMotor.setControl(vOut.withOutput(volts));
  }

  @Override
  public void stop() {
    spindexerMotor.setControl(vOut.withOutput(0));
  }

  @Override
  public void runSysIdRoutine(Voltage volts) {
    spindexerMotor.setControl(new VoltageOut(volts));
  }
}
