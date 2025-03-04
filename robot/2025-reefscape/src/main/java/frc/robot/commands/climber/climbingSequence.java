// // Copyright (c) FIRST and other WPILib contributors.
// // Open Source Software; you can modify and/or share it under the terms of
// // the WPILib BSD license file in the root directory of this project.

// package frc.robot.commands.climber;

// import java.util.function.BooleanSupplier;

// import com.pathplanner.lib.auto.AutoBuilder;
// import com.pathplanner.lib.path.PathPlannerPath;

// import edu.wpi.first.wpilibj2.command.Command;
// import edu.wpi.first.wpilibj2.command.SequentialCommandGroup;
// import frc.robot.constants.RobotMap;
// import frc.robot.constants.RobotMap.ClimberMap;
// import frc.robot.constants.RobotMap.SafetyMap;
// import frc.robot.constants.RobotMap.SafetyMap.AutonConstraints;
// import frc.robot.subsystems.climber.Climber;
// import frc.robot.utils.AutoPathFinder;
// import frc.robot.utils.DrivetrainConstants;

// // NOTE:  Consider using this command inline, rather than writing a subclass.  For more
// // information, see:
// // https://docs.wpilib.org/en/stable/docs/software/commandbased/convenience-features.html
// public class climbingSequence extends SequentialCommandGroup {
//     private Climber m_climber;
//     private PathPlannerPath climbAlignPath = AutoPathFinder.loadPath("BlueClimbCenter");
//     private Command followPath;

//     /** Creates a new climbingSequence. */
//     public climbingSequence(Climber climber) {
//         m_climber = climber;
//         followPath = AutoBuilder.pathfindThenFollowPath(climbAlignPath, AutonConstraints.kPathConstraints);
//         // Add your commands in the addCommands() call, e.g.
//         // addCommands(new FooCommand(), new BarCommand());
//         addCommands(followPath,
//                 new raiseClimber(m_climber, RobotMap.ClimberMap.CLIMBER_UP_ANGLE), DrivetrainConstants.drivetrain
//                         .applyRequest(() -> DrivetrainConstants.robotDrive.withVelocityX(.1).withVelocityY(0))
//                         .until(m_climber::getLeftValue)
//                         .until(m_climber::getRightValue),
//                 new raiseClimber(m_climber, ClimberMap.CLIMBER_STOW_ANGLE));
//     }
// }
