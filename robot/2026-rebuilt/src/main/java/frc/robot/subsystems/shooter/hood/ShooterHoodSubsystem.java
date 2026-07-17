package frc.robot.subsystems.shooter.hood;

import static edu.wpi.first.units.Units.Rotations;
import java.util.function.DoubleSupplier;
import java.util.logging.Logger;
import org.littletonrobotics.junction.networktables.LoggedNetworkNumber;
import com.ctre.phoenix6.controls.PositionVoltage;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.Current;
import edu.wpi.first.units.measure.Distance;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.RobotMap;
import frc.robot.RobotMap.ShooterConstants;
import frc.robot.subsystems.shooter.hood.ShooterHoodIO.HoodIOInputs;

public class ShooterHoodSubsystem extends SubsystemBase {
  public enum shooterhood_state {
    TEST(Rotations.of(0)), IN(ShooterConstants.minHoodAngle), OUT(
        ShooterConstants.maxHoodAngle), PASSING(
            Rotations.of(0)), SHOOTING(Rotations.of(30)), LAYUP(Rotations.of(8.5)), // 3.278m
                                                                                    // (midway
                                                                                    // between
                                                                                    // hub+tower),
                                                                                    // see
                                                                                    // https://docs.google.com/spreadsheets/d/1dgeEKQ00QiUogEZPXbh4vTJQD8yXOX3HCi0rzDTo5SA
    HALFCOURT(Rotations.of(17.0)), // 5.23m (corner), see doc above
    MANUAL(Rotations.of(0)),
    // Sim states
    AIMING_UP(Rotations.of(0)), AIMING_DOWN(Rotations.of(0));


    private final Angle angleTarget;

    shooterhood_state(Angle angleTarget) {
      this.angleTarget = angleTarget;
    }

    public Angle getAngle() {
      return angleTarget;
    }
  }

  // TODO: add these to swerve logger
  private final DoubleSupplier distanceToHub;
  private final DoubleSupplier distanceToPassingLoc;

  private final ShooterHoodIO io;
  private final HoodIOInputsAutoLogged shooterHoodInputs = new HoodIOInputsAutoLogged();

  shooterhood_state currentState = shooterhood_state.IN;
  private LoggedNetworkNumber hoodManualPositionTrackPos =
      new LoggedNetworkNumber("Hood Manual Position Set", 0.0);

  public ShooterHoodSubsystem(ShooterHoodIO io, DoubleSupplier distanceToHub,
      DoubleSupplier distanceToPassingLoc) {
    this.io = io;
    this.distanceToHub = distanceToHub;
    this.distanceToPassingLoc = distanceToPassingLoc;
  }

  @Override
  public void periodic() {
    io.updateInputs(shooterHoodInputs);
    org.littletonrobotics.junction.Logger.processInputs("Shooter Hood", shooterHoodInputs);

    switch (currentState) {
      case OUT:

        break;

      case IN:
        break;

      case SHOOTING:
        io.setPosition(getTargetPositionShooting().times(shooterHoodInputs.hoodAngleMultiplier));
        break;

      case PASSING:
        io.setPosition(getTargetPositionPassing());
        break;

      case MANUAL:
        break;

      case LAYUP, HALFCOURT:
        break;
      case TEST:
        io.setPosition(Rotations.of(hoodManualPositionTrackPos.get()));
        break;
    }

  }

  public void setState(shooterhood_state state) {
    currentState = state;
    io.setPosition(state.getAngle());
  }

  public void updateHoodAngleMultiplier(double toAdd) {
    io.updateHoodAngleMultiplier(toAdd);
  }

  public shooterhood_state getCurrentState() {
    return currentState;
  }

  public Angle getPosition() {
    return shooterHoodInputs.hoodMotorPosition;
  }

  public Current getCurrentDraw() {
    return shooterHoodInputs.hoodMotorCurrent;
  }

  public static double rotationsToAngleRadians(double rotations) {
    double range = ShooterConstants.HOOD_MAX_ANGLE_DEG - ShooterConstants.HOOD_MIN_ANGLE_DEG;
    double degrees = ShooterConstants.HOOD_MIN_ANGLE_DEG
        + (rotations / ShooterConstants.HOOD_FORWARD_SOFT_LIMIT_ROT) * range;
    return degrees / 180 * Math.PI;
  }

  public double getPositionRadians() {
    return rotationsToAngleRadians(getPosition().in(Rotations));
  }

  public void setAngle(Angle angle) {
    io.setPosition(angle);
  }

  public boolean atSetpointShooting() {
    return RobotMap.ShooterConstants.postionTolerance
        .gte(Rotations.of(getPosition().minus(getTargetPositionShooting()).abs(Rotations))); // not
                                                                                             // for
                                                                                             // passing
                                                                                             // bc
                                                                                             // doesnt
                                                                                             // need
                                                                                             // to
                                                                                             // be
                                                                                             // super
                                                                                             // accurate
  }

  public Command setStateCommand(shooterhood_state state) {
    return runOnce(() -> setState(state));
  }

  public Command setMotorPower(Double power) {
    return runOnce(() -> {
      setState(shooterhood_state.MANUAL);
      io.setDutyCycle(power);
    });
  }

  public Command resetHoodAngle() {
    return runOnce(() -> io.setEncoderAngle(Rotations.of(0)));
  }

  public Angle getTargetPositionShooting() {
    return Rotations
        .of(RobotMap.ShooterConstants.kShootingPositionMap.get(distanceToHub.getAsDouble()));
  }

  public Angle getTargetPositionPassing() {
    return Rotations.of(
        RobotMap.ShooterConstants.kPassingPositionMap.get((distanceToPassingLoc.getAsDouble())));
  }

}
