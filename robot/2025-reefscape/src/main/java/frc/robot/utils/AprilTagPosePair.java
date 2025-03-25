package frc.robot.utils;

import edu.wpi.first.math.geometry.Pose2d;

public class AprilTagPosePair {
    public Pose2d redAlliance;
    public Pose2d blueAlliance;
    public Pose2d leftpose;
    public Pose2d rightpose;
    public Pose2d centerPose;


   
    public AprilTagPosePair(Pose2d redAlliance, Pose2d blueAlliance, Pose2d leftpose, Pose2d rightpose, Pose2d centerPose) {
        this.redAlliance = redAlliance;
        this.blueAlliance = blueAlliance;
        this.leftpose = leftpose;
        this.rightpose = rightpose;
        this.centerPose = centerPose;
    }
    
    public Pose2d getLeftPath() {
        return leftpose;
    }

    public Pose2d getRightPath() {
        return rightpose;
    }

    public Pose2d getCenterPath(){
        return centerPose;
    }

    public boolean poseToPath(Pose2d robotPose) {
        if (robotPose == redAlliance) {
            return true;
        } else if (robotPose == blueAlliance) {
            return true;
        } else {
            return false;
        }
    }

}