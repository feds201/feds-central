// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.subsystems.intake;

import com.ctre.phoenix6.hardware.CANcoder;
import com.ctre.phoenix6.hardware.TalonFX;

import edu.wpi.first.wpilibj2.command.SubsystemBase;

public class intake extends SubsystemBase {
  /** Creates a new intake. */
  private TalonFX moterTalonFX1 = new TalonFX(13);
  private CANcoder CANcoder = new CANcoder(15);
  
  public intake() {}
  
  @Override
  public void periodic() {
    // This method will be called once per scheduler run
  }
}
