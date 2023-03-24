package frc.robot.commands.arm;

import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.constants.ArmConstants;
import frc.robot.subsystems.ArmSubsystem4;

public class RotateArmPositionNearThreshold extends CommandBase {
    private final ArmSubsystem4 s_arm;
    private final double m_angleRadians;

    public RotateArmPositionNearThreshold(ArmSubsystem4 s_arm, double angleRadians) {
        this.s_arm = s_arm;
        addRequirements(s_arm);

        this.m_angleRadians = angleRadians;
    }

    
    @Override
    public void initialize() {
        s_arm.getRotationPIDController().reset();
        // SmartDashboard.putNumber("Angle set to PID (RADIANS)", m_angleRadians);
        // s_arm.getRotationPIDController().setSetpoint(m_angleRadians);
    }

    @Override
    public void execute() {
        PIDController rotationController = s_arm.getRotationPIDController();
        double PIDCalculatedValue = rotationController.calculate(s_arm.getArmAngleRadians(), m_angleRadians);
        SmartDashboard.putNumber("Angle set to PID (RADIANS)", m_angleRadians);
        SmartDashboard.putNumber("PIDController Calculate", PIDCalculatedValue);
    
        if(Math.abs(s_arm.getArmAngleRadians() - m_angleRadians) < ArmConstants.kActivatePIDThreshold) {
            s_arm.rotateClosedLoop(PIDCalculatedValue);
        } else if (s_arm.getArmAngleRadians() > m_angleRadians) {
            s_arm.rotate(-ArmConstants.kArmCruisingPower);
        } else {
            s_arm.rotate(ArmConstants.kArmCruisingPower);
        }
    }

    @Override
    public void end(boolean interrupted) {
        s_arm.rotateClosedLoop(0);
    }

    @Override
    public boolean isFinished() {
        return s_arm.getRotationPIDController().atSetpoint();
    }

}
