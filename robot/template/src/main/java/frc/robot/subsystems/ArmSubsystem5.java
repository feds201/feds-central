package frc.robot.subsystems;

import com.ctre.phoenix.motorcontrol.ControlMode;
import com.ctre.phoenix.motorcontrol.DemandType;
import com.ctre.phoenix.motorcontrol.can.TalonFX;

import edu.wpi.first.math.controller.ArmFeedforward;
import edu.wpi.first.math.util.Units;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.lib.math.Conversions;
import frc.robot.constants.ArmConstants;

public class ArmSubsystem5 extends SubsystemBase {
    private final TalonFX m_armMotor;
    private final ArmFeedforward m_rotationFF = new ArmFeedforward(ArmConstants.kS, ArmConstants.kG, ArmConstants.kV,
            ArmConstants.kA);

    public ArmSubsystem5() {
        m_armMotor = new TalonFX(ArmConstants.kArmMotor1); 
        ArmConstants.configArmMotor(m_armMotor);
    } 
    
    public void rotate(double power) {
        if (power == 0.0) {
            rotateClosedLoop(getArmAngleRadians()); // we always want the arm to hold its position @ 0 output
        } else {
            m_armMotor.set(ControlMode.PercentOutput, power);
        }
    }

    public double getArmAngleRadians() {
        return Units.degreesToRadians(
                Conversions.falconToDegrees(m_armMotor.getSelectedSensorPosition(), ArmConstants.kArmGearRatio));
    }

    public void rotateClosedLoop(double position) {
        // double feedforward = m_rotationFF.calculate(getArmAngleRadians(), velocity);
        double feedforwardOffset = m_rotationFF.calculate(getArmAngleRadians()-ArmConstants.kFeedforwardOffset, 0);
        // SmartDashboard.putNumber("Feedforward", feedforward);
        SmartDashboard.putNumber("Feedforward Offsetted", feedforwardOffset);

        m_armMotor.set(ControlMode.MotionMagic, Conversions.degreesToFalcon(Units.radiansToDegrees(position), ArmConstants.kArmGearRatio), DemandType.ArbitraryFeedForward, feedforwardOffset);
    }
}
