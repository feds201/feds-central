package frc.robot.subsystems.testing;

import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.subsystems.shooter.ShooterWheels;
import frc.robot.subsystems.spindexer.Spindexer;
import frc.robot.subsystems.feeder.Feeder;
import frc.robot.subsystems.feeder.Feeder.feeder_state;
import frc.robot.subsystems.shooter.ShooterWheels.shooter_state;
import frc.robot.subsystems.spindexer.Spindexer.spindexer_state;
import frc.robot.utils.RTU.DiagnosticContext;
import frc.robot.utils.RTU.RobotAction;

import static edu.wpi.first.units.Units.RotationsPerSecond;

/**
 * RTU test subsystem that runs the shooter wheels and spindexer and records
 * velocity, acceleration and estimated voltage over a 10 second run.
 */
public class ShooterTestSubsystem extends SubsystemBase {


  private final ShooterWheels shooterWheels;
  private final Spindexer spindexer;
  private final Feeder feeder;

  public ShooterTestSubsystem(ShooterWheels shooterWheels, Spindexer spindexer, Feeder feeder) {
    this.shooterWheels = shooterWheels;
    this.spindexer = spindexer;
    this.feeder = feeder;
  }

  @RobotAction(
    name = "Shooter Profile Test",
    description = "Runs shooter wheels + spindexer for 10s and records velocity, acceleration, and estimated voltage",
    order = 1,
    timeoutSeconds = 10.0
  )
  public boolean shooterProfileTest(DiagnosticContext ctx) {

    ctx.info("Starting shooter profile test (10s)");

    // simple controller constants mirrored from ShooterWheels configuration
    final double kS = 0.34; // static friction volts
    final double kV = 0.12; // volts per rps (approx)

  // Run shooter at shooting velocity and start indexer + feeder (kicker)
  shooterWheels.setState(shooter_state.SHOOTING);
  spindexer.setState(spindexer_state.RUN);
  feeder.setState(feeder_state.RUN);

    double lastVelocity = shooterWheels.getVelocity().in(RotationsPerSecond);
    long startMs = System.currentTimeMillis();
    long nowMs = startMs;

    // sample at ~50 Hz
    final long sampleMs = 20;

    while (nowMs - startMs < 10_000) {
      try {
        Thread.sleep(sampleMs);
      } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
        break;
      }

      double velocity = shooterWheels.getVelocity().in(RotationsPerSecond);
      double dt = (double) (sampleMs) / 1000.0;
      double accel = (velocity - lastVelocity) / dt;
      lastVelocity = velocity;

      double estVoltage = kS + kV * velocity;

      ctx.sample("Shooter Velocity (rps)", velocity);
      ctx.sample("Shooter Acceleration (rps/s)", accel);
      ctx.sample("Estimated Commanded Voltage (V)", estVoltage);

      nowMs = System.currentTimeMillis();
    }

  // stop mechanisms
  feeder.setState(feeder_state.STOP);
  spindexer.setState(spindexer_state.STOP);
  shooterWheels.setState(shooter_state.IDLE);

    ctx.info("Shooter profile test complete");
    return true;
  }
}
