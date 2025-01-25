
package frc.robot.subsystems.coralAlgaeIntake;

import com.ctre.phoenix6.hardware.CANrange;
import com.ctre.phoenix6.hardware.TalonFX;
import edu.wpi.first.wpilibj2.command.Command;

import frc.robot.utils.SubsystemABS;

public class coralAlgaeIntake extends SubsystemABS {
  private TalonFX intakemotor;
  private CANrange algaeIntakeSensor;
  private CANrange coralIntakeSensor;

  // 1,2,3 are meant to be can IDs (not yet put in)

  private final int intakemotorCanId = 1;
  private final int algaeIntakeSensorCanId = 2;
  private final int coralIntakeSensorCanId = 3;

  // constructor

  public coralAlgaeIntake() {
    intakemotor = new TalonFX(intakemotorCanId); // intializing CANrange sensors
    algaeIntakeSensor = new CANrange(algaeIntakeSensorCanId);
    coralIntakeSensor = new CANrange(coralIntakeSensorCanId);
  }

  @Override
  public void periodic() {
    double algaeSensorReading = algaeIntakeSensor.getDistance().getValueAsDouble();
    double coralSensorReading = coralIntakeSensor.getDistance().getValueAsDouble();

    System.out.println("Algae Sensor Reading: " + algaeSensorReading);
    System.out.println("Coral Sensor Reading: " + coralSensorReading);

    if (algaeSensorReading < 0.1) {
      setMotorSpeed(-0.1);
    } else if (coralSensorReading < 1) { // distance is too close so motor is reversed
      setMotorSpeed(0.1);
    } else {
      stopMotor(); // if sensor reading is normal range, motor stops
    }
  }

  public void stopMotor() {
    intakemotor.disable();
  }

  private void setMotorSpeed(double d) {
    intakemotor.set(d);
  }

  @Override
  public void init() {
    intakemotor = new TalonFX(intakemotorCanId); // intializing CANrange sensors
    algaeIntakeSensor = new CANrange(algaeIntakeSensorCanId);
    coralIntakeSensor = new CANrange(coralIntakeSensorCanId);
  }

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
    // TODO Auto-generated method stub
  }

  @Override
  public void Failsafe() {
    intakemotor.disable();
  }


}
