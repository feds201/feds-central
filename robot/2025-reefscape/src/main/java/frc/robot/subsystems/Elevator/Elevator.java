package frc.robot.subsystems.elevator;

import java.util.function.DoubleSupplier;

import com.ctre.phoenix6.controls.Follower;
import com.ctre.phoenix6.hardware.CANcoder;
import com.ctre.phoenix6.hardware.TalonFX;
import frc.robot.constants.RobotMap;
import frc.robot.constants.RobotMap.ElevatorMap;
import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import frc.robot.utils.SubsystemABS;
import frc.robot.utils.Subsystems;

public class Elevator extends SubsystemABS {
    private TalonFX elevatorMotorLeader; // Primary motor
    private TalonFX elevatorMotorFollower; // Follower motor
    // private CANcoder elevatorEncoder; // Range sensor
    private DoubleSupplier Codervalue;

    // private final ShuffleboardTab tab = Shuffleboard.getTab("Elevator");
    private final PIDController pid;

    public Elevator(Subsystems subsystem, String name) {
        super(subsystem, name);
        elevatorMotorLeader = new TalonFX(RobotMap.ElevatorMap.ELEVATOR_MOTOR);
        elevatorMotorFollower = new TalonFX(RobotMap.ElevatorMap.ELEVATOR_MOTOR2);

        // Configure follower motor
        elevatorMotorFollower.setControl(new Follower(elevatorMotorLeader.getDeviceID(), false));

        // Configure current limits
        elevatorMotorLeader.getConfigurator().apply(
                RobotMap.CurrentLimiter.getCurrentLimitConfiguration(RobotMap.ElevatorMap.ELEVATOR_CURRENT_LIMIT));
        elevatorMotorFollower.getConfigurator().apply(
                RobotMap.CurrentLimiter.getCurrentLimitConfiguration(RobotMap.ElevatorMap.ELEVATOR_CURRENT_LIMIT));

        //elevatorEncoder = new CANcoder(RobotMap.ElevatorMap.EVEVATOR_ENCODER);
        Codervalue = () -> elevatorMotorLeader.getPosition().getValueAsDouble();
        pid = new PIDController(RobotMap.ElevatorMap.ELEVATOR_P, RobotMap.ElevatorMap.ELEVATOR_I,
                RobotMap.ElevatorMap.ELEVATOR_D);
        tab.addNumber("Elevator Position", Codervalue);
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

    public void setMotorSpeed(double speed) {
        elevatorMotorLeader.set(speed); // Set the speed of the primary motor
    }

    public void setPIDTarget(double target) {
        pid.setSetpoint(target);
    }

    public boolean pidAtSetpoint() {
        return pid.atSetpoint();
    }

    public void rotateElevatorPID() {
        double output = pid.calculate(getEncoderValue());
        setMotorSpeed(output);
    }

    public double getEncoderValue() {
        return Codervalue.getAsDouble();
    }

    public double getElevatorHeight() {
        return Codervalue.getAsDouble() * ElevatorMap.ELEVATOR_CIRCUMFERENCE;
    }

    @Override
    public boolean isHealthy() {
        // TODO Auto-generated method stub
        return true;
    }

    @Override
    public void Failsafe() {
        // elevatorMotorLeader.disable();
        // elevatorMotorFollower.disable();
    }
}
