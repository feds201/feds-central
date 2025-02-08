// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.subsystems.gooseNeck;

import java.util.function.DoubleSupplier;

import com.ctre.phoenix6.hardware.CANcoder;
import com.ctre.phoenix6.hardware.CANrange;
import com.ctre.phoenix6.hardware.TalonFX;

import frc.robot.constants.RobotMap.IntakeMap;
import frc.robot.utils.SubsystemABS;
import frc.robot.utils.Subsystems;

public class GooseNeck extends SubsystemABS {
    /** Creates a new gooseNeck. */
    private TalonFX intakeMotor;
    private TalonFX pivotMotor;
    private CANrange coralCanRange;
    private CANrange algaeCanRange;
    private CANcoder gooseNeckAngler;
    private DoubleSupplier algaeCANrangeVal;
    private DoubleSupplier coralCANrangeVal;
    private DoubleSupplier gooseNeckCANCoderValue;

    public GooseNeck(Subsystems subsystem, String name) {
        super(subsystem, name);
        intakeMotor = new TalonFX(IntakeMap.SensorConstants.INTAKE_MOTOR);
        pivotMotor = new TalonFX(IntakeMap.SensorConstants.PIVOT_MOTOR);
        coralCanRange = new CANrange(IntakeMap.SensorConstants.CORAL_CANRANGE);
        algaeCanRange = new CANrange(IntakeMap.SensorConstants.ALGAE_CANRANGE);
        gooseNeckAngler = new CANcoder(IntakeMap.SensorConstants.INTAKE_ENCODER);
        lockPivot();
        algaeCANrangeVal = () -> algaeCanRange.getDistance().getValueAsDouble();
        coralCANrangeVal = () -> coralCanRange.getDistance().getValueAsDouble();
        gooseNeckCANCoderValue = () -> gooseNeckAngler.getPosition().getValueAsDouble();
        tab.addNumber("algaeCanRange", algaeCANrangeVal);
        tab.addNumber("coralCanRange", coralCANrangeVal);
        tab.addNumber("gooseNeckAngler", gooseNeckCANCoderValue);
    }

    @Override
    public void periodic() {

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

    public void runPivotMotor(double speed) {
        pivotMotor.set(speed);
    }

    public double getPivotAngle() {
        return gooseNeckCANCoderValue.getAsDouble();
    }

    private void lockPivot() {
        pivotMotor.getConfigurator().apply(IntakeMap.getBreakConfiguration());
    }

    public void unlockPivot() {
        pivotMotor.getConfigurator().apply(IntakeMap.getCoastConfiguration());
    }

}
