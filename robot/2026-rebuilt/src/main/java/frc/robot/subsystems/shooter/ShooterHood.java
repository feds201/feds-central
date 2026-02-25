// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.subsystems.shooter;

import static edu.wpi.first.units.Units.Meters;
import static edu.wpi.first.units.Units.Rotations;

import com.ctre.phoenix6.configs.TalonFXConfiguration;
import com.ctre.phoenix6.controls.PositionVoltage;
import com.ctre.phoenix6.hardware.TalonFX;
import com.ctre.phoenix6.signals.InvertedValue;
import com.ctre.phoenix6.signals.NeutralModeValue;

import edu.wpi.first.epilogue.Logged;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.Distance;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.RobotMap;
import frc.robot.RobotMap.ShooterConstants;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;

@Logged
public class ShooterHood extends SubsystemBase {

    public enum shooterhood_state {
    IN(ShooterConstants.minHoodAngle),
    OUT(ShooterConstants.maxHoodAngle),
    PASSING(Rotations.of(0)),
    SHOOTING(Rotations.of(0));

    private final Angle angleTarget;

    shooterhood_state(Angle angleTarget) {
      this.angleTarget = angleTarget;
    }

    public Angle getAngle() {
      return angleTarget;
    }
  }


  private final TalonFX hoodMotor;
  private final TalonFXConfiguration config;
  private final PositionVoltage positionVoltage;
  private shooterhood_state currentState = shooterhood_state.IN;
  private final CommandSwerveDrivetrain dt;

  /** Creates a new Shooter. */
  public ShooterHood(CommandSwerveDrivetrain dt) {
    this.dt = dt;
    hoodMotor = new TalonFX(ShooterConstants.ShooterHood);
    positionVoltage = new PositionVoltage(0.0);
    config = new TalonFXConfiguration();
    config.MotorOutput.NeutralMode = NeutralModeValue.Brake;
    config.MotorOutput.Inverted = InvertedValue.CounterClockwise_Positive;
    config.CurrentLimits.StatorCurrentLimit = 20;
    //Following values would need to be tuned.
    config.Slot0.kS = 0.0; // Constant applied for friction compensation (static gain)
    config.Slot0.kP = 0.0; // Proportional gain 
    config.Slot0.kD = 0.0; // Derivative gain
    // Apply config multiple times to ensure application
    for (int i = 0; i < 2; ++i){
      var status = hoodMotor.getConfigurator().apply(config);
      if(status.isOK()) break;
    }
  }

  @Override
  public void periodic() {

    switch (currentState) {
      case OUT:
      
        break;
    
      case IN:
        break;

      case SHOOTING:
      hoodMotor.setControl(positionVoltage.withPosition(getTargetPositionShooting())); //from passing table
        break;

      case PASSING:
      hoodMotor.setControl(positionVoltage.withPosition(getTargetPositionPassing()));
        break;
    }
    // This method will be called once per scheduler run
  }

  public void setAngle(Angle targetAngle){
    hoodMotor.setControl(positionVoltage.withPosition(targetAngle));
  }

  public void setState(shooterhood_state state){
    currentState = state;
    setAngle(state.getAngle());
  }
  
  public shooterhood_state getCurrentState(){
    return currentState;
  }

  public Angle getPosition(){
    return hoodMotor.getPosition().getValue();
  }

  public boolean atSetpointShooting(){
    return RobotMap.ShooterConstants.postionTolerance.gte(Rotations.of(getPosition().minus(getTargetPositionShooting()).abs(Rotations))); //not for passing bc doesnt need to be super accurate
  } 

  public Angle getTargetPositionShooting()
  {
     Distance d = dt.getDistanceToVirtualHub();
      return Rotations.of(RobotMap.ShooterConstants.kShootingPositionMap.get(d.in(Meters)));
  }

   public Angle getTargetPositionPassing()
  {
     Distance d = dt.getDistanceToCorner();
      return Rotations.of(RobotMap.ShooterConstants.kPassingPositionMap.get(d.in(Meters)));
  }

  public Command setStateCommand(shooterhood_state state) {
    return runOnce(() -> setState(state));
  } 
}
