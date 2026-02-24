package frc.robot.utils;

import static edu.wpi.first.units.Units.Celsius;
import static edu.wpi.first.units.Units.DegreesPerSecond;
import static edu.wpi.first.units.Units.RadiansPerSecond;

import java.util.Optional;

import edu.wpi.first.math.Matrix;
import edu.wpi.first.math.VecBuilder;
import edu.wpi.first.math.numbers.N1;
import edu.wpi.first.math.numbers.N3;
import edu.wpi.first.math.util.Units;
import frc.robot.RobotMap.VisionConstants;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import limelight.Limelight;
import limelight.networktables.AngularVelocity3d;
import limelight.networktables.Orientation3d;

public class LimelightWrapper extends Limelight{
    public LimelightWrapper(String limelightName){
        super(limelightName);
        SubsystemStatusManager.addSubsystem(limelightName, ()-> this.getNTTable().getTopic("tv").exists());
        DeviceTempReporter.addDevice(limelightName, ()-> Celsius.of(this.getNTTable().getEntry("hw").getDoubleArray(new Double[4])[3]));
    }

  /**
   * Retrieve estimated standard deviations for a Megatag 1 estimate
   * @param poseEstimate the pose estimate from the limelight
   * @param isLL4 True if limelight is a limelight 4, false otherwise
   * @return the estimated standard deviations
   */
  public Matrix<N3, N1> getMegaTag1StdDevs(limelight.networktables.PoseEstimate poseEstimate, boolean isLL4){
    var estStdDevs = VisionConstants.MT1_STDDEV;

    // Calculate the number of tags, average distance and average ambiguity
    int numTags = 0; 
    double avgDist = 0;
    double avgAmbiguity = 0;
    for(var value : poseEstimate.rawFiducials){ // Loop through all the tags detected
      numTags++;
      avgDist += value.distToCamera;
      avgAmbiguity += value.ambiguity;
    }

    // if no tags detected return single tag std devs
    if (numTags == 0) {
      return estStdDevs;
    }

    // Calculate the averages
    avgDist /= numTags;
    avgAmbiguity /= numTags;

    // Decrease std devs if limelight is LL4
    if (isLL4){
        estStdDevs = estStdDevs.times(.8);
    }

    // If the average ambiguity is too high, return very high std devs to ignore the pose
    if (avgAmbiguity > 0.7) {
      return VecBuilder.fill(Double.MAX_VALUE, Double.MAX_VALUE, Double.MAX_VALUE);
    }

    // Scale the standard deviations based on the average ambiguity
    estStdDevs = estStdDevs.times((1 + avgAmbiguity) * 5);
    
    // If the average distance is too far, return very high std devs to ignore the pose
    if (numTags == 1 && avgDist > 2) {
      estStdDevs = VecBuilder.fill(Double.MAX_VALUE, Double.MAX_VALUE, Double.MAX_VALUE);
    }else{ // Scale the standard deviations based on the average distance
      estStdDevs = estStdDevs.times(1 + (avgDist * avgDist/30));
    }

    return estStdDevs;
  }

  /**
   * Retrieve estimated standard deviations for a Megatag 2 estimate
   * @param poseEstimate the pose estimate from the limelight
   * @param isLL4 True if limelight is a limelight 4, false otherwise
   * @return the estimated standard deviations
   */
  public static Matrix<N3, N1> getEstimationStdDevsLimelightMT2(limelight.networktables.PoseEstimate poseEstimate, boolean isLL4) {
    var estStdDevs =VisionConstants.MT2_STDDEV;
    
    int numTags = 0;
    double avgDist = 0;
    for (var value : poseEstimate.rawFiducials) {
        numTags++;
        avgDist += value.distToCamera;
    }

    if (numTags == 0) {
        return estStdDevs;
    }

    avgDist /= numTags;

    // Decrease std devs if multiple targets are visible
    if (numTags > 1) {
        estStdDevs = estStdDevs.times(0.65);
    }

    // Decrease std devs if limelight is LL4
    if (isLL4){
        estStdDevs = estStdDevs.times(.8);
    }

    // Increase std devs based on (average) distance
    if (numTags == 1 && avgDist > 5) {
        estStdDevs = VecBuilder.fill(Double.MAX_VALUE, Double.MAX_VALUE, Double.MAX_VALUE);
    } else {
        estStdDevs = estStdDevs.times(1 + (avgDist * avgDist * 5));
    }

    return estStdDevs;
}

/**
 * Update a localization-focused limelight (meant to be called each periodic loop)
 * @param ll Limelight to update
 * @param isLL4 True if limelight is a limelight 4, false otherwise
 * @param drivetrain Robot drivetrain
 */
public static void updateLocalizationLimelight(LimelightWrapper ll, boolean isLL4, CommandSwerveDrivetrain drivetrain){
    // ll.getSettings()
    //     .withRobotOrientation(new Orientation3d(drivetrain.getRotation3d(),
    //         new AngularVelocity3d(RadiansPerSecond.of(drivetrain.getState().Speeds.omegaRadiansPerSecond),
    //             DegreesPerSecond.of(0),
    //             DegreesPerSecond.of(0))))
    //     .save();

    // // Get MegaTag2 pose
    // Optional<limelight.networktables.PoseEstimate> visionEstimate = ll.createPoseEstimator(EstimationMode.MEGATAG2).getPoseEstimate();
    // // If the pose is present
    // visionEstimate.ifPresent((limelight.networktables.PoseEstimate poseEstimate) -> {
    //     // And we see >0 tags and robot rotates <2 rotations per second
    //     if(poseEstimate.tagCount > 0 &&  Math.abs(Units.radiansToRotations(drivetrain.getState().Speeds.omegaRadiansPerSecond)) < 2){
    //         // Add it to the pose estimator.
    //         drivetrain.addVisionMeasurement(poseEstimate.pose.toPose2d(), poseEstimate.timestampSeconds, LimelightWrapper.getEstimationStdDevsLimelightMT2(poseEstimate, isLL4));
    //     }
    // });
}

    
}
