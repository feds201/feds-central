package frc.robot.commands.auton;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.wpilibj2.command.CommandBase;

import java.util.ArrayList;
import java.util.HashMap;

import com.pathplanner.lib.PathConstraints;
import com.pathplanner.lib.PathPlanner;
import com.pathplanner.lib.PathPlannerTrajectory;
import com.pathplanner.lib.auto.PIDConstants;
import com.pathplanner.lib.auto.SwerveAutoBuilder;

import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.SequentialCommandGroup;
import edu.wpi.first.wpilibj2.command.WaitCommand;
import frc.robot.subsystems.SwerveSubsystem;
import frc.robot.commands.drive.BalanceWhileOn;
import frc.robot.commands.drive.LockWheels;
import frc.robot.constants.SwerveConstants;

public class BalancePath extends SequentialCommandGroup {
    public BalancePath(SwerveSubsystem s_Swerve) {
        addRequirements(s_Swerve);
        // This will load the file "FullAuto.path" and generate it with a max velocity
        // of 4 m/s and a max acceleration of 3 m/s^2
        // for every path in the group
        ArrayList<PathPlannerTrajectory> pathGroup = (ArrayList<PathPlannerTrajectory>) PathPlanner
                .loadPathGroup("Mid Score + Balance", new PathConstraints(0.5, 0.5));

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
                new PIDConstants(SwerveConstants.driveKP, SwerveConstants.driveKI, SwerveConstants.driveKD), // PID
                                                                                                             // constants
                                                                                                             // to
                                                                                                             // correct
                                                                                                             // for
                                                                                                             // translation
                                                                                                             // error
                                                                                                             // (used to
                                                                                                             // create
                                                                                                             // the X
                // and Y PID controllers)
                new PIDConstants(SwerveConstants.angleKP, SwerveConstants.angleKI, SwerveConstants.angleKD), // PID
                                                                                                             // constants
                                                                                                             // to
                                                                                                             // correct
                                                                                                             // for
                                                                                                             // rotation
                                                                                                             // error
                                                                                                             // (used to
                                                                                                             // create
                                                                                                             // the
                // rotation controller)
                s_Swerve::setModuleStates, // Module states consumer used to output to the drive subsystem
                eventMap,
                true, // Should the path be automatically mirrored depending on alliance color.
                      // Optional, defaults to true
                s_Swerve // The drive subsystem. Used to properly set the requirements of path following
                         // commands
        );

        Command balanceAuto = autoBuilder.fullAuto(pathGroup);

        addCommands(
                new InstantCommand(() -> s_Swerve.resetOdometry(pathGroup.get(0).getInitialHolonomicPose())),
                balanceAuto,
                new BalanceWhileOn(s_Swerve));
    }
}
