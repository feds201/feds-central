package frc.robot.utils.RTU;

import edu.wpi.first.units.measure.AngularVelocity;

import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.Distance;

/**
 * Lightweight thread-safe holder for a few live telemetry values that the
 * diagnostic dashboard can poll. Robot code should call
 * TelemetryPublisher.publish(...) periodically (robotPeriodic) to keep
 * values fresh.
 */
public final class TelemetryPublisher {
  private static double shooterVelocityRps = 0.0;
  private static double hoodAngleDeg = 0.0;
  private static double distanceToHubM = 0.0;

  private TelemetryPublisher() {}

  public static synchronized void publish(AngularVelocity shooterVelocity, Angle hoodAngle, Distance distanceToHub) {
    shooterVelocityRps = shooterVelocity == null ? 0.0 : shooterVelocity.in(edu.wpi.first.units.Units.RotationsPerSecond);
    hoodAngleDeg = hoodAngle == null ? 0.0 : hoodAngle.in(edu.wpi.first.units.Units.Degrees);
    distanceToHubM = distanceToHub == null ? 0.0 : distanceToHub.in(edu.wpi.first.units.Units.Meters);
  }

  public static synchronized double getShooterVelocityRps() { return shooterVelocityRps; }
  public static synchronized double getHoodAngleDeg() { return hoodAngleDeg; }
  public static synchronized double getDistanceToHubM() { return distanceToHubM; }
}
