package frc.robot.subsystems.shooter.hood;

import static edu.wpi.first.units.Units.Amps;
import static edu.wpi.first.units.Units.Celsius;
import static edu.wpi.first.units.Units.Rotations;
import static edu.wpi.first.units.Units.RotationsPerSecond;
import static edu.wpi.first.units.Units.Volts;
import org.littletonrobotics.junction.AutoLog;
import org.littletonrobotics.junction.networktables.LoggedNetworkNumber;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.AngularVelocity;
import edu.wpi.first.units.measure.Current;
import edu.wpi.first.units.measure.Temperature;
import edu.wpi.first.units.measure.Voltage;

public interface ShooterHoodIO {

  @AutoLog
  public static class HoodIOInputs {
    public Temperature hoodmotorTemp = Celsius.of(0);
    public Voltage hoodMotorAppliedVoltage = Volts.of(0);
    public Current hoodMotorCurrent = Amps.of(0);
    public Angle hoodMotorPosition = Rotations.of(0);
    public AngularVelocity hoodMotorVelocity = RotationsPerSecond.of(0);
    public double hoodAngleMultiplier = 1;
  }

  public default void updateInputs(HoodIOInputs inputs) {}

  public default void setPosition(Angle position) {}

  public default void setDutyCycle(double percent) {}

  public default void stop() {}

  public default void setEncoderAngle(Angle position) {}

  /**
   * Update the hood angle multiplier, capped in the range of 0.9 to 1.1.
   *
   * @param toAdd Positive or negative double value to add to the multiplier
   */
  public default void updateHoodAngleMultiplier(double toAdd) {}
}
