package frc.robot.subsystems;

import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.Constants.VisionConstants;

import java.util.List;

import org.photonvision.*;
import org.photonvision.PhotonCamera;
import org.photonvision.targeting.PhotonPipelineResult;
import org.photonvision.targeting.PhotonTrackedTarget;

public class VisionSubsystem extends SubsystemBase {

    private PhotonCamera m_camera;
    private double cameraYaw;
    private double cameraPitch;
    private boolean isTargetLow;
    private PhotonPipelineResult result;
    private double distance;
    private double horizontalDistance;
    private PhotonTrackedTarget target;
    List<PhotonTrackedTarget> targets;

    /**
     * Constructor for the PhotonVision Vision Subsystem with a toggle for whether
     * the target is the lower of the middle or high targets.
     * 
     * @param isTargetLow
     */
    public VisionSubsystem(boolean isTargetLow) {
        m_camera = new PhotonCamera("limelightCamera");
        target = new PhotonTrackedTarget();
        this.isTargetLow = isTargetLow;
    }

    /**
     * Constructor for the PhotonVision Vision Subsystem by default looking at the
     * high target
     */
    public VisionSubsystem() {
        m_camera = new PhotonCamera("limelightCamera");
        target = new PhotonTrackedTarget();
        isTargetLow = true;
    }

    public void updateResultToLatest() {
        result = m_camera.getLatestResult();
    }

    public void setTargetLow(boolean isTargetLow) {
        this.isTargetLow = isTargetLow;
    }

    public boolean getHasTarget() {
        return result.hasTargets();
    }

    /**
     * Precondition: {@link #getHasTarget()} is true
     */
    public void updateTargetsToLatest() {
        targets = result.getTargets();
    }

    public void setTarget() {
        double maxArea = 0;
        double minArea = 100;
        for (int i = 1; i < targets.size(); i++) {
            if (isTargetLow) {
                target = targets.get(0);
                if (targets.get(i).getArea() > maxArea) {
                    target = targets.get(i);
                }
            } else {
                target = targets.get(0);
                if (targets.get(i).getArea() < minArea) {
                    target = targets.get(i);
                }
            }
        }
    }

    /**
     * @return cameraYaw in Radians
     */
    public double getTargetYaw() {
        cameraYaw = target.getYaw();
        cameraYaw = Math.toRadians(cameraYaw);
        return cameraYaw;
    }

    /**
     * @return cameraPitch in radians
     */
    public double getTargetPitch() {
        cameraPitch = target.getPitch();
        cameraPitch = Math.toRadians(cameraPitch);
        return cameraPitch;
    }

    public double getTargetDistance() {
        if (isTargetLow) {
            distance = PhotonUtils.calculateDistanceToTargetMeters(VisionConstants.limelightheight,
                    VisionConstants.lowTargetHeight,
                    VisionConstants.limelightPitchRadians,
                    getTargetPitch());
        } else {
            distance = PhotonUtils.calculateDistanceToTargetMeters(VisionConstants.limelightheight,
                    VisionConstants.highTargetHeight,
                    VisionConstants.limelightPitchRadians,
                    getTargetPitch());
        }
        return Math.sqrt(Math.pow(distance, 2) + Math.pow(VisionConstants.limelightToTopArmOffset, 2) -
                (2 * distance * VisionConstants.limelightToTopArmOffset
                        * Math.cos((Math.PI / 2) - (getTargetPitch() + VisionConstants.limelightPitchRadians))));
    }

    public double getHorizontalDistanceToTarget() {
        horizontalDistance = Math.cos(cameraPitch + getTargetPitch()) * distance;
        return horizontalDistance;
    }

    public void periodic() {
        SmartDashboard.putNumber("The Camera Yaw", getTargetYaw());
        SmartDashboard.putNumber("The Camera Pitch", getTargetYaw());
        SmartDashboard.putNumber("The Camera Horizontal Distance", getHorizontalDistanceToTarget());

    }

    public double strafeAlign() {
        double driveDistance;
        if (getTargetYaw() >= 0) {
            driveDistance = (Math.cos(90 - getTargetYaw()) * getHorizontalDistanceToTarget())
                    - VisionConstants.limelightOffset;
        } else {
            driveDistance = (Math.cos(90 - getTargetYaw()) * getHorizontalDistanceToTarget())
                    + VisionConstants.limelightOffset;
        }
        return driveDistance;
    }

    public boolean strafeFinished() {
        return (Math.cos(90 - getTargetYaw()) * getHorizontalDistanceToTarget()) == VisionConstants.limelightOffset;
    }

    public boolean rotateFinished() {
        return false;
    }

    public double rotateArmValue() {
        double sinRotateAngle = Math.sin((Math.PI / 2) - (getTargetPitch() + VisionConstants.limelightPitchRadians));
        return Math.asin(sinRotateAngle);
    }
}
