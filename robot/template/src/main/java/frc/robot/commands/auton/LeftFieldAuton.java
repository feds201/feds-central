package frc.robot.commands.auton;

import frc.robot.constants.IntakeConstants;
import frc.robot.constants.SwerveConstants;
import frc.robot.commands.drive.LockWheels;
import frc.robot.commands.intake.ReverseIntakeWheels;
import frc.robot.subsystems.ArmSubsystem5;
import frc.robot.subsystems.ClawSubsystem;
import frc.robot.subsystems.IntakeSubsystem;
import frc.robot.subsystems.LimelightSubsystem;
import frc.robot.subsystems.SwerveSubsystem;
import frc.robot.subsystems.WheelSubsystem;

import java.util.ArrayList;
import java.util.HashMap;

import com.pathplanner.lib.PathConstraints;
import com.pathplanner.lib.PathPlanner;
import com.pathplanner.lib.PathPlannerTrajectory;
import com.pathplanner.lib.auto.PIDConstants;
import com.pathplanner.lib.auto.SwerveAutoBuilder;

import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.ParallelDeadlineGroup;
import edu.wpi.first.wpilibj2.command.SequentialCommandGroup;
import edu.wpi.first.wpilibj2.command.WaitCommand;

public class LeftFieldAuton extends SequentialCommandGroup {
    public LeftFieldAuton(SwerveSubsystem s_Swerve, ArmSubsystem5 s_arm, ClawSubsystem s_claw, IntakeSubsystem s_intake, WheelSubsystem s_wheels, LimelightSubsystem s_limelight) {
        // This will load the file "FullAuto.path" and generate it with a max velocity
        // of 4 m/s and a max acceleration of 3 m/s^2
        // for every path in the group
        ArrayList<PathPlannerTrajectory> pathGroup = (ArrayList<PathPlannerTrajectory>) PathPlanner
                .loadPathGroup("Curve Path", new PathConstraints(4, 2));

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

        Command fullLeftSideAuto = autoBuilder.fullAuto(pathGroup);


        addCommands(
                new PlaceHighCone(s_Swerve, s_limelight, s_arm, s_claw),
                new InstantCommand(() -> s_Swerve.resetOdometry(pathGroup.get(0).getInitialHolonomicPose())),
                new ParallelDeadlineGroup(
                        fullLeftSideAuto, 
                        new SequentialCommandGroup(
                                new WaitCommand(3.4),
                                new CubeIntakeSequence(s_intake, s_wheels))),
                new ReverseIntakeWheels(s_wheels, 0.5, IntakeConstants.kIntakeWheelHighSpeed),
                new LockWheels(s_Swerve),
                new WaitCommand(15));
    }
}