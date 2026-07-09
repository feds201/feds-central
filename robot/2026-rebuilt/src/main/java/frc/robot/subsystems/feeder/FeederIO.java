package frc.robot.subsystems.feeder;

import static edu.wpi.first.units.Units.Amps;
import static edu.wpi.first.units.Units.Celsius;
import static edu.wpi.first.units.Units.Rotations;
import static edu.wpi.first.units.Units.RotationsPerSecond;
import static edu.wpi.first.units.Units.Volts;
import org.littletonrobotics.junction.AutoLog;
import com.ctre.phoenix6.hardware.TalonFX;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.AngularVelocity;
import edu.wpi.first.units.measure.Current;
import edu.wpi.first.units.measure.Temperature;
import edu.wpi.first.units.measure.Voltage;

public interface FeederIO {

  @AutoLog
  public static class FeederIOInputs {
    public Temperature feederMotorTemp = Celsius.of(0);
    public Voltage feederMotorAppliedVoltage = Volts.of(0);
    public Current feederMotorCurrent = Amps.of(0);
    public Angle feederMotorPosition = Rotations.of(0);
    public AngularVelocity feederMotorVelocity = RotationsPerSecond.of(0);
  }

  public default void updateInputs(FeederIOInputs inputs) {}

  public default void setVoltage(Voltage volts) {}

  public default void stop() {}

  public default void runSysIdRoutine(Voltage volts) {}

  public default TalonFX getFeederMotor() {
    return null;
  }
}
