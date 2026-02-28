package frc.robot.subsystems;

import com.ctre.phoenix6.hardware.TalonFX;

import edu.wpi.first.wpilibj.motorcontrol.MotorController;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.utils.RTU.RobotAction;

public class MotorTestSubsystem extends SubsystemBase {

    private final TalonFX motor;

    public MotorTestSubsystem(TalonFX motor) {
        this.motor = motor;
    }

    @RobotAction(name = "Check Motor Connection", description = "Ensure the motor is connected.", order = 1)
    public boolean checkMotorConnection() {
        // Example logic: Check if motor responds to a small voltage
        try {
            motor.set(0.1);
            Thread.sleep(200);
            motor.set(0);
            return true; // Assume motor is connected if no exception
        } catch (Exception e) {
            return false;
        }
    }

    @RobotAction(name = "Run Motor Forward", description = "Run the motor forward at 10% speed.", order = 2)
    public void runMotorForward() {
        motor.set(0.1);
        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        } finally {
            motor.set(0);
        }
    }

    @RobotAction(name = "Run Motor Reverse", description = "Run the motor in reverse at 10% speed.", order = 3)
    public void runMotorReverse() {
        motor.set(-0.1);
        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        } finally {
            motor.set(0);
        }
    }

    @RobotAction(name = "Ramp Motor Speed", description = "Gradually increase motor speed and log diagnostics.", order = 4)
    public void rampMotorSpeed() {
        for (double speed = 0.0; speed <= 0.5; speed += 0.1) {
            motor.set(speed);
            try {
                Thread.sleep(500);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            }
        }
        motor.set(0);
    }
}