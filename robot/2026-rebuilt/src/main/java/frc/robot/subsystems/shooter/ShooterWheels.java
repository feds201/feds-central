// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.subsystems.shooter;

import static edu.wpi.first.units.Units.Meters;
import static edu.wpi.first.units.Units.RotationsPerSecond;
import static edu.wpi.first.units.Units.Second;
import static edu.wpi.first.units.Units.Volts;

import com.ctre.phoenix6.SignalLogger;
import com.ctre.phoenix6.configs.TalonFXConfiguration;
import com.ctre.phoenix6.controls.Follower;
import com.ctre.phoenix6.controls.MotionMagicVelocityVoltage;
import com.ctre.phoenix6.controls.VoltageOut;
import com.ctre.phoenix6.hardware.TalonFX;
import com.ctre.phoenix6.signals.InvertedValue;
import com.ctre.phoenix6.signals.MotorAlignmentValue;
import com.ctre.phoenix6.signals.NeutralModeValue;

import org.littletonrobotics.junction.Logger;
import edu.wpi.first.epilogue.Logged;
import edu.wpi.first.units.measure.AngularVelocity;
import edu.wpi.first.units.measure.Distance;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import edu.wpi.first.wpilibj2.command.sysid.SysIdRoutine;
import frc.robot.RobotMap;
import frc.robot.RobotMap.ShooterConstants;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;

@Logged
public class ShooterWheels extends SubsystemBase {

    public enum shooter_state {
    SHOOTING(RotationsPerSecond.of(0)),
    IDLE(RotationsPerSecond.of(0)),
    PASSING(RotationsPerSecond.of(0));

    private final AngularVelocity targetVelocity;

    shooter_state(AngularVelocity targetVelocity) {
      this.targetVelocity = targetVelocity;
    }

    public AngularVelocity getVelocity() {
      return targetVelocity;
    }
  } 


    private final TalonFX shooterLeader;
    private final TalonFX shooterFollower1;
    private final TalonFX shooterFollower2;
    private final TalonFX shooterFollower3;
    private final TalonFXConfiguration config;
    private final MotionMagicVelocityVoltage motionMagicControl;
    private shooter_state currentState = shooter_state.IDLE;
    private final CommandSwerveDrivetrain dt;
    private final SysIdRoutine m_flywheelSysId;
  
  /** Creates a new Shooter. */
  public ShooterWheels(CommandSwerveDrivetrain dt) {
    this.dt = dt;
    shooterLeader = new TalonFX(ShooterConstants.ShooterRightTop);
    shooterFollower1 = new TalonFX(ShooterConstants.ShooterBottomLeft);
    shooterFollower2 = new TalonFX(ShooterConstants.ShooterRightBottom);
    shooterFollower3 = new TalonFX(ShooterConstants.ShooterTopLeft);
    shooterFollower1.setControl(new Follower(shooterLeader.getDeviceID(), MotorAlignmentValue.Opposed));
    shooterFollower2.setControl(new Follower(shooterLeader.getDeviceID(), MotorAlignmentValue.Aligned));
    shooterFollower3.setControl(new Follower(shooterLeader.getDeviceID(), MotorAlignmentValue.Opposed));
    motionMagicControl = new MotionMagicVelocityVoltage(0.0);

    m_flywheelSysId = new SysIdRoutine(
    new SysIdRoutine.Config(
      Volts.of(0.5).per(Second),                // default ramp (or Volts.of(x).per(Second) if you want custom)
      Volts.of(3),          // dynamic step voltage: start with something conservative (4-6 V)
      null,                // default timeout
      state -> SignalLogger.writeString("SysId_Flywheel_State", state.toString()) // log state string
    ),
    new SysIdRoutine.Mechanism(
      // apply voltage request -> set CTRE motor VoltageOut
      voltsMeasure -> {
        // voltsMeasure is a Measure<Voltage>
        double volts = voltsMeasure.in(Volts); // numeric voltage (e.g. 0..12)
        // phoenix6: setControl with VoltageOut (applies volts to motor)
        shooterLeader.setControl(new VoltageOut(volts));
        // if you have follower motors, set them appropriately (use followers or set same request for each)
         SignalLogger.writeDouble("Rotational_Rate", voltsMeasure.in(Volts));
      },
      // logging callback: when using CTRE SignalLogger set this to null (CTRE logs motor signals automatically)
      null,
      this // subsystem for command requirements
    )
  );

    config = new TalonFXConfiguration();
    config.MotorOutput.NeutralMode = NeutralModeValue.Coast;
    config.MotorOutput.Inverted = InvertedValue.CounterClockwise_Positive;
    config.CurrentLimits.StatorCurrentLimit = 40;
    //Following values would need to be tuned.
    config.Slot0.kS = 0.0; // Constant applied for friction compensation (static gain)///;;poy' qwertyhellooooooo
    config.Slot0.kP = 0.0; // Proportional gain 
    config.Slot0.kD = 0.0; // Derivative gain
    config.Slot0.kV = 0.0;// Velocity gain
    config.Slot0.kA = 0.0; // Acceleration gain
    config.MotionMagic.MotionMagicCruiseVelocity = 0.0; // Max allowed velocity (Motor rot / sec)
    config.MotionMagic.MotionMagicAcceleration = 0.0; // Max allowed acceleration (Motor rot / sec^2)
    // Apply config multiple times to ensure application
    for (int i = 0; i < 2; ++i){
      var status = shooterLeader.getConfigurator().apply(config);
      if(status.isOK()) break;
    }
  }

  @Override
  public void periodic() {

    Logger.recordOutput("Robot/Shooter/IsShooting", currentState == shooter_state.SHOOTING);

    switch (currentState) {
      case SHOOTING:
      shooterLeader.setControl(motionMagicControl.withVelocity(getTargetVelocityShooting()));

        break;

      case IDLE:
        break;

      case PASSING:
      shooterLeader.setControl(motionMagicControl.withVelocity(getTargetVelocityPassing())); //from passing table
        break;
    }
  }

  public void setVelocity(AngularVelocity velocity){
    shooterLeader.setControl(motionMagicControl.withVelocity(velocity));
  }

  public void setState(shooter_state state){
    currentState = state;
    setVelocity(state.getVelocity());
  }
  
  public shooter_state getCurrentState(){
    return currentState;
  }

  public AngularVelocity getVelocity(){
    return shooterLeader.getVelocity().getValue();
  }

  public boolean atSetpoint(){
    return RobotMap.ShooterConstants.velocityTolerance.gte(RotationsPerSecond.of(getVelocity().minus(getTargetVelocityShooting()).abs(RotationsPerSecond)));
  } 

  public AngularVelocity getTargetVelocityShooting()
  {
     Distance d = dt.getDistanceToVirtualHub();
      return RotationsPerSecond.of(RobotMap.ShooterConstants.kShootingVelocityMap.get(d.in(Meters)));
  }

  //METHOD DYSFUNCTIONAL: Passing doesnt shoot to hub, find position on field to pass to.
   public AngularVelocity getTargetVelocityPassing()
  {
     Distance d = dt.getDistanceToCorner();
      return RotationsPerSecond.of(RobotMap.ShooterConstants.kPassingVelocityMap.get(d.in(Meters)));
  }

  public Command flywheelSysIdQuasistatic(SysIdRoutine.Direction dir) { return m_flywheelSysId.quasistatic(dir); }
  public Command flywheelSysIdDynamic(SysIdRoutine.Direction dir) { return m_flywheelSysId.dynamic(dir); }

  public Command setStateCommand(shooter_state state) {
    return runOnce(() -> setState(state));
  }
}
