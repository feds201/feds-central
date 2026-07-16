package frc.robot.subsystems.shooter.hood;

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

public interface ShooterHoodIO {

  @AutoLog
  public static class RackIOInputs {
    public Temperature rackMotorTemp = Celsius.of(0);
    public Voltage rackMotorAppliedVoltage = Volts.of(0);
    public Current rackMotorCurrent = Amps.of(0);
    public Angle rackMotorPosition = Rotations.of(0);
    public AngularVelocity rackMotorVelocity = RotationsPerSecond.of(0);
    public double HoodAngleMultiplier = 1;
  }
}
