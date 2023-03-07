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

    public boolean getHasTarget() {
        if (result != null) {
            return result.hasTargets();
        }
        return false;
    }

    /**
     * Precondition: {@link #getHasTarget()} is true
     */
    public void updateTargetsToLatest() {
        if(getHasTarget()){
            targets = result.getTargets();
        }
    }

    public void setTarget(){
        target = result.getBestTarget();
    }
    public void setTarget(boolean isTargetLow) {
        
        this.isTargetLow = isTargetLow;
        double maxArea = 0;
        double minArea = 100;
        for (int i = 1; i < targets.size(); i++) {
            if (this.isTargetLow) {
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
        
        // This is the law of cosines
        // C^2 = A^2 + B^2 - 2*A*Bcos(theta)
        //double cameraDistanceToTargetSquared = Math.pow(cameraDistanceToTarget, 2); // this is A^2
        //double limelightToArmRotateAxisSquared = Math.pow(VisionConstants.limelightToTopArmOffset, 2); // this is B^2
        //double theta = Math.PI / 2 - getTargetPitch() - VisionConstants.limelightPitchRadians;
    
        //                        A^2                        +              B^2                - 2 *             A          *                        B                *     cos(theta)                      
        //double rightHandSide = cameraDistanceToTargetSquared + limelightToArmRotateAxisSquared - 2 * cameraDistanceToTarget * VisionConstants.limelightToTopArmOffset * Math.cos(theta);

        // C = sqrt(rightHandSize)
        //return Math.sqrt(rightHandSide);
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
        // This is the law of cosines
        // C^2 = A^2 + B^2 - 2*A*Bcos(theta)
        //double cameraDistanceToTargetSquared = Math.pow(cameraDistanceToTarget, 2); // this is A^2
        //double limelightToArmRotateAxisSquared = Math.pow(VisionConstants.limelightToTopArmOffset, 2); // this is B^2
        //double theta = Math.PI / 2 - getTargetPitch() - VisionConstants.limelightPitchRadians;
    
        //                        A^2                        +              B^2                - 2 *             A          *                        B                *     cos(theta)                      
        //double rightHandSide = cameraDistanceToTargetSquared + limelightToArmRotateAxisSquared - 2 * cameraDistanceToTarget * VisionConstants.limelightToTopArmOffset * Math.cos(theta);

        // C = sqrt(rightHandSize)
        //return Math.sqrt(rightHandSide);
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
