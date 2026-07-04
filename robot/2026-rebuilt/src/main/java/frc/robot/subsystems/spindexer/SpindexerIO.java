package frc.robot.subsystems.spindexer;

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

public interface SpindexerIO {

  @AutoLog
  public static class SpindexerIOInputs {
    public Temperature spindexerMotorTemp = Celsius.of(0);
    public Voltage spindexerMotorAppliedVoltage = Volts.of(0);
    public Current spindexerMotorCurrent = Amps.of(0);
    public Angle spindexerMotorPosition = Rotations.of(0);
    public AngularVelocity spindexerMotorVelocity = RotationsPerSecond.of(0);
  }

  public default void updateInputs(SpindexerIOInputs inputs) {}

  public default void setVoltage(Voltage volts) {}

  public default void stop() {}

  public default void runSysIdRoutine(Voltage volts) {}
}
