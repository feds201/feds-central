
package frc.robot.subsystems.coralAlgaeIntake;

import com.ctre.phoenix6.hardware.CANrange;
import com.ctre.phoenix6.hardware.TalonFX;

import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import frc.robot.constants.RobotMap;
import frc.robot.utils.SubsystemABS;

public class coralAlgaeIntake extends SubsystemABS {
  private TalonFX intakemotor;
  private CANrange algaeIntakeSensor;
  private CANrange coralIntakeSensor;
  private double algaeSensorReading;
  private double coralSensorReading;


 

  // constructor

  public coralAlgaeIntake() {
    intakemotor = new TalonFX(RobotMap.IntakeMap.SensorConstants.INTAKE_MOTOR); // intializing CANrange sensors
    algaeIntakeSensor = new CANrange(RobotMap.IntakeMap.SensorConstants.ALGAE_CANRANGE);
    coralIntakeSensor = new CANrange(RobotMap.IntakeMap.SensorConstants.CORAL_CANRANGE);
  }

  @Override
  public void periodic() {
    algaeSensorReading = algaeIntakeSensor.getDistance().getValueAsDouble();
    coralSensorReading = coralIntakeSensor.getDistance().getValueAsDouble();

    SmartDashboard.putNumber("Algae Distance Reading: ", algaeSensorReading);
    SmartDashboard.putNumber("Coral Distance Reading", coralSensorReading);
    
    
    if (algaeSensorReading < 0.1) {
      setMotorSpeed(-0.1);
    } else if (coralSensorReading < 1) { // distance is too close so motor is reversed
      setMotorSpeed(0.1);
    } else {
      stopMotor(); // if sensor reading is normal range, motor stops
    }
  }


   //setters
  public void stopMotor() {
    intakemotor.set(0);
  }

  public void setMotorSpeed(double speed) {
    intakemotor.set(speed);
  }

  //getters
  public double getCoralCanrangeValue(){
    return coralSensorReading;
  }

  public double getAlgaeCanrangeValue(){
    return algaeSensorReading;
  }

  @Override
  public void init() {}
  

  @Override
  public void simulationPeriodic() {
    periodic();
  }

  @Override
  public void setDefaultCmd() {

  }

  @Override
  public boolean isHealthy() {
    if (intakemotor.getDeviceTemp().getValueAsDouble() > 60) {
      return true;
    }
    return false;
  }

  @Override
  public void Failsafe() {
    intakemotor.disable();
  }



}