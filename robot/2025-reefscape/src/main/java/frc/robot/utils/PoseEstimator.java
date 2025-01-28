package frc.robot.utils;

import edu.wpi.first.math.estimator.SwerveDrivePoseEstimator;
import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.kinematics.SwerveModulePosition;
import edu.wpi.first.networktables.NetworkTable;
import edu.wpi.first.networktables.NetworkTableInstance;
import edu.wpi.first.networktables.StructPublisher;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;

public class PoseEstimator {

    /* What to publish over networktables for telemetry */
    private final NetworkTableInstance inst = NetworkTableInstance.getDefault();

    /* Robot swerve drive state */
    private final NetworkTable driveStateTable = inst.getTable("DriveState");
    private final StructPublisher<Pose2d> EstimatorPose = driveStateTable.getStructTopic("EstimatorPose", Pose2d.struct).publish();


    SwerveDrivePoseEstimator poseEstimator;
    Rotation2d gyroAngle;
    SwerveModulePosition[] modulePositions;

    public PoseEstimator(CommandSwerveDrivetrain drivetrain) {
        gyroAngle = DrivetrainConstants.drivetrain.getState().Pose.getRotation();
        modulePositions = DrivetrainConstants.drivetrain.getState().ModulePositions;
        poseEstimator = new SwerveDrivePoseEstimator(DrivetrainConstants.drivetrain.getKinematics(), gyroAngle, null, new Pose2d(0, 0, gyroAngle));
    }

    public void updatePose() {
        poseEstimator.update(gyroAngle, modulePositions);
        EstimatorPose.set(poseEstimator.getEstimatedPosition());
    }

}
