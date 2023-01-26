package frc.robot.commands;

import java.util.function.DoubleSupplier;

import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.Constants;
import frc.robot.subsystems.DriveSubsystem;
import frc.robot.utils.DriveFunctions;

public class FieldRelativeDriveControlCommand extends CommandBase {
    private final DriveSubsystem m_drive;
    private final DoubleSupplier m_forward;
    private final DoubleSupplier m_strafe;
    private final DoubleSupplier m_rotateX;
    private final DoubleSupplier m_poseAngle;

    public FieldRelativeDriveControlCommand (DriveSubsystem drive, DoubleSupplier forward, DoubleSupplier strafe, DoubleSupplier rotateX, DoubleSupplier poseAngle) {
        m_drive = drive;
        m_forward = forward;
        m_strafe = strafe;
        m_rotateX = rotateX;
        m_poseAngle = poseAngle;

        addRequirements(m_drive);
    } 

    @Override
    public void execute() {
        double forwardValue = -m_forward.getAsDouble();
        double strafeValue = m_strafe.getAsDouble();
        double rotateXValue = m_rotateX.getAsDouble();
        double poseAngleValue = m_poseAngle.getAsDouble();

        double linearAngle = -Math.atan2(forwardValue, strafeValue) / Math.PI / 2 + 0.25;
        linearAngle = (linearAngle % 1 + 1) % 1;
        linearAngle -= poseAngleValue;
        double linearSpeed = DriveFunctions.deadzone(Math.sqrt(forwardValue * forwardValue + strafeValue * strafeValue), Constants.DEADZONE_THRESHOLD);
        double rotate = DriveFunctions.deadzone(rotateXValue, Constants.DEADZONE_THRESHOLD) / 2;

        this.m_drive.setTargetVelocity(linearAngle, linearSpeed, rotate);
    }
}



