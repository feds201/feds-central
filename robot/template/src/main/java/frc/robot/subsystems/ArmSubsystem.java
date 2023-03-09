package frc.robot.subsystems;

import frc.robot.subsystems.VisionSubsystem;
import frc.robot.utils.ConeDetection;

import com.ctre.phoenix.motorcontrol.DemandType;
import com.ctre.phoenix.motorcontrol.FollowerType;
import com.ctre.phoenix.motorcontrol.InvertType;
import com.ctre.phoenix.motorcontrol.NeutralMode;
import com.ctre.phoenix.motorcontrol.StatusFrameEnhanced;
import com.ctre.phoenix.motorcontrol.SupplyCurrentLimitConfiguration;
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
import frc.robot.Constants.coneOrientation;
import frc.lib.math.Conversions;
import frc.robot.subsystems.VisionSubsystem;

public class ArmSubsystem extends SubsystemBase {
    private final TalonFX rotateArmMain = new TalonFX(ArmConstants.kArmMotor1);
    private final TalonFX rotateArmFollower = new TalonFX(ArmConstants.kArmMotor2);
    private final ConeDetection coneDetector;

    private boolean settingArmPositionUp = false;
    private boolean armDoneRotating = false;
    private double targetArmPosition = ArmConstants.kArmHome;

    public ArmSubsystem() {
        rotateArmMain.configFactoryDefault();
        rotateArmFollower.configFactoryDefault();

        rotateArmMain.configForwardSoftLimitThreshold(Conversions.degreesToFalcon(130, ArmConstants.kArmGearRatio),
                0);
        rotateArmMain.configReverseSoftLimitThreshold(Conversions.degreesToFalcon(-130, ArmConstants.kArmGearRatio), 0);
        rotateArmMain.configForwardSoftLimitEnable(true, 0);
        rotateArmMain.configReverseSoftLimitEnable(true, 0);

        rotateArmMain.setSelectedSensorPosition(0);

        rotateArmMain.config_kP(0, ArmConstants.kPUp, 0); // TUNE THIS
        rotateArmMain.config_kI(0, ArmConstants.kIUp, 0);
        rotateArmMain.config_kD(0, ArmConstants.kDUp, 0);

        rotateArmMain.config_kP(1, ArmConstants.kPDown, 0); // TUNE THIS
        rotateArmMain.config_kI(1, ArmConstants.kIDown, 0);
        rotateArmMain.config_kD(1, ArmConstants.kDDown, 0);

        rotateArmFollower.follow(rotateArmMain);
        rotateArmFollower.setInverted(TalonFXInvertType.FollowMaster);

        rotateArmMain.setInverted(TalonFXInvertType.CounterClockwise);
        rotateArmMain.setNeutralMode(NeutralMode.Brake);
        rotateArmFollower.setNeutralMode(NeutralMode.Brake);
        rotateArmMain.configVoltageCompSaturation(12);
        rotateArmFollower.configVoltageCompSaturation(12);
        rotateArmMain.enableVoltageCompensation(true);
        rotateArmFollower.enableVoltageCompensation(true);


        rotateArmMain.setStatusFramePeriod(StatusFrameEnhanced.Status_1_General, 10);
		rotateArmMain.setStatusFramePeriod(StatusFrameEnhanced.Status_2_Feedback0, 10);
		rotateArmMain.setStatusFramePeriod(StatusFrameEnhanced.Status_3_Quadrature, 255);
		rotateArmMain.setStatusFramePeriod(StatusFrameEnhanced.Status_4_AinTempVbat, 255);
		rotateArmMain.setStatusFramePeriod(StatusFrameEnhanced.Status_8_PulseWidth, 255);
		rotateArmMain.setStatusFramePeriod(StatusFrameEnhanced.Status_10_Targets, 255);
		rotateArmMain.setStatusFramePeriod(StatusFrameEnhanced.Status_12_Feedback1, 255);
		rotateArmMain.setStatusFramePeriod(StatusFrameEnhanced.Status_13_Base_PIDF0, 255);
		rotateArmMain.setStatusFramePeriod(StatusFrameEnhanced.Status_14_Turn_PIDF1, 255);
		rotateArmMain.setStatusFramePeriod(StatusFrameEnhanced.Status_Brushless_Current, 255);

        rotateArmFollower.setStatusFramePeriod(StatusFrameEnhanced.Status_1_General, 10);
		rotateArmFollower.setStatusFramePeriod(StatusFrameEnhanced.Status_2_Feedback0, 10);
		rotateArmFollower.setStatusFramePeriod(StatusFrameEnhanced.Status_3_Quadrature, 255);
		rotateArmFollower.setStatusFramePeriod(StatusFrameEnhanced.Status_4_AinTempVbat, 255);
		rotateArmFollower.setStatusFramePeriod(StatusFrameEnhanced.Status_8_PulseWidth, 255);
		rotateArmFollower.setStatusFramePeriod(StatusFrameEnhanced.Status_10_Targets, 255);
		rotateArmFollower.setStatusFramePeriod(StatusFrameEnhanced.Status_12_Feedback1, 255);
		rotateArmFollower.setStatusFramePeriod(StatusFrameEnhanced.Status_13_Base_PIDF0, 255);
		rotateArmFollower.setStatusFramePeriod(StatusFrameEnhanced.Status_14_Turn_PIDF1, 255);
		rotateArmFollower.setStatusFramePeriod(StatusFrameEnhanced.Status_Brushless_Current, 255);
        
        SupplyCurrentLimitConfiguration rotateArmMainCurrentLimit = new SupplyCurrentLimitConfiguration();
        rotateArmMainCurrentLimit.currentLimit = 40;

        rotateArmMain.configSupplyCurrentLimit(rotateArmMainCurrentLimit);

        coneDetector = new ConeDetection();
    }

    public coneOrientation getGripResult(){ 
        coneDetector.startVisionThread();
        return coneDetector.getResult();
    }

    public Command goToHome() {
        return runOnce(
                () -> {
                    rotateArmMain.set(TalonFXControlMode.Position, 0);
                });
    }

    public Command slowlyGoDown() {
        return runOnce(
                () -> {
                    rotateArmMain.set(TalonFXControlMode.PercentOutput, -.1);
                });
    }

    public Command slowlyGoUp() {
        return runOnce(
                () -> {
                    rotateArmMain.set(TalonFXControlMode.PercentOutput, .1);
                });
    }

    public Command stop() {
        return runOnce(() -> {
            rotateArmMain.set(TalonFXControlMode.PercentOutput, 0);
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

        targetArmPosition = position; // set the target arm position
        armDoneRotating = false; // the arm either is at the target, in which case this will quickly
                                 // set to be true, or the arm is truely not done rotating

        if (position != ArmConstants.kArmHome) {
            settingArmPositionUp = true; // you don't want to extend into the robot.
        } else {
            settingArmPositionUp = false;
        }

        return runOnce(
                () -> {
                    manageMotion(position);
                    double aff = ArmConstants.armFeedforward.calculate(
                            Units.degreesToRadians(Conversions.falconToDegrees(position, ArmConstants.kArmGearRatio))
                                    - 90,
                            Units.degreesToRadians(Conversions.falconToRPM(position, position)));

                    // SmartDashboard.putNumber("Target Position Encoder Counts", position);
                    // SmartDashboard.putNumber("Target Degrees for motor",
                    //         Conversions.falconToDegrees(position, ArmConstants.kArmGearRatio));
                    // SmartDashboard.putNumber("Target Degrees for feedforward",
                    //         Conversions.falconToDegrees(position, ArmConstants.kArmGearRatio) - 90);
                    // SmartDashboard.putNumber("Feedfoward with that amount",
                    //         aff);

                    rotateArmMain.set(TalonFXControlMode.MotionMagic, position, DemandType.ArbitraryFeedForward, aff);


                });
    }

    public Command grabCone(){
        double targetArmPosition;
        if(getGripResult().equals(coneOrientation.LEFT)){
            targetArmPosition = ArmConstants.kArmPickConeLeft;
        }
        else if(getGripResult().equals(coneOrientation.RIGHT)){
            targetArmPosition = ArmConstants.kArmPickConeRight;
        }
        else{
            targetArmPosition = ArmConstants.kArmPickCube;
        }
        return runOnce(
                () -> {
                    manageMotion(targetArmPosition);
                    double aff = ArmConstants.armFeedforward.calculate(
                            Units.degreesToRadians(Conversions.falconToDegrees(targetArmPosition, ArmConstants.kArmGearRatio))
                                    - 90,
                            0);
                            rotateArmMain.set(TalonFXControlMode.MotionMagic, targetArmPosition, DemandType.ArbitraryFeedForward, aff);
        
                        });        
    }

    public void manageMotion(double targetPosition) {
        // double currentPosition = rotateArmMain.getSelectedSensorPosition();

        // if (currentPosition > targetPosition) {
        rotateArmMain.configMotionAcceleration(ArmConstants.cruiseVelocityAccelUp, 0);
        rotateArmMain.configMotionCruiseVelocity(ArmConstants.cruiseVelocityAccelUp, 0);

        rotateArmMain.selectProfileSlot(0, 0);
        // SmartDashboard.putBoolean("Towards Front", true);
        // } else {
        // rotateArmMain.configMotionAcceleration(cruiseVelocityAccelDown, 0);
        // rotateArmMain.configMotionCruiseVelocity(cruiseVelocityAccelDown, 0);

        // rotateArmMain.selectProfileSlot(1, 0);
        // SmartDashboard.putBoolean("Towards Front", false);
        // }
    }

    public boolean getArmDoneRotating() {
        return armDoneRotating;
    }

    @Override
    public void periodic() {

        if (settingArmPositionUp) { // if you are outside the limits of the robot
            if (Math.abs(
                    targetArmPosition - rotateArmMain.getSelectedSensorPosition()) < ArmConstants.kArmGoalThreshold) {
                // and the arm is very close to the target position
                armDoneRotating = true; // then you can extend
            } else {
                armDoneRotating = false; // else DO NOT EXTEND
            }
        }

        // SmartDashboard.putNumber("Sensor Position main", rotateArmMain.getSelectedSensorPosition());
        // SmartDashboard.putNumber("Sensor Position degrees",
                // Conversions.CANcoderToDegrees(rotateArmMain.getSelectedSensorPosition(), ArmConstants.kArmGearRatio));
        // SmartDashboard.putNumber("Sensor Voltage main", rotateArmMain.getMotorOutputVoltage());
    
        // SmartDashboard.putBoolean("Arm Done ROtating", armDoneRotating);
        // SmartDashboard.putNumber("Targ3et Arm Position", targetArmPosition);
        // SmartDashboard.putBoolean("Setting Arm Pos UP?", settingArmPositionUp);
    }
}
