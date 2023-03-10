// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.commands.arm;


import java.util.function.DoubleSupplier;

import edu.wpi.first.math.MathUtil;
import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.Constants;
import frc.robot.Constants.ArmConstants;
import frc.robot.subsystems.ArmSubsystem2;

public class ArmControl extends CommandBase {
    /** Creates a new ArmControl. */
    private DoubleSupplier m_rotationSupplier;
    private DoubleSupplier m_extensionSupplier;
    
    private ArmSubsystem2 m_arm;

    public ArmControl(ArmSubsystem2 arm, DoubleSupplier rotationSupplier, DoubleSupplier extensionSupplier) {
        m_arm = arm;
        addRequirements(arm);
        
        m_rotationSupplier = rotationSupplier;
        m_extensionSupplier = extensionSupplier;
        // Use addRequirements() here to declare subsystem dependencies.
    }

    // Called when the command is initially scheduled.
    @Override
    public void initialize() {
    }

    // Called every time the scheduler runs while the command is scheduled.
    @Override
    public void execute() {
        double rotatePercent = modifyAxis(m_rotationSupplier.getAsDouble()) / 2;
        if (rotatePercent > 0) {
            rotatePercent = rotatePercent * (1 - ArmConstants.kGPercent) + ArmConstants.kGPercent;
        } else if (rotatePercent < 0) {
            rotatePercent = rotatePercent * (ArmConstants.kGPercent) + ArmConstants.kGPercent;
        }
        double extendPercent = modifyAxis(m_extensionSupplier.getAsDouble()) / 2;
        m_arm.extend(-extendPercent);
        m_arm.rotate(-rotatePercent);
    }

    // Called once the command ends or is interrupted.
    @Override
    public void end(boolean interrupted) {
    }

    private static double modifyAxis(double value) {
        return modifyAxis(value, 2);
    }

    private static double modifyAxis(double value, int exponent) {
        // Deadband
        value = MathUtil.applyDeadband(value, Constants.stickDeadbandDrive);

        value = Math.copySign(Math.pow(value, exponent), value);

        return value;
    }

    // Returns true when the command should end.
    @Override
    public boolean isFinished() {
        return false;
    }
}
