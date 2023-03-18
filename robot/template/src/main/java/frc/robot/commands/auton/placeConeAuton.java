package frc.robot.commands.auton;

import frc.robot.constants.ArmConstants;
import frc.robot.constants.TelescopeConstants;
import frc.robot.commands.clawpid.CloseClaw;
import frc.robot.commands.clawpid.OpenClaw;
import frc.robot.commands.telescope.ExtendTelescope;
import frc.robot.commands.telescope.RetractTelescope;
import frc.robot.commands.utilityCommands.TimerDeadline;
import frc.robot.subsystems.ArmSubsystem;
import frc.robot.subsystems.ClawSubsystem;
import frc.robot.subsystems.ClawSubsystemWithPID;
import frc.robot.subsystems.SwerveSubsystem;
import frc.robot.subsystems.TelescopeSubsystem;

import java.util.List;

import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.controller.ProfiledPIDController;
import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.math.trajectory.Trajectory;
import edu.wpi.first.math.trajectory.TrajectoryConfig;
import edu.wpi.first.math.trajectory.TrajectoryGenerator;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.ParallelCommandGroup;
import edu.wpi.first.wpilibj2.command.ParallelDeadlineGroup;
import edu.wpi.first.wpilibj2.command.SequentialCommandGroup;
import edu.wpi.first.wpilibj2.command.SwerveControllerCommand;
import edu.wpi.first.wpilibj2.command.WaitCommand;

public class placeConeAuton extends SequentialCommandGroup {
    public placeConeAuton(ClawSubsystemWithPID s_claw, TelescopeSubsystem s_telescope, ArmSubsystem s_arm){
        // TrajectoryConfig config =
        //     new TrajectoryConfig(
        //             Constants.AutoConstants.kMaxSpeedMetersPerSecond,
        //             Constants.AutoConstants.kMaxAccelerationMetersPerSecondSquared)
        //         .setKinematics(Constants.SwerveConstants.swerveKinematics);

        // // An example trajectory to follow.  All units in meters.
        // Trajectory exampleTrajectory =
        //     TrajectoryGenerator.generateTrajectory(
        //         // Start at the origin facing the +X direction
        //         new Pose2d(0, 0, new Rotation2d(0)),
        //         // Pass through these two interior waypoints, making an 's' curve path
        //         List.of(new Translation2d(1, 1), new Translation2d(2, -1)),
        //         // End 3 meters straight ahead of where we started, facing forward
        //         new Pose2d(3, 0, new Rotation2d(0)),
        //         config);

        // var thetaController =
        //     new ProfiledPIDController(
        //         Constants.AutoConstants.kPThetaController, 0, 0, Constants.AutoConstants.kThetaControllerConstraints);
        // thetaController.enableContinuousInput(-Math.PI, Math.PI);

        // SwerveControllerCommand swerveControllerCommand =
        //     new SwerveControllerCommand(
        //         exampleTrajectory,
        //         s_Swerve::getPose,
        //         Constants.SwerveConstants.swerveKinematics,
        //         new PIDController(Constants.AutoConstants.kPXController, 0, 0),
        //         new PIDController(Constants.AutoConstants.kPYController, 0, 0),
        //         thetaController,
        //         s_Swerve::setModuleStates,
        //         s_Swerve);


        addCommands
        (new ParallelCommandGroup
                (s_arm.setPosition(ArmConstants.kArmAutonPosition),
                    new SequentialCommandGroup(
                        new WaitCommand(1),
                        new ExtendTelescope(s_telescope,TelescopeConstants.kTelescopeExtendedMax), 
                        new ParallelDeadlineGroup(new TimerDeadline(0.5), new OpenClaw(s_claw)))
                            // wait time for opening claw
                            
                )
        );
    }
}