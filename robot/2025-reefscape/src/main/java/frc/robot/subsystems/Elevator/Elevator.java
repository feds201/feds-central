package frc.robot.subsystems.elevator;

import com.ctre.phoenix6.controls.Follower;
import com.ctre.phoenix6.hardware.CANrange;
import com.ctre.phoenix6.hardware.TalonFX;
import frc.robot.constants.RobotMap;
import frc.robot.constants.RobotMap.ElevatorMap;
import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardTab;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.utils.SubsystemABS;

public class Elevator extends SubsystemABS {
    private final TalonFX elevatorMotorLeader; // Primary motor
    private final TalonFX elevatorMotorFollower; // Follower motor
    // private final CANrange measure; // Range sensor
    private final ShuffleboardTab tab = Shuffleboard.getTab("CANrange Status");

    public Elevator() {
        elevatorMotorLeader = new TalonFX(RobotMap.ElevatorMap.ELEVATOR_MOTOR);
        elevatorMotorFollower = new TalonFX(RobotMap.ElevatorMap.ELEVATOR_MOTOR2);
        // measure = new CANrange(17);
        // Configure follower motor
        elevatorMotorFollower.setControl(new Follower(elevatorMotorLeader.getDeviceID(), false));
        
        // Add Shuffleboard widget for the range sensor
        // tab.add("Elevator Position", getRangePosition());
    }

    public void setMotorSpeed(double speed) {
        elevatorMotorLeader.set(speed); // Set the speed of the primary motor
    }

    // public double getRangePosition() {
    //     return measure.getDistance().getValueAsDouble(); // Get the range position
    // }

    @Override
    public void periodic() {
        // Update Shuffleboard with the latest range position
        // tab.add("Elevator Position", getRangePosition());
    }

    @Override
    public void init() {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("Unimplemented method 'init'");
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
