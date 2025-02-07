// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.subsystems.gooseNeck;


import java.util.function.DoubleSupplier;

import com.ctre.phoenix6.hardware.CANrange;
import com.ctre.phoenix6.hardware.TalonFX;

import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.constants.RobotMap;
import frc.robot.utils.SubsystemABS;

public class gooseNeck extends SubsystemABS {
  /** Creates a new gooseNeck. */
private TalonFX intakeMotor;
private TalonFX pivotMotor;
private CANrange coralCanRange;
private CANrange algaeCanRange;
private DoubleSupplier coralCanRangeVal;
private DoubleSupplier algaeCanRangeVal;
  public gooseNeck() {
    intakeMotor = new TalonFX(RobotMap.IntakeMap.SensorConstants.INTAKE_MOTOR);
    pivotMotor = new TalonFX(RobotMap.IntakeMap.SensorConstants.PIVOT_MOTOR);
    coralCanRange = new CANrange(RobotMap.IntakeMap.SensorConstants.CORAL_CANRANGE);
    algaeCanRange = new CANrange(RobotMap.IntakeMap.SensorConstants.ALGAE_CANRANGE);

  }

  @Override
  public void periodic() {
    // This method will be called once per scheduler run
    SmartDashboard.putNumber(getName(), 0);
  }

@Override
public void init() {
   tab.addDouble("coralCanRangeVal", coralCanRangeVal);
   tab.addDouble("algaecanRangeVal", algaeCanRangeVal);
}

@Override
public void simulationPeriodic() {
    // TODO Auto-generated method stub
    throw new UnsupportedOperationException("Unimplemented method 'simulationPeriodic'");
}

@Override
public void setDefaultCmd() {
    // TODO Auto-generated method stub
    throw new UnsupportedOperationException("Unimplemented method 'setDefaultCmd'");
}

@Override
public boolean isHealthy() {
    // TODO Auto-generated method stub
    throw new UnsupportedOperationException("Unimplemented method 'isHealthy'");
}

@Override
public void Failsafe() {
    // TODO Auto-generated method stub
    throw new UnsupportedOperationException("Unimplemented method 'Failsafe'");
}
}
