// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.subsystems.shooter;

import static edu.wpi.first.units.Units.RotationsPerSecond;

import com.ctre.phoenix6.configs.TalonFXConfiguration;
import com.ctre.phoenix6.controls.Follower;
import com.ctre.phoenix6.controls.MotionMagicVelocityVoltage;
import com.ctre.phoenix6.hardware.TalonFX;
import com.ctre.phoenix6.signals.InvertedValue;
import com.ctre.phoenix6.signals.MotorAlignmentValue;
import com.ctre.phoenix6.signals.NeutralModeValue;

import edu.wpi.first.units.measure.AngularVelocity;
import edu.wpi.first.wpilibj2.command.SubsystemBase;

public class Shooter extends SubsystemBase {

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
  




  /** Creates a new Shooter. */
  public Shooter() {
    shooterLeader = new TalonFX(0);
    shooterFollower1 = new TalonFX(1);
    shooterFollower2 = new TalonFX(2);
    shooterFollower3 = new TalonFX(3);
    shooterFollower1.setControl(new Follower(0, MotorAlignmentValue.Aligned));
    shooterFollower2.setControl(new Follower(0, MotorAlignmentValue.Aligned));
    shooterFollower3.setControl(new Follower(0, MotorAlignmentValue.Aligned));
    motionMagicControl = new MotionMagicVelocityVoltage(0.0);
    config = new TalonFXConfiguration();
    config.MotorOutput.NeutralMode = NeutralModeValue.Coast;
    config.MotorOutput.Inverted = InvertedValue.CounterClockwise_Positive;
    config.CurrentLimits.StatorCurrentLimit = 40;
    //Following values would need to be tuned.
    config.Slot0.kS = 0.0; // Constant applied for friction compensation (static gain)
    config.Slot0.kP = 0.0; // Proportional gain 
    config.Slot0.kD = 0.0; // Derivative gain
    config.Slot0.kV =0.0;// Velocity gain
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

    switch (currentState) {
      case SHOOTING:
        
        break;
    
      case IDLE:
        break;

      case PASSING:
        break;
    }
    // This method will be called once per scheduler run
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

}
