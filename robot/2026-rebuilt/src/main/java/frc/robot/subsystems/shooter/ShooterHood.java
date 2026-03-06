 // Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.subsystems.shooter;

import static edu.wpi.first.units.Units.Degree;
import static edu.wpi.first.units.Units.Degrees;
import static edu.wpi.first.units.Units.Meters;
import static edu.wpi.first.units.Units.Rotations;

import java.util.Map;
import java.util.function.DoubleSupplier;

import com.ctre.phoenix6.configs.TalonFXConfiguration;
import com.ctre.phoenix6.controls.PositionVoltage;
import com.ctre.phoenix6.hardware.TalonFX;
import com.ctre.phoenix6.mechanisms.swerve.LegacySwerveRequest.Idle;
import com.ctre.phoenix6.signals.InvertedValue;
import com.ctre.phoenix6.signals.NeutralModeValue;

import org.littletonrobotics.junction.Logger;
import edu.wpi.first.epilogue.Logged;
import edu.wpi.first.networktables.GenericEntry;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.Distance;
import edu.wpi.first.wpilibj.shuffleboard.BuiltInWidgets;
import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardTab;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.RobotMap;
import frc.robot.RobotMap.ShooterConstants;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;

@Logged
public class ShooterHood extends SubsystemBase {

    public enum shooterhood_state {
      TEST(Rotations.of(0)),
      IN(ShooterConstants.minHoodAngle),
      OUT(ShooterConstants.maxHoodAngle),
      PASSING(Rotations.of(0)),
      SHOOTING(Rotations.of(30)),
      LAYUP(ShooterConstants.maxHoodAngle),
      HALFCOURT(ShooterConstants.minHoodAngle),
      MANUAL(Rotations.of(0)),
      //Sim states
      AIMING_UP(Rotations.of(0)),
      AIMING_DOWN(Rotations.of(0));
      

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
  private double HoodAngleMultiplier = 1;
  private ShuffleboardTab tab = Shuffleboard.getTab("testing");
    private DoubleSupplier pos = ()->0.0;

  /** Creates a new Shooter. */
  public ShooterHood(CommandSwerveDrivetrain dt) {
    this.dt = dt;
    hoodMotor = new TalonFX(ShooterConstants.ShooterHood);
    positionVoltage = new PositionVoltage(0.0);
    config = new TalonFXConfiguration();
    config.MotorOutput.NeutralMode = NeutralModeValue.Coast;
    config.MotorOutput.Inverted = InvertedValue.Clockwise_Positive;
    config.CurrentLimits.StatorCurrentLimit = 40;
    //Following values would need to be tuned.
    config.Slot0.kS = .189; // Constant applied for friction compensation (static gain)
    config.Slot0.kP = 1; // Proportional gain 
    config.Slot0.kD = 0.0; // Derivative gain
    config.SoftwareLimitSwitch.ForwardSoftLimitThreshold = 28; 
    config.SoftwareLimitSwitch.ReverseSoftLimitThreshold = 0.5; 
    config.SoftwareLimitSwitch.ForwardSoftLimitEnable = true;
    config.SoftwareLimitSwitch.ReverseSoftLimitEnable = true;
    // Apply config multiple times to ensure application
    for (int i = 0; i < 2; ++i){
      var status = hoodMotor.getConfigurator().apply(config);
      if(status.isOK()) break;
    }

     GenericEntry swanNeckPivotSpeedSetter = tab.add("hood pos", 0.0)
                .withWidget(BuiltInWidgets.kNumberSlider)
                .withProperties(Map.of("min", 0, "max", .2))
                .getEntry();
                pos = () -> swanNeckPivotSpeedSetter.getDouble(0);
  }

  @Override
  public void periodic() {
    Logger.recordOutput("Robot/Shooter/Shooter Hood State", currentState.toString());

    switch (currentState) {
      case OUT:
      
        break;
    
      case IN:
        break;

      case SHOOTING:
      hoodMotor.setControl(positionVoltage.withPosition(getTargetPositionShooting().times(HoodAngleMultiplier)));
        break;

      case PASSING:
      hoodMotor.setControl(positionVoltage.withPosition(getTargetPositionPassing()));
        break;

      case MANUAL, AIMING_UP,AIMING_DOWN:
        // Sim-only: hood angle managed by ShooterSim, not the motor
        break;
      
      case LAYUP, HALFCOURT:
        break;
      case TEST:
      setAngle(Rotations.of(pos.getAsDouble()));
      break;
    }
    Logger.recordOutput("Robot/Shooter/HoodAngleRotations", getPosition().in(Rotations));
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
     double d = dt.getState().Pose.getTranslation().getDistance(ShooterConstants.hubCenter);
      return Rotations.of(RobotMap.ShooterConstants.kShootingPositionMap.get(d));
  }

   public Angle getTargetPositionPassing()
  {
     Distance d = dt.getDistanceToCorner();
      return Rotations.of(RobotMap.ShooterConstants.kPassingPositionMap.get(d.in(Meters)));
  }

  public void setSimPosition(double rotations) {
    hoodMotor.getSimState().setRawRotorPosition(rotations);
  }

  /**
   * Update the hood angle multiplier, capped in the range of 0.9 to 1.1.
   * @param toAdd Positive or negative double value to add to the multiplier 
   */
  public void updateHoodAngleMultiplier(double toAdd) {
    if(HoodAngleMultiplier + toAdd > 1.1 || HoodAngleMultiplier + toAdd < 0.9) {
      return;
    } else {
    HoodAngleMultiplier += toAdd;
    Logger.recordOutput("Robot/Shooter/HoodAngleMultiplier", HoodAngleMultiplier);
    }
  }

  public Command setStateCommand(shooterhood_state state) {
    return runOnce(() -> setState(state));
  }

   public Command setMotorPower(Double power){
    setState(shooterhood_state.MANUAL);
    return runOnce(()->  hoodMotor.set(power));
  }

  public Command resetHoodAngle(){
    return runOnce(() -> hoodMotor.setPosition(0));
  }
}
