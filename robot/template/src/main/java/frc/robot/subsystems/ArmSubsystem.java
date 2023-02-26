package frc.robot.subsystems;

import com.ctre.phoenix.motorcontrol.DemandType;
import com.ctre.phoenix.motorcontrol.InvertType;
import com.ctre.phoenix.motorcontrol.NeutralMode;
import com.ctre.phoenix.motorcontrol.TalonFXControlMode;
import com.ctre.phoenix.motorcontrol.TalonFXFeedbackDevice;
import com.ctre.phoenix.motorcontrol.TalonFXInvertType;
import com.ctre.phoenix.motorcontrol.can.TalonFX;

import edu.wpi.first.math.controller.ArmFeedforward;
import edu.wpi.first.math.util.Units;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import frc.robot.Constants.ArmConstants;

import frc.lib.math.Conversions;

public class ArmSubsystem extends SubsystemBase {

    private final TalonFX rotateArmMain = new TalonFX(ArmConstants.kArmMotor1);
    private final TalonFX rotateArmFollower = new TalonFX(ArmConstants.kArmMotor2);

    private int peakVelocityUp = 13360;
    private final double percentOfPeakUp = .65;
    private final double cruiseVelocityAccelUp = peakVelocityUp * percentOfPeakUp;

    private int peakVelocityDown = 8090;
    private final double percentOfPeakDown = .65;
    private final double cruiseVelocityAccelDown = peakVelocityDown * percentOfPeakDown;

    private boolean m_dangerMode = false;

    private ArmFeedforward armFeedforward;
    private final double kS = 0;
    private final double kG = 0.1;
    private final double kV = 0;
    private final double kA = 0;

    public ArmSubsystem() {

        armFeedforward = new ArmFeedforward(kS, kG, kV, kA);

        rotateArmMain.configFactoryDefault();
        rotateArmFollower.configFactoryDefault();
        rotateArmMain.setSelectedSensorPosition(0);

        rotateArmMain.config_kF(0, 0, 0);
        rotateArmMain.config_kP(0, 0.06031, 0); // TUNE THIS
        rotateArmMain.config_kI(0, 0, 0);
        rotateArmMain.config_kD(0, 0.1, 0);

        rotateArmMain.config_kF(1, 0, 0);
        rotateArmMain.config_kP(1, 0.12657, 0); // TUNE THIS
        rotateArmMain.config_kI(1, 0, 0);
        rotateArmMain.config_kD(1, 0, 0);

        rotateArmMain.setInverted(TalonFXInvertType.CounterClockwise);
        rotateArmMain.setNeutralMode(NeutralMode.Brake);
        rotateArmFollower.setNeutralMode(NeutralMode.Brake);

    }

    public Command goToHome() {
        return runOnce(
                () -> {
                    rotateArmMain.set(TalonFXControlMode.Position, 0);
                    // rotateArmFollower.set(TalonFXControlMode.Position, 0);
                });
    }

    public Command slowlyGoDown() {
        return runOnce(
                () -> {
                    rotateArmMain.set(TalonFXControlMode.PercentOutput, -.1);
                    rotateArmFollower.follow(rotateArmMain);
                    // rotateArmFollower.setInverted(InvertType.OpposeMaster);
                });
    }

    public Command slowlyGoUp() {
        return runOnce(
                () -> {
                    rotateArmMain.set(TalonFXControlMode.PercentOutput, .1);
                    rotateArmFollower.follow(rotateArmMain);
                    // rotateArmFollower.setInverted(InvertType.OpposeMaster);
                });
    }

    public Command stop() {
        return runOnce(() -> {
            rotateArmMain.set(TalonFXControlMode.PercentOutput, 0);
            // rotateArmFollower.set(TalonFXControlMode.PercentOutput, 0);
        });
    }

    public Command resetSensor() {
        return runOnce(
                () -> {
                    rotateArmMain.setSelectedSensorPosition(0);
                    rotateArmFollower.setSelectedSensorPosition(0);
                });
    }

    public Command setPosition(double position) {
        return runOnce(
                () -> {
                    manageMotion(position);

                    rotateArmMain.set(TalonFXControlMode.MotionMagic, position, DemandType.ArbitraryFeedForward,
                            armFeedforward.calculate(
                                    Units.degreesToRadians(Conversions.CANcoderToDegrees(position, 38.75)), 0));
                    rotateArmFollower.follow(rotateArmMain);
                    // rotateArmFollower.setInverted(InvertType.OpposeMaster);
                });
    }

    public void manageMotion(double targetPosition) {
        double currentPosition = rotateArmMain.getSelectedSensorPosition();

        if (currentPosition < targetPosition) {
            rotateArmMain.configMotionAcceleration(cruiseVelocityAccelUp, 0);
            rotateArmMain.configMotionCruiseVelocity(cruiseVelocityAccelUp, 0);

            rotateArmMain.selectProfileSlot(0, 0);
            SmartDashboard.putBoolean("Going Up or Down", true);
        } else {
            rotateArmMain.configMotionAcceleration(cruiseVelocityAccelDown, 0);
            rotateArmMain.configMotionCruiseVelocity(cruiseVelocityAccelDown, 0);

            rotateArmMain.selectProfileSlot(1, 0);
            SmartDashboard.putBoolean("Going Up or Down", false);
        }
    }

    @Override
    public void periodic() {
        SmartDashboard.putNumber("Sensor Position main", rotateArmMain.getSelectedSensorPosition());
        SmartDashboard.putNumber("Sensor Position follower", rotateArmMain.getSelectedSensorPosition());
        SmartDashboard.putNumber("Sensor Voltage main", rotateArmMain.getMotorOutputVoltage());
        SmartDashboard.putNumber("Sensor Voltage follower", rotateArmFollower.getMotorOutputVoltage());
        SmartDashboard.putNumber("arm up cruise velo + acceleration", cruiseVelocityAccelUp);
        SmartDashboard.putNumber("arm down cruise velo + acceleration", cruiseVelocityAccelDown);
        // SmartDashboard.putBoolean("Danger Mode", getDangerMode());
    }
}
