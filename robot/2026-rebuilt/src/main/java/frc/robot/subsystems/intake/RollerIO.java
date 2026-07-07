package frc.robot.subsystems.intake;

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

public interface RollerIO {

  @AutoLog
  public static class RollerIOInputs {
    public Temperature rollerMotorTemp = Celsius.of(0);
    public Voltage rollerMotorAppliedVoltage = Volts.of(0);
    public Current rollerMotorCurrent = Amps.of(0);
    public Angle rollerMotorPosition = Rotations.of(0);
    public AngularVelocity rollerMotorVelocity = RotationsPerSecond.of(0);
  }

  public default void updateInputs(RollerIOInputs inputs) {}

  public default void set(double percent) {}

  public default void stop() {}

  public default void runSysIdRoutine(Voltage volts) {}

  public default TalonFX getRollerMotorLeader() {
    return null;
  }

  public default TalonFX getRollerMotorFollower() {
    return null;
  }
}
