package frc.robot.subsystems.intake;

import static edu.wpi.first.units.Units.Amps;
import static edu.wpi.first.units.Units.Celsius;
import static edu.wpi.first.units.Units.Rotations;
import static edu.wpi.first.units.Units.RotationsPerSecond;
import static edu.wpi.first.units.Units.Volts;
import org.littletonrobotics.junction.AutoLog;
import com.ctre.phoenix6.hardware.TalonFX;
import com.fasterxml.jackson.databind.ser.std.StdKeySerializers.Default;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.AngularVelocity;
import edu.wpi.first.units.measure.Current;
import edu.wpi.first.units.measure.Temperature;
import edu.wpi.first.units.measure.Voltage;
import edu.wpi.first.wpilibj.DigitalInput;

public interface RackIO {

  @AutoLog
  public static class RackIOInputs {
    public Temperature rackMotorTemp = Celsius.of(0);
    public Voltage rackMotorAppliedVoltage = Volts.of(0);
    public Current rackMotorCurrent = Amps.of(0);
    public Angle rackMotorPosition = Rotations.of(0);
    public AngularVelocity rackMotorVelocity = RotationsPerSecond.of(0);
    public boolean rackLimitSwitch = false;
    public boolean hasMotorBeenPosResetThisCycle = false; // Track if we've reset the motor position
                                                          // during this command cycle
  }

  public default void updateInputs(RackIOInputs inputs) {}

  public default void setPosition(Angle position) {}

  public default void zeroEncoder(Angle position) {}

  public default void stop() {}

  public default void set(double percent) {}

  public default void limitSwitchExtensionControl() {}

  public default void runSysIdRoutine(Voltage volts) {}

  public default TalonFX getIntakeMotor() {
    return null;
  }

  public default DigitalInput getLimitSwitch() {
    return null;
  }
}
