package frc.robot.subsystems.sampleSubsystem;

import static edu.wpi.first.units.Units.Degrees;
import static edu.wpi.first.units.Units.Rotations;

import com.ctre.phoenix6.configs.TalonFXConfiguration;
import com.ctre.phoenix6.controls.MotionMagicVoltage;
import com.ctre.phoenix6.hardware.TalonFX;
import com.ctre.phoenix6.signals.GravityTypeValue;
import com.ctre.phoenix6.signals.InvertedValue;
import com.ctre.phoenix6.signals.NeutralModeValue;

import edu.wpi.first.math.geometry.Pose3d;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.utils.DeviceTempReporter;
import frc.robot.utils.LimelightWrapper;
import frc.robot.utils.SubsystemStatusManager;
import limelight.networktables.LimelightSettings.LEDMode;

public class SampleSubsystem extends SubsystemBase {

  private final TalonFX sampleMotor;
  private final LimelightWrapper sampleLimelight;
  private TalonFXConfiguration config;
  private turret_state currentState;

  /*
    States : SPIN, STOP, TARGET
    get tx from limleight
    use CTRE's PID network and 
    
  
  */
  public enum turret_state {
    STOP(Rotations.of(0)),
    START(Rotations.of(0)),
    ALIGN(Rotations.of(0)),
    HOME(Rotations.of(0));

    private final Angle targetPosition;
    private final Angle tolerance;

    turret_state(Angle targetPosition){
      this.targetPosition = targetPosition;
      this.tolerance = Degrees.of(3);

    }

    public Angle getTargetPosition(){
      return targetPosition;
    }

    public Angle getTolerance(){
      return tolerance;
    }
  }

  private final MotionMagicVoltage positionOut = new MotionMagicVoltage(Rotations.of(0));
  
  public SampleSubsystem() {
    currentState = turret_state.HOME;
    sampleMotor = new TalonFX(1);
    sampleLimelight = new LimelightWrapper("limelight", true);
    sampleLimelight.getSettings()
         .withLimelightLEDMode(LEDMode.PipelineControl)
         .withCameraOffset(Pose3d.kZero)
         .save();
    
    config = new TalonFXConfiguration();
    config.MotorOutput.NeutralMode = NeutralModeValue.Brake;
    config.MotorOutput.Inverted = InvertedValue.CounterClockwise_Positive;
    config.CurrentLimits.StatorCurrentLimit = 40;
    config.Slot0.GravityType = GravityTypeValue.Elevator_Static;
    //Following values would need to be tuned.
    config.Slot0.kG = 0.0; // Constant applied for gravity compensation
    config.Slot0.kS = 0.0; // Constant applied for friction compensation (static gain)
    config.Slot0.kP = 0.0; // Proportional gain 
    config.Slot0.kD = 0.0; // Derivative gain
    config.MotionMagic.MotionMagicCruiseVelocity = 0.0; // Max allowed velocity (Motor rot / sec)
    config.MotionMagic.MotionMagicAcceleration = 0.0; // Max allowed acceleration (Motor rot / sec^2)
    // Apply config multiple times to ensure application
    for (int i = 0; i < 2; ++i){
      var status = sampleMotor.getConfigurator().apply(config);
      if(status.isOK()) break;
    }

    SubsystemStatusManager.addSubsystem(getName(), sampleMotor);
    DeviceTempReporter.addDevices(sampleMotor);
  }

  @Override
  public void periodic() {
    // This method will be called once per scheduler run
    super.periodic();
  }

  public void setPosition(Angle position){
    sampleMotor.setControl(positionOut.withPosition(position));
  }

  public void setState(turret_state state){
    currentState = state;
    setPosition(state.getTargetPosition());
  }

  public Angle getPosition(){
    return sampleMotor.getPosition().getValue();
  }

  public Angle getTargetPosition(){
    return currentState.getTargetPosition();
  }

  public Angle getTolerance(){
    return currentState.getTolerance();
  }

  public void stop(){
    sampleMotor.stopMotor();
  }

  public turret_state getCurrentState(){
    return currentState;
  }

  public boolean isAtTarget(){
    return getPosition().isNear(getTargetPosition(), getTolerance());
  }

  public Command setStateCommand(turret_state targetState){
      return new InstantCommand(() -> {
        setState(targetState);
      });
  }

  




}
