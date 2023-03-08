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
    private double cameraDistanceToTarget;
    private double horizontalDistance;
    private PhotonTrackedTarget target;
    List<PhotonTrackedTarget> targets;

    /**
     * Constructor for the PhotonVision Vision Subsystem by default looking at the
     * high target
     */
    public VisionSubsystem() {
        m_camera = new PhotonCamera("limelightCamera");
        target = new PhotonTrackedTarget();
        //isTargetLow = true;
    }

    public void updateResultToLatest() {
        result = m_camera.getLatestResult();
    }

    public boolean hasTarget() {
        if (result != null) {
            return result.hasTargets();
        }
        return false;
    }

    public void updateTargetsToLatest() {
        if(hasTarget()){
            targets = result.getTargets();
        }
    }

    public void setTarget(){
        target = result.getBestTarget();
    }
    public void setTarget(boolean isTargetLow) {
        if(!hasTarget()){
            return;
        }
        this.isTargetLow = isTargetLow;
        double pitch = targets.get(0).getPitch();
        for (int i = 1; i < targets.size(); i++) {
            if (this.isTargetLow) {
                if (targets.get(i).getPitch() < pitch) {
                    target = targets.get(i);
                }
            } else {
                if (targets.get(i).getPitch() > pitch) {
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

    public double getTargetDistance(boolean isTargetLow){
        if(isTargetLow){
            cameraDistanceToTarget = PhotonUtils.calculateDistanceToTargetMeters(VisionConstants.limelightheight, 
                                                                VisionConstants.lowTargetHeight, 
                                                                VisionConstants.limelightPitchRadians,
                                                                getTargetPitch()); 
        }
        else{
            cameraDistanceToTarget = PhotonUtils.calculateDistanceToTargetMeters(VisionConstants.limelightheight, 
                                                                VisionConstants.highTargetHeight, 
                                                                VisionConstants.limelightPitchRadians,
                                                                getTargetPitch());    
        }
        
        
        return cameraDistanceToTarget;
    }
    
    public double getTargetDistance(){
        if(targets.size() == 1){
            cameraDistanceToTarget = PhotonUtils.calculateDistanceToTargetMeters(VisionConstants.limelightheight, 
                                                                VisionConstants.lowTargetHeight, 
                                                                VisionConstants.limelightPitchRadians,
                                                                getTargetPitch());
        }
        else{
            cameraDistanceToTarget = PhotonUtils.calculateDistanceToTargetMeters(VisionConstants.limelightheight, 
                                                                VisionConstants.highTargetHeight, 
                                                                VisionConstants.limelightPitchRadians,
                                                                getTargetPitch());   
        }
        
        return cameraDistanceToTarget;
    }

    public double getHorizontalDistanceToTarget(){
        horizontalDistance = Math.cos(cameraPitch + getTargetPitch()) * getTargetDistance();
        return horizontalDistance;
    }

    @Override
    public void periodic() {
        {
            
        }
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
        return getTargetYaw() == 0;
    }

    public double rotateAlign() {
        return getTargetYaw();
    }
}
