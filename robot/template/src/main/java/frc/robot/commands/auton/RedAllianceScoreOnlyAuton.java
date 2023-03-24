package frc.robot.commands.auton;

import frc.robot.constants.IntakeConstants;
import frc.robot.constants.SwerveConstants;
import frc.robot.commands.drive.LockWheels;
import frc.robot.commands.intake.ReverseIntakeWheels;
import frc.robot.commands.intake.RotateIntakeToPosition;
import frc.robot.commands.intake.RunIntakeWheelsInfinite;
import frc.robot.subsystems.IntakeSubsystem;
import frc.robot.subsystems.SwerveSubsystem;
import frc.robot.subsystems.WheelSubsystem;

import java.util.ArrayList;
import java.util.HashMap;

import com.pathplanner.lib.PathConstraints;
import com.pathplanner.lib.PathPlanner;
import com.pathplanner.lib.PathPlannerTrajectory;
import com.pathplanner.lib.auto.PIDConstants;
import com.pathplanner.lib.auto.SwerveAutoBuilder;
import com.pathplanner.lib.commands.*;

import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.ParallelCommandGroup;
import edu.wpi.first.wpilibj2.command.ParallelDeadlineGroup;
import edu.wpi.first.wpilibj2.command.SequentialCommandGroup;
import edu.wpi.first.wpilibj2.command.WaitCommand;

public class RedAllianceScoreOnlyAuton extends SequentialCommandGroup {
        private final IntakeSubsystem s_intake;
        private final WheelSubsystem s_wheels;

    public RedAllianceScoreOnlyAuton(SwerveSubsystem s_Swerve) {
        s_intake = new IntakeSubsystem();
        s_wheels = new WheelSubsystem();
        // This will load the file "FullAuto.path" and generate it with a max velocity
        // of 4 m/s and a max acceleration of 3 m/s^2
        // for every path in the group
        ArrayList<PathPlannerTrajectory> pathGroup1 = (ArrayList<PathPlannerTrajectory>) PathPlanner
                .loadPathGroup("High Cone + Low Cube (B)", new PathConstraints(3, 2));

        // This is just an example event map. It would be better to have a constant,
        // global event map
        // in your code that will be used by all path following commands.
        HashMap<String, Command> eventMap = new HashMap<>();

        // Create the AutoBuilder. This only needs to be created once when robot code
        // starts, not every time you want to create an auto command. A good place to
        // put this is in RobotContainer along with your subsystems.
        SwerveAutoBuilder autoBuilder = new SwerveAutoBuilder(
                s_Swerve::getPose, // Pose2d supplier
                s_Swerve::resetOdometry, // Pose2d consumer, used to reset odometry at the beginning of auto
                SwerveConstants.swerveKinematics, // SwerveDriveKinematics
                new PIDConstants(SwerveConstants.driveKP, SwerveConstants.driveKI, SwerveConstants.driveKD), // PID constants to correct for translation error (used to create the X
                                                 // and Y PID controllers)
                new PIDConstants(SwerveConstants.angleKP, SwerveConstants.angleKI, SwerveConstants.angleKD), // PID constants to correct for rotation error (used to create the
                                                 // rotation controller)
                s_Swerve::setModuleStates, // Module states consumer used to output to the drive subsystem
                eventMap,
                true, // Should the path be automatically mirrored depending on alliance color.
                      // Optional, defaults to true
                s_Swerve // The drive subsystem. Used to properly set the requirements of path following
                         // commands
        );

        Command fullAuto2 = autoBuilder.fullAuto(pathGroup1);


        addCommands(
                new PlaceConeHigh(null, null, s_Swerve),
                new InstantCommand(() -> s_Swerve.resetOdometry(pathGroup1.get(0).getInitialHolonomicPose())), 
                new ParallelCommandGroup(fullAuto2, 
                        new SequentialCommandGroup(new WaitCommand(2.3), 
                                new ParallelDeadlineGroup(new RotateIntakeToPosition(s_intake, IntakeConstants.kIntakeForwardSetpoint), 
                                        new RunIntakeWheelsInfinite(s_wheels),
                                        new WaitCommand(1.7)), 
                                new ParallelDeadlineGroup(new WaitCommand(2.3), 
                                        new RotateIntakeToPosition(s_intake, IntakeConstants.kIntakeRetractSetpoint))),
                        new ReverseIntakeWheels(s_wheels, 0.5)), 
                new WaitCommand(15));
        }
}