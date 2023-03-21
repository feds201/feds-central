package frc.robot.subsystems;

import com.ctre.phoenix.motorcontrol.ControlMode;
import com.ctre.phoenix.motorcontrol.can.TalonFX;

import edu.wpi.first.math.controller.ArmFeedforward;
import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.util.Units;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.lib.math.Conversions;
import frc.robot.constants.ArmConstants;
import frc.robot.utils.DriveFunctions;

public class ArmSubsystem4 extends SubsystemBase {
    private final TalonFX m_armMain = new TalonFX(ArmConstants.kArmMotor1);
    private final PIDController m_rotationPIDController = new PIDController(ArmConstants.kPUp, ArmConstants.kIUp,
            ArmConstants.kDUp);
    private final ArmFeedforward m_rotationFF = new ArmFeedforward(ArmConstants.kS, ArmConstants.kG, ArmConstants.kV,
            ArmConstants.kA);

    // private double angleSetpointRadians;
    private boolean isHumanControlledRotation; // TODO: does this even matter?

    public ArmSubsystem4() {
        ArmConstants.configArmMotor(m_armMain);
        m_armMain.setSelectedSensorPosition(0);

        m_rotationPIDController.enableContinuousInput(0, 2 * Math.PI);
        // setAngleSetpointRadians(getArmAngleRadians());
        m_rotationPIDController.setTolerance(ArmConstants.kArmTolerance);
        isHumanControlledRotation = false;
        
        SmartDashboard.putData("Arm Rotation PID Controller", m_rotationPIDController);
    }

    public PIDController getRotationPIDController() {
        return m_rotationPIDController;
    }

    public double getArmAngleRadians() {
        return Units.degreesToRadians(
                Conversions.falconToDegrees(m_armMain.getSelectedSensorPosition(), ArmConstants.kArmGearRatio));
    }

    // public double getArmSetpointRadians() {
    //     return angleSetpointRadians;
    // }

    // public void setAngleSetpointRadians(double angle) {
    //     this.angleSetpointRadians = angle;
    // }

    public void rotate(double power) {
        if (power == 0.0) {
            // if (isHumanControlledRotation) {
                rotateClosedLoop(0); // we always want the arm to hold its position @ 0 output
            // }
        } else {
            isHumanControlledRotation = true;
            m_armMain.set(ControlMode.PercentOutput, power);
        }
    }

    public void rotateClosedLoop(double velocity) {
        if (getArmAngleRadians() > Units.degreesToRadians(ArmConstants.kForwardSoftLimit)) {
            velocity = 0;
        }

        isHumanControlledRotation = false;

        double feedforward = m_rotationFF.calculate(getArmAngleRadians(), velocity);
        double feedforwardOffset = m_rotationFF.calculate(getArmAngleRadians()-ArmConstants.kFeedforwardOffset, velocity);
        SmartDashboard.putNumber("Feedforward", feedforward);
        SmartDashboard.putNumber("Feedforward Offsetted", feedforwardOffset);
        SmartDashboard.putNumber("Velocity", velocity);

        m_armMain.set(ControlMode.PercentOutput, DriveFunctions.voltageToPercentOutput(feedforward));
    }

    
    @Override
    public void periodic() {
        // SmartDashboard.putNumber("Target Angle Rads", this.angleSetpointRadians);
        // SmartDashboard.putNumber("Target Angle Rads Translated", this.angleSetpointRadians - Math.PI/2);

        SmartDashboard.putNumber("Target Angle Rads", this.getRotationPIDController().getSetpoint());
        SmartDashboard.putNumber("Target Angle Rads Translated", this.getRotationPIDController().getSetpoint() - Math.PI/2);
        
        SmartDashboard.putNumber("Current Angle Rads", Units.degreesToRadians(
                Conversions.falconToDegrees(m_armMain.getSelectedSensorPosition(), ArmConstants.kArmGearRatio)));
        SmartDashboard.putNumber("Current Angle Rads Translated", Units.degreesToRadians(
                Conversions.falconToDegrees(m_armMain.getSelectedSensorPosition(), ArmConstants.kArmGearRatio)) - Math.PI/2);
        SmartDashboard.putBoolean("Is Human Controlled", isHumanControlledRotation);


        SmartDashboard.putNumber("kP", ArmConstants.kPUp);
        SmartDashboard.putNumber("kI", ArmConstants.kIUp);
        SmartDashboard.putNumber("kD", ArmConstants.kDUp);

        SmartDashboard.putNumber("kS", ArmConstants.kS);
        SmartDashboard.putNumber("kG", ArmConstants.kG);
        SmartDashboard.putNumber("kV", ArmConstants.kV);
        SmartDashboard.putNumber("kA", ArmConstants.kA);

    }
}
