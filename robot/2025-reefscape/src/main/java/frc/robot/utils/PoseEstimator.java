package frc.robot.utils;

import edu.wpi.first.math.estimator.SwerveDrivePoseEstimator;
import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.kinematics.SwerveModulePosition;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;

public class PoseEstimator {
    SwerveDrivePoseEstimator poseEstimator;
    Rotation2d gyroAngle;
    SwerveModulePosition[] modulePositions;

    public PoseEstimator(CommandSwerveDrivetrain drivetrain) {
        gyroAngle = DrivetrainConstants.drivetrain.getState().Pose.getRotation();
        modulePositions = DrivetrainConstants.drivetrain.getState().ModulePositions;
        poseEstimator = new SwerveDrivePoseEstimator(DrivetrainConstants.drivetrain.getKinematics(), gyroAngle, modulePositions, new Pose2d(0, 0, gyroAngle));
    }

    public void updatePose() {
        poseEstimator.update(gyroAngle, modulePositions);
    }

}
