// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.commands.climber;

import java.util.function.BooleanSupplier;

import com.pathplanner.lib.auto.AutoBuilder;
import com.pathplanner.lib.path.PathPlannerPath;

import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.ParallelDeadlineGroup;
import edu.wpi.first.wpilibj2.command.SequentialCommandGroup;
import edu.wpi.first.wpilibj2.command.WaitCommand;
import frc.robot.constants.RobotMap;
import frc.robot.constants.RobotMap.ClimberMap;
import frc.robot.constants.RobotMap.SafetyMap;
import frc.robot.constants.RobotMap.SafetyMap.AutonConstraints;
import frc.robot.subsystems.climber.Climber;
import frc.robot.utils.AutoPathFinder;
import frc.robot.utils.DrivetrainConstants;

// NOTE:  Consider using this command inline, rather than writing a subclass.  For more
// information, see:
// https://docs.wpilib.org/en/stable/docs/software/commandbased/convenience-features.html
public class climbingSequenceUp extends SequentialCommandGroup {
    private Climber m_climber;

    /** Creates a new climbingSequence. */
    public climbingSequenceUp(Climber climber) {
        m_climber = climber;
        // addCommands(new FooCommand(), new BarCommand());
        addCommands( new RaiseClimberBasic(()-> .05, climber).until(m_climber :: internalEncoderPastThreshold));
    }
}
