package frc.robot.subsystems.shooter.wheels;

import com.ctre.phoenix6.BaseStatusSignal;
import com.ctre.phoenix6.StatusSignal;
import com.ctre.phoenix6.controls.CoastOut;
import com.ctre.phoenix6.controls.Follower;
import com.ctre.phoenix6.controls.VelocityVoltage;
import com.ctre.phoenix6.controls.VoltageOut;
import com.ctre.phoenix6.hardware.ParentDevice;
import com.ctre.phoenix6.hardware.TalonFX;
import com.ctre.phoenix6.signals.MotorAlignmentValue;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.AngularVelocity;
import edu.wpi.first.units.measure.Current;
import edu.wpi.first.units.measure.Temperature;
import edu.wpi.first.units.measure.Voltage;
import frc.robot.RobotMap.ShooterConstants;
import frc.robot.utils.PhoenixUtil;

public class FlywheelIOTalonFX implements FlywheelIO {

  private TalonFX shooterLeader = new TalonFX(ShooterConstants.ShooterRightTop);
  private TalonFX shooterFollower1 = new TalonFX(ShooterConstants.ShooterBottomLeft);
  private TalonFX shooterFollower2 = new TalonFX(ShooterConstants.ShooterRightBottom);
  private TalonFX shooterFollower3 = new TalonFX(ShooterConstants.ShooterTopLeft);
  private VelocityVoltage velocityVoltageControl = new VelocityVoltage(0);

  private final StatusSignal<Angle> flywheelMotorPosition;
  private final StatusSignal<AngularVelocity> flywheelMotorVelocity;
  private final StatusSignal<Voltage> flywheelMotorAppliedVoltage;
  private final StatusSignal<Current> flywheelMotorCurrent;
  private final StatusSignal<Temperature> flywheelMotorTemp;

  public FlywheelIOTalonFX() {
    shooterFollower1
        .setControl(new Follower(shooterLeader.getDeviceID(), MotorAlignmentValue.Opposed));
    shooterFollower2
        .setControl(new Follower(shooterLeader.getDeviceID(), MotorAlignmentValue.Aligned));
    shooterFollower3
        .setControl(new Follower(shooterLeader.getDeviceID(), MotorAlignmentValue.Opposed));

    velocityVoltageControl.Acceleration = 200;

    this.flywheelMotorAppliedVoltage = shooterLeader.getMotorVoltage();
    this.flywheelMotorCurrent = shooterLeader.getStatorCurrent();
    this.flywheelMotorPosition = shooterLeader.getPosition();
    this.flywheelMotorTemp = shooterLeader.getDeviceTemp();
    this.flywheelMotorVelocity = shooterLeader.getVelocity();

    PhoenixUtil.tryUntilOk(5, () -> shooterLeader.getConfigurator()
        .apply(ShooterConstants.getShooterWheelsConfiguration(), .25));

    BaseStatusSignal.setUpdateFrequencyForAll(50, flywheelMotorAppliedVoltage, flywheelMotorCurrent,
        flywheelMotorPosition, flywheelMotorTemp, flywheelMotorVelocity);
    ParentDevice.optimizeBusUtilizationForAll(shooterLeader, shooterFollower1, shooterFollower2,
        shooterFollower3);
  }

  @Override
  public void updateInputs(FlywheelIOInputs inputs) {
    inputs.flywheelMotorAppliedVoltage = flywheelMotorAppliedVoltage.getValue();
    inputs.flywheelMotorCurrent = flywheelMotorCurrent.getValue();
    inputs.flywheelMotorPosition = flywheelMotorPosition.getValue();
    inputs.flywheelMotorTemp = flywheelMotorTemp.getValue();
    inputs.flywheelMotorVelocity = flywheelMotorVelocity.getValue();
  }

  @Override
  public void setVelocity(AngularVelocity velocity) {
    shooterLeader.setControl(velocityVoltageControl.withVelocity(velocity));
  }

  @Override
  public void runSysidRoutine(Voltage volts) {
    shooterLeader.setControl(new VoltageOut(volts));
  }

  @Override
  public void setCoast() {
    shooterLeader.setControl(new CoastOut());
  }
}
