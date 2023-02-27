package frc.robot.subsystems;

import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.geometry.Transform3d;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.Constants.VisionConstants;

import java.util.List;

import javax.xml.transform.Result;

import org.photonvision.*;
import org.photonvision.PhotonCamera;
import org.photonvision.targeting.PhotonPipelineResult;
import org.photonvision.targeting.PhotonTrackedTarget;


public class VisionSubsystem extends SubsystemBase{

    private PhotonCamera camera;
    private double cameraYaw;
    private double cameraPitch;
    private boolean isTargetLow;
    private PhotonPipelineResult result;
    private double distance;
    private double horizontalDistance;
    private PhotonTrackedTarget target;
    List<PhotonTrackedTarget> targets;
   
    public VisionSubsystem(boolean isTargetLow){
        camera = new PhotonCamera("limelightCamera");
        target = new PhotonTrackedTarget();
        this.isTargetLow = isTargetLow;
    }

    public void getResult(){
        result = camera.getLatestResult();
    }

    public boolean hasTarget(){
        return result.hasTargets();
    }

    public void setTargets(){
        if(hasTarget()){
            targets = result.getTargets();
        }
        else{
            targets = null;
        }
    }

    public void setTarget(){
        double maxArea = 0;
        double minArea = 100;
        for(int i = 1; i<targets.size(); i++){
            if(isTargetLow){
                target = targets.get(0);
                if(targets.get(i).getArea() > maxArea){
                    target = targets.get(i);
                }
            }
            else{
                target = targets.get(0);
                if(targets.get(i).getArea() < minArea){
                    target = targets.get(i);
                }
            }
        }
    }

    public double getTargetYaw(){
        cameraYaw = target.getYaw();
        cameraYaw = Math.toRadians(cameraYaw);
        return cameraYaw;
    }

    public double getTargetPitch(){
        cameraPitch = target.getPitch();
        cameraPitch = Math.toRadians(cameraPitch);
        return cameraPitch;
    }

    public double getTargetDistance(){
        if(isTargetLow){
            distance = PhotonUtils.calculateDistanceToTargetMeters(VisionConstants.limelightheight, 
                                                                VisionConstants.lowTargetHeight, 
                                                                VisionConstants.limelightPitchRadians,
                                                                getTargetPitch()); 
        }
        else{
            distance = PhotonUtils.calculateDistanceToTargetMeters(VisionConstants.limelightheight, 
                                                                VisionConstants.highTargetHeight, 
                                                                VisionConstants.limelightPitchRadians,
                                                                getTargetPitch());    
        }       
        return distance; 
    }

    public double getHorizontalDistanceToTarget(){
        horizontalDistance = Math.cos(cameraPitch + getTargetPitch()) * distance;
        return horizontalDistance;
    }

    public void periodic(){
        SmartDashboard.putNumber("The Camera Yaw", getTargetYaw());
        SmartDashboard.putNumber("The Camera Pitch", getTargetYaw());
        SmartDashboard.putNumber("The Camera Horizontal Distance", getHorizontalDistanceToTarget());
        
    }

    public void strafeAlign(){
        double driveDistance;
        if(getTargetYaw()>=0){
           driveDistance = (Math.cos(90-getTargetYaw()) * getHorizontalDistanceToTarget()) - VisionConstants.limelightOffset;
        }
        else{
            driveDistance = (Math.cos(90-getTargetYaw()) * getHorizontalDistanceToTarget()) + VisionConstants.limelightOffset;            
        }
    }
    
    public void rotateToTarget(){

    }

    public boolean strafeFinished(){
        return (Math.cos(90-getTargetYaw()) * getHorizontalDistanceToTarget()) == VisionConstants.limelightOffset;
    }

    public boolean rotateFinished(){
        return false;
    }

    public double rotateArmValue(){
        return VisionConstants.degreesToEncoderCounts * (getTargetPitch() + VisionConstants.limelightPitchRadians + 90);
    }
}
