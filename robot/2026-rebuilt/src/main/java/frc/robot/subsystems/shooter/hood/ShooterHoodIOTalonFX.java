package frc.robot.subsystems.shooter.hood;

import org.littletonrobotics.junction.Logger;
import com.ctre.phoenix6.BaseStatusSignal;
import com.ctre.phoenix6.StatusSignal;
import com.ctre.phoenix6.controls.PositionVoltage;
import com.ctre.phoenix6.hardware.ParentDevice;
import com.ctre.phoenix6.hardware.TalonFX;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.AngularVelocity;
import edu.wpi.first.units.measure.Current;
import edu.wpi.first.units.measure.Temperature;
import edu.wpi.first.units.measure.Voltage;
import frc.robot.RobotMap;
import frc.robot.RobotMap.ShooterConstants;
import frc.robot.utils.PhoenixUtil;

public class ShooterHoodIOTalonFX implements ShooterHoodIO {

  private final TalonFX hoodMotor = new TalonFX(RobotMap.ShooterConstants.ShooterHood);
  private final PositionVoltage positionVoltage = new PositionVoltage(0);
  private double HoodAngleMultiplier = 1.0;



  private final StatusSignal<Angle> shooterHoodMotorPosition;
  private final StatusSignal<AngularVelocity> shooterHoodMotorVelocity;
  private final StatusSignal<Voltage> shooterHoodMotorAppliedVoltage;
  private final StatusSignal<Current> shooterHoodMotorCurrent;
  private final StatusSignal<Temperature> shooterHoodMotorTemp;

  public ShooterHoodIOTalonFX() {
    PhoenixUtil.tryUntilOk(5, () -> hoodMotor.getConfigurator()
        .apply(ShooterConstants.getShooterHoodConfiguration(), 0.25));

    this.shooterHoodMotorAppliedVoltage = hoodMotor.getMotorVoltage();
    this.shooterHoodMotorCurrent = hoodMotor.getStatorCurrent();
    this.shooterHoodMotorPosition = hoodMotor.getPosition();
    this.shooterHoodMotorTemp = hoodMotor.getDeviceTemp();
    this.shooterHoodMotorVelocity = hoodMotor.getVelocity();

    BaseStatusSignal.setUpdateFrequencyForAll(50, shooterHoodMotorAppliedVoltage,
        shooterHoodMotorCurrent, shooterHoodMotorPosition, shooterHoodMotorTemp,
        shooterHoodMotorVelocity);
    ParentDevice.optimizeBusUtilizationForAll(hoodMotor);
  }

  @Override
  public void updateInputs(HoodIOInputs inputs) {
    BaseStatusSignal.refreshAll(shooterHoodMotorAppliedVoltage, shooterHoodMotorCurrent,
        shooterHoodMotorPosition, shooterHoodMotorTemp, shooterHoodMotorVelocity);
    inputs.hoodAngleMultiplier = this.HoodAngleMultiplier;
    inputs.hoodMotorAppliedVoltage = shooterHoodMotorAppliedVoltage.getValue();
    inputs.hoodMotorCurrent = shooterHoodMotorCurrent.getValue();
    inputs.hoodMotorPosition = shooterHoodMotorPosition.getValue();
    inputs.hoodMotorVelocity = shooterHoodMotorVelocity.getValue();
    inputs.hoodmotorTemp = shooterHoodMotorTemp.getValue();
  }

  @Override
  public void updateHoodAngleMultiplier(double toAdd) {
    if (HoodAngleMultiplier + toAdd > 1.2 || HoodAngleMultiplier + toAdd < 0.8) {
      return;
    } else {
      HoodAngleMultiplier += toAdd;
    }
  }

  @Override
  public void setPosition(Angle position) {
    hoodMotor.setControl(positionVoltage.withPosition(position));
  }

  @Override
  public void setDutyCycle(double percent) {
    hoodMotor.set(percent);
  }

  @Override
  public void stop() {
    hoodMotor.set(0);
  }

  @Override
  public void setEncoderAngle(Angle position) {
    hoodMotor.setPosition(position);
  }


}
