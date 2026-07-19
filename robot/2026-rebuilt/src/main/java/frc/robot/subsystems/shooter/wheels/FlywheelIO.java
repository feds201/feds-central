package frc.robot.subsystems.shooter.wheels;

import static edu.wpi.first.units.Units.Amps;
import static edu.wpi.first.units.Units.Celsius;
import static edu.wpi.first.units.Units.Rotations;
import static edu.wpi.first.units.Units.RotationsPerSecond;
import static edu.wpi.first.units.Units.Volts;
import org.littletonrobotics.junction.AutoLog;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.AngularVelocity;
import edu.wpi.first.units.measure.Current;
import edu.wpi.first.units.measure.Temperature;
import edu.wpi.first.units.measure.Voltage;

public interface FlywheelIO {

  @AutoLog
  public static class FlywheelIOInputs {
    public Temperature flywheelMotorTemp = Celsius.of(0);
    public Voltage flywheelMotorAppliedVoltage = Volts.of(0);
    public Current flywheelMotorCurrent = Amps.of(0);
    public Angle flywheelMotorPosition = Rotations.of(0);
    public AngularVelocity flywheelMotorVelocity = RotationsPerSecond.of(0);
  }

  public default void updateInputs(FlywheelIOInputs inputs) {}

  public default void setVelocity(AngularVelocity velocity) {}

  public default void setCoast() {}

  public default void runSysidRoutine(Voltage volts) {}


}
