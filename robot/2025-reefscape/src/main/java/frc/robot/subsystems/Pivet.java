// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.subsystems;

import com.ctre.phoenix6.hardware.CANcoder;
import com.ctre.phoenix6.hardware.TalonFX;

import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.wpilibj.XboxController;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.SubsystemBase;


public class Pivet extends SubsystemBase {
  /** Creates a new Coralintake. */
  private TalonFX moterTalonFX1 = new TalonFX(13);
  private CANcoder pivetCANcoder = new CANcoder(15);
  private XboxController controller = new XboxController(0); 
  private PIDController pidcontroller = new PIDController(.1, 0, 0)
  private final double speed = 1.5;
 
  public Pivet() {
    if (controller.getYButton()){
      TalonFX.set(pidcontroller.calculate(pivetCANcoder.getAbsolutePosition().getValueAsDouble(), null));
    } 
  }
  
  @Override
  public void periodic() {
    SmartDashboard.putNumber("Pivet CANcoder Value", pivetCANcoder.getAbsolutePosition() );
    // This method will be called once per scheduler run
  }
}
