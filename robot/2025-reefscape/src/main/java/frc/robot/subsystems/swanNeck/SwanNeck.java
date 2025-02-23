// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.subsystems.swanNeck;

import java.util.Map;
import java.util.function.DoubleSupplier;

import org.dyn4j.geometry.Rotation;

import com.ctre.phoenix6.hardware.CANcoder;
import com.ctre.phoenix6.hardware.CANrange;
import com.ctre.phoenix6.hardware.TalonFX;

import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.networktables.GenericEntry;
import edu.wpi.first.wpilibj.shuffleboard.BuiltInWidgets;
import edu.wpi.first.wpilibj.shuffleboard.WidgetType;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import frc.robot.constants.RobotMap.CurrentLimiter;
import frc.robot.constants.RobotMap.IntakeMap;
import frc.robot.utils.SubsystemABS;
import frc.robot.utils.Subsystems;
 
public class SwanNeck extends SubsystemABS {
    /** Creates a new gooseNeck. */
    private TalonFX intakeMotor;
    private TalonFX pivotMotor;
    private CANrange coralCanRange;
    private CANrange algaeCanRange;
    // private CANcoder gooseNeckAngler;
    private DoubleSupplier algaeCANrangeVal = ()-> 0.0;
    private DoubleSupplier coralCANrangeVal = ()-> 0.0;
    private DoubleSupplier swanNeckAngleValue = ()-> 0.0;
    public DoubleSupplier m_swanNeckPivotSpeed;
    public DoubleSupplier m_swanNeckWheelSpeed;
    private PIDController pid;
  

    public SwanNeck(Subsystems subsystem, String name) {
        super(subsystem, name);
        intakeMotor = new TalonFX(IntakeMap.SensorCanId.INTAKE_MOTOR);
            intakeMotor.getConfigurator().apply(CurrentLimiter.getCurrentLimitConfiguration(IntakeMap.INTAKE_MOTOR_CURRENT_LIMIT));
        pivotMotor = new TalonFX(IntakeMap.SensorCanId.PIVOT_MOTOR);
            pivotMotor.getConfigurator().apply(CurrentLimiter.getCurrentLimitConfiguration(IntakeMap.PIVOT_MOTOR_CURRENT_LIMIT));
        coralCanRange = new CANrange(IntakeMap.SensorCanId.CORAL_CANRANGE);
        algaeCanRange = new CANrange(IntakeMap.SensorCanId.ALGAE_CANRANGE);
        pid = IntakeMap.intakePid;
    
        // gooseNeckAngler = new CANcoder(IntakeMap.SensorCanId.INTAKE_ENCODER);
        

        pivotMotor.getConfigurator().apply(IntakeMap.getBreakConfigurationGooseNeck());
        algaeCANrangeVal = () -> algaeCanRange.getDistance().getValueAsDouble();
        coralCANrangeVal = () -> coralCanRange.getDistance().getValueAsDouble();
        swanNeckAngleValue = () -> pivotMotor.getPosition().getValueAsDouble();

      
        tab.addNumber("algae CanRange Value", algaeCANrangeVal);
        tab.addNumber("coral CanRange Value", coralCANrangeVal);
        tab.addNumber("gooseNeck Angle", swanNeckAngleValue);
        tab.add("GooseNeck PID", pid).withWidget(BuiltInWidgets.kPIDController);

           GenericEntry swanNeckPivotSpeedSetter = tab.add("Swan Neck Pivot Speed", 0.0)
                .withWidget(BuiltInWidgets.kNumberSlider)
                .withProperties(Map.of("min", 0, "max", .2))
                .getEntry();
                m_swanNeckPivotSpeed = () -> swanNeckPivotSpeedSetter.getDouble(0);

            GenericEntry swanNeckWheelSpeedSetter = tab.add("Swan Neck Wheel Speed", 0.0)
                .withWidget(BuiltInWidgets.kNumberSlider)
                .withProperties(Map.of("min", 0, "max", .2))
                .getEntry();
                m_swanNeckWheelSpeed = () -> swanNeckWheelSpeedSetter.getDouble(0);
    }

    @Override
    public void periodic() {
        algaeCANrangeVal = () -> algaeCanRange.getDistance().getValueAsDouble();
        coralCANrangeVal = () -> coralCanRange.getDistance().getValueAsDouble();
        swanNeckAngleValue = () -> pivotMotor.getPosition().getValueAsDouble();
        SmartDashboard.putNumber("gooseneck pivot value", pivotMotor.getPosition().getValueAsDouble());
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
        pivotMotor.disable();

    }

    public void setPivotSpeed(double speed) {
        pivotMotor.set(speed);
    }

    public void setPIDTarget(double target) {
        pid.setSetpoint(target);
    }

    public boolean pidAtSetpoint() {
        return pid.atSetpoint();
    }

    public void rotateSwanNeckPID() {
        double pidOutput = pid.calculate(getPivotPosition());
        if(pidOutput >= 0){
            pidOutput += IntakeMap.ks;
        } else {
            pidOutput -= IntakeMap.ks;
        }
        double output = pidOutput + (IntakeMap.kg * Math.cos(getPivotPosition() * 2 * Math.PI));
        
        setPivotSpeed(output);
    }

    public void spinSwanWheels(double speed){
        intakeMotor.set(speed);
    }

    public void resetGooseNeckEncoder() {
        pivotMotor.setPosition(.2);
    }



    public double getPivotPosition() {
        return pivotMotor.getPosition().getValueAsDouble();
    }



    public void lockPivot() {
        pivotMotor.getConfigurator().apply(IntakeMap.getBreakConfigurationGooseNeck());
    }

    public void unlockPivot() {
        pivotMotor.getConfigurator().apply(IntakeMap.getCoastConfiguration());
    }

}
