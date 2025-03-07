// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.subsystems.swanNeck;

import java.util.Map;
import java.util.function.DoubleSupplier;

import com.ctre.phoenix6.hardware.TalonFX;

import edu.wpi.first.networktables.GenericEntry;
import edu.wpi.first.wpilibj.shuffleboard.BuiltInWidgets;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.constants.RobotMap.CurrentLimiter;
import frc.robot.constants.RobotMap.IntakeMap;
import frc.robot.utils.SubsystemABS;
import frc.robot.utils.Subsystems;

public class SwanNeckWheels extends SubsystemABS {
   public DoubleSupplier m_swanNeckWheelSpeed;
   private TalonFX intakeMotor;
  /** Creates a new SwanNeckWheels. */
  public SwanNeckWheels(Subsystems subsystem, String name) {
        super(subsystem, name);
     intakeMotor = new TalonFX(IntakeMap.SensorCanId.INTAKE_MOTOR);
            intakeMotor.getConfigurator().apply(CurrentLimiter.getCurrentLimitConfiguration(IntakeMap.INTAKE_MOTOR_CURRENT_LIMIT));

     GenericEntry swanNeckWheelSpeedSetter = tab.add("Swan Neck Wheel Speed", 0.0)
                .withWidget(BuiltInWidgets.kNumberSlider)
                .withProperties(Map.of("min", 0, "max", .2))
                .getEntry();
                m_swanNeckWheelSpeed = () -> swanNeckWheelSpeedSetter.getDouble(0);
  }

  @Override
  public void periodic() {
    // This method will be called once per scheduler run
  }

  @Override
  public void simulationPeriodic() {
   }

  @Override
  public void setDefaultCmd() {
   }

  @Override
  public boolean isHealthy() {
    return true;
 }

  @Override
  public void Failsafe() {
    intakeMotor.disable();
  }

  public void spinSwanWheels(double speed){
    intakeMotor.set(speed);
}

}
