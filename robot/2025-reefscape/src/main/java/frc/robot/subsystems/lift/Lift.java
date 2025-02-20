package frc.robot.subsystems.lift;

import java.util.Map;
import java.util.function.DoubleSupplier;

import com.ctre.phoenix6.controls.Follower;
import com.ctre.phoenix6.controls.VoltageOut;
import com.ctre.phoenix6.hardware.CANcoder;
import com.ctre.phoenix6.hardware.TalonFX;
import frc.robot.constants.RobotMap;
import frc.robot.constants.RobotMap.ElevatorMap;
import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.networktables.GenericEntry;
import edu.wpi.first.wpilibj.shuffleboard.BuiltInWidgets;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.button.NetworkButton;
import frc.robot.utils.SubsystemABS;
import frc.robot.utils.Subsystems;

public class Lift extends SubsystemABS {
    private TalonFX elevatorMotorLeader; // Primary motor
    private TalonFX elevatorMotorFollower; // Follower motor
    // private CANcoder elevatorEncoder; // Range sensor
    private DoubleSupplier m_encoderValue;
    public DoubleSupplier m_elevatorSpeed;

    // private final ShuffleboardTab tab = Shuffleboard.getTab("Elevator");
    private final PIDController pid;

    public Lift(Subsystems subsystem, String name) {
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

        // elevatorEncoder = new CANcoder(RobotMap.ElevatorMap.EVEVATOR_ENCODER);
        m_encoderValue = () -> elevatorMotorLeader.getPosition().getValueAsDouble();
        pid = new PIDController(RobotMap.ElevatorMap.ELEVATOR_P, RobotMap.ElevatorMap.ELEVATOR_I, RobotMap.ElevatorMap.ELEVATOR_D);
        
        tab.add("Elevator PID", pid)
            .withWidget(BuiltInWidgets.kPIDController);

        tab.addNumber("Elevator Position", m_encoderValue);
        GenericEntry elevatorSpeedSetter = tab.add("Elevator Speed", 0.0)
                .withWidget(BuiltInWidgets.kNumberSlider)
                .withProperties(Map.of("min", 0, "max", .2))
                .getEntry();
        m_elevatorSpeed = () -> elevatorSpeedSetter.getDouble(0);
    }

    @Override
    public void periodic() {
        m_encoderValue = () -> elevatorMotorLeader.getPosition().getValueAsDouble();
    }

    @Override
    public void simulationPeriodic() {
    }

    @Override
    public void setDefaultCmd() {
    }

    public void setMotorSpeed(double speed) {
        elevatorMotorLeader.set(speed); // Set the speed of the primary motor
        SmartDashboard.putNumber("Actual Elevator Speed", speed);
    }

    public void setMotorVolt(double volt){
        elevatorMotorLeader.setControl(new VoltageOut(volt));
    }

    public void setPIDTarget(double target) {
        pid.setSetpoint(target);
    }

    public boolean pidAtSetpoint() {
        return pid.atSetpoint();
    }

    public void rotateElevatorPID() {
        double output = pid.calculate(getEncoderValue());
        setMotorSpeed(output + ElevatorMap.ELEVATOR_F);
    }

    public double getEncoderValue() {
        return m_encoderValue.getAsDouble();
    }

    public double getElevatorHeight() {
        return m_encoderValue.getAsDouble() * ElevatorMap.ELEVATOR_CIRCUMFERENCE;
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
