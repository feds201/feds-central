package frc.robot.subsystems.Elevator;

import com.ctre.phoenix6.configs.CurrentLimitsConfigs;
import com.ctre.phoenix6.configs.TalonFXConfiguration;
import com.ctre.phoenix6.configs.TalonFXConfigurator;
import com.ctre.phoenix6.controls.Follower;
import com.ctre.phoenix6.hardware.CANcoder;
import com.ctre.phoenix6.hardware.CANrange;
import com.ctre.phoenix6.hardware.TalonFX;
import frc.robot.constants.RobotMap;
import frc.robot.constants.RobotMap.ElevatorMap;
import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardTab;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.utils.SubsystemABS;

public class Elevator extends SubsystemABS {
    private final TalonFX elevatorMotorLeader; // Primary motor
    private final TalonFX elevatorMotorFollower; // Follower motor
    private final CANcoder elevatorEncoder; // Range sensor
    private final ShuffleboardTab tab;// replace with ABS tab
    private final PIDController pid;

    public Elevator(/*add part and tab name to follow abs */) {
        tab = Shuffleboard.getTab("Elevator"); //put in init with get tab AFTER replacing tab with abs tab

        elevatorMotorLeader = new TalonFX(RobotMap.ElevatorMap.ELEVATOR_MOTOR);
        elevatorMotorFollower = new TalonFX(RobotMap.ElevatorMap.ELEVATOR_MOTOR2);

        elevatorEncoder = new CANcoder(RobotMap.ElevatorMap.EVEVATOR_ENCODER);
        
        pid = new PIDController(RobotMap.ElevatorMap.ELEVATOR_P, RobotMap.ElevatorMap.ELEVATOR_I, RobotMap.ElevatorMap.ELEVATOR_D);
    }

    @Override
    public void init() {
        // Configure follower motor
        elevatorMotorFollower.setControl(new Follower(elevatorMotorLeader.getDeviceID(), false));

        // Configure current limits
        elevatorMotorLeader.getConfigurator().apply(RobotMap.ElevatorMap.getElevatorCurrentLimitingConfiguration());
        elevatorMotorFollower.getConfigurator().apply(RobotMap.ElevatorMap.getElevatorCurrentLimitingConfiguration());

        // Add Shuffleboard widget for the range sensor
        tab.add("Elevator Position", getEncoderValue());
    }

    @Override
    public void periodic() {
        // Update Shuffleboard with the latest position
        tab.add("Elevator Position", getEncoderValue());
    }
    
    @Override
    public void simulationPeriodic() {
        // TODO Auto-generated method stub
      
    }

    public void setMotorSpeed(double speed) {
        elevatorMotorLeader.set(speed); // Set the speed of the primary motor
    }

    public void setPIDTarget(double target){
        pid.setSetpoint(target);
    }

    public boolean pidAtSetpoint() {
        return pid.atSetpoint();
    }
     
    public void rotateElevatorPID(){
        double output = pid.calculate(getEncoderValue());
        setMotorSpeed(output);
    }

   public double getEncoderValue(){
        return elevatorEncoder.getAbsolutePosition().getValueAsDouble();
   }





    @Override
    public void setDefaultCmd() {
        // TODO Auto-generated method stub
      
    }

    @Override
    public boolean isHealthy() {
        // TODO Auto-generated method stub
       return false;
    }

    @Override
    public void Failsafe() {
        // TODO Auto-generated method stub
      
    }
}
