package frc.robot.subsystems;

import com.ctre.phoenix.motorcontrol.ControlMode;
import com.ctre.phoenix.motorcontrol.can.TalonFX;

import edu.wpi.first.math.util.Units;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.lib.math.Conversions;
import frc.robot.constants.ArmConstants;

public class ArmSubsystem4 extends SubsystemBase {
    private final TalonFX m_armMain = new TalonFX(ArmConstants.kArmMotor1);

    public ArmSubsystem4() {
        ArmConstants.configArmMotor(m_armMain);
        m_armMain.setSelectedSensorPosition(0);
    }

    public void rotate(double power) {
        m_armMain.set(ControlMode.PercentOutput, power * ArmConstants.kRotateInputSensitivity);
    }

    public void setPosition(double position) {
        m_armMain.set(ControlMode.MotionMagic, position);
    }

    public double getArmAngleRadians() {
        return Units.degreesToRadians(
                Conversions.falconToDegrees(m_armMain.getSelectedSensorPosition(), ArmConstants.kArmGearRatio));
    }

    @Override
    public void periodic() {
    }
}
