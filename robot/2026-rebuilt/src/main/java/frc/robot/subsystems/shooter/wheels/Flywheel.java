package frc.robot.subsystems.shooter.wheels;

import static edu.wpi.first.units.Units.RotationsPerSecond;
import static edu.wpi.first.units.Units.Second;
import static edu.wpi.first.units.Units.Seconds;
import static edu.wpi.first.units.Units.Volts;
import java.util.function.DoubleSupplier;
import org.littletonrobotics.junction.Logger;
import org.littletonrobotics.junction.networktables.LoggedNetworkNumber;
import com.ctre.phoenix6.SignalLogger;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.AngularVelocity;
import edu.wpi.first.units.measure.Current;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import edu.wpi.first.wpilibj2.command.sysid.SysIdRoutine;
import frc.robot.RobotMap;

public class Flywheel extends SubsystemBase {

  public enum shooter_state {
    TEST(RotationsPerSecond.of(9.0)), SHOOTING(RotationsPerSecond.of(0)), IDLE(
        RotationsPerSecond.of(0)), PASSING(
            RotationsPerSecond.of(0)), LAYUP(RotationsPerSecond.of(34.47)), // ~3.278m (midway
                                                                            // between hub+tower),
                                                                            // see
                                                                            // https://docs.google.com/spreadsheets/d/1dgeEKQ00QiUogEZPXbh4vTJQD8yXOX3HCi0rzDTo5SA
    HALFCOURT(RotationsPerSecond.of(40.86)); // ~5.23m (corner), see doc above

    private final AngularVelocity targetVelocity;

    shooter_state(AngularVelocity targetVelocity) {
      this.targetVelocity = targetVelocity;
    }

    public AngularVelocity getVelocity() {
      return targetVelocity;
    }
  }

  // TODO: add these to swerve logger
  private final DoubleSupplier distanceToHub;
  private final DoubleSupplier distanceToPassingLoc;

  private final FlywheelIO io;
  private final FlywheelIOInputsAutoLogged flywheelIOInputs = new FlywheelIOInputsAutoLogged();

  private shooter_state currentState = shooter_state.IDLE;
  private final SysIdRoutine m_flywheelSysId;
  private LoggedNetworkNumber flywheelManualVelocitySetter =
      new LoggedNetworkNumber("Flywheel Manual Velocity Set", 0.0);

  public Flywheel(FlywheelIO io, DoubleSupplier distanceToHub,
      DoubleSupplier distanceToPassingLoc) {
    this.distanceToHub = distanceToHub;
    this.distanceToPassingLoc = distanceToPassingLoc;
    this.io = io;

    m_flywheelSysId = new SysIdRoutine(new SysIdRoutine.Config(Volts.of(0.5).per(Second), // default
                                                                                          // ramp
                                                                                          // (or
                                                                                          // Volts.of(x).per(Second)
                                                                                          // if you
                                                                                          // want
                                                                                          // custom)
        Volts.of(3), // dynamic step voltage: start with something conservative (4-6 V)
        Seconds.of(5), // default timeout
        state -> SignalLogger.writeString("SysId_Flywheel_State", state.toString()) // log state
                                                                                    // string
    ), new SysIdRoutine.Mechanism(
        // apply voltage request -> set CTRE motor VoltageOut
        voltsMeasure -> {
          // phoenix6: setControl with VoltageOut (applies volts to motor)
          io.runSysidRoutine(voltsMeasure);
          // if you have follower motors, set them appropriately (use followers or set same request
          // for each)
          SignalLogger.writeDouble("Rotational_Rate", voltsMeasure.in(Volts));
        },
        // logging callback: when using CTRE SignalLogger set this to null (CTRE logs motor signals
        // automatically)
        null, this // subsystem for command requirements
    ));
  }

  @Override
  public void periodic() {
    Logger.recordOutput("Robot/Shooter/IsShooting", currentState != shooter_state.IDLE);
    Logger.recordOutput("Robot/Shooter/ShooterState", currentState.toString());

    Logger.recordOutput("Robot/ShooterWheels/TargetVelocityRPS",
        currentState.getVelocity().in(RotationsPerSecond));
    switch (currentState) {
      case SHOOTING:
        io.setVelocity(getTargetVelocityShooting());
        Logger.recordOutput("Robot/Shooter/ExpectedVelocity",
            getTargetVelocityShooting().in(RotationsPerSecond));
        break;
      case IDLE:
        break;
      case PASSING:
        io.setVelocity(getTargetVelocityPassing()); // from
                                                    // passing
                                                    // table
        break;
      case LAYUP, HALFCOURT:
        break;
      case TEST:
        io.setVelocity(RotationsPerSecond.of(flywheelManualVelocitySetter.get()));
        break;
    }
  }

  public void setState(shooter_state state) {
    currentState = state;
    if (state.equals(shooter_state.IDLE)) {
      io.setCoast();
      return;
    }
    io.setVelocity(state.getVelocity());
  }

  public void setVelocity(AngularVelocity velocity) {
    io.setVelocity(velocity);
  }

  public shooter_state getCurrentState() {
    return currentState;
  }

  public AngularVelocity getVelocity() {
    return flywheelIOInputs.flywheelMotorVelocity;
  }

  public Current getCurrent() {
    return flywheelIOInputs.flywheelMotorCurrent;
  }

  public Angle getPosition() {
    return flywheelIOInputs.flywheelMotorPosition;
  }

  public boolean atSetpoint() {
    return RobotMap.ShooterConstants.velocityTolerance.gte(RotationsPerSecond
        .of(getVelocity().minus(getTargetVelocityShooting()).abs(RotationsPerSecond)));
  }

  public AngularVelocity getTargetVelocityShooting() {
    return RotationsPerSecond
        .of(RobotMap.ShooterConstants.kShootingVelocityMap.get(distanceToHub.getAsDouble()));
  }

  // METHOD DYSFUNCTIONAL: Passing doesnt shoot to hub, find position on field to pass to.
  public AngularVelocity getTargetVelocityPassing() {
    return RotationsPerSecond
        .of(RobotMap.ShooterConstants.kPassingVelocityMap.get(distanceToPassingLoc.getAsDouble()));
  }

  public Command flywheelSysIdQuasistatic(SysIdRoutine.Direction dir) {
    return m_flywheelSysId.quasistatic(dir);
  }

  public Command flywheelSysIdDynamic(SysIdRoutine.Direction dir) {
    return m_flywheelSysId.dynamic(dir);
  }

  public Command setStateCommand(shooter_state state) {
    return runOnce(() -> setState(state));
  }
}
