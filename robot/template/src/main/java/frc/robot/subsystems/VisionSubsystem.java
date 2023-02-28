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
    private double cameraToTargetDistance;
    private double horizontalDistance;
    private PhotonTrackedTarget target;
    List<PhotonTrackedTarget> targets;
   
    public VisionSubsystem(boolean isTargetLow){
        camera = new PhotonCamera("limelightCamera");
        target = new PhotonTrackedTarget();
        this.isTargetLow = isTargetLow;
    }

    public VisionSubsystem(){
        camera = new PhotonCamera("limelightCamera");
        target = new PhotonTrackedTarget();
        isTargetLow = true;
    }

    public void getResult(){
        result = camera.getLatestResult();
    }

    public void setTargetHeight(boolean isTargetLow){
        this.isTargetLow = isTargetLow;
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
        //This first part sets distace equal to the
        if(isTargetLow){
            cameraToTargetDistance = PhotonUtils.calculateDistanceToTargetMeters(VisionConstants.limelightheight, 
                                                                VisionConstants.lowTargetHeight, 
                                                                VisionConstants.limelightPitchRadians,
                                                                getTargetPitch()); 
        }
        else{
            cameraToTargetDistance = PhotonUtils.calculateDistanceToTargetMeters(VisionConstants.limelightheight, 
                                                                VisionConstants.highTargetHeight, 
                                                                VisionConstants.limelightPitchRadians,
                                                                getTargetPitch());    
        }  
        //Uses law of Cosines to get the distance from arm rotation point to the target     
        return Math.sqrt(Math.pow(cameraToTargetDistance,2) + Math.pow(VisionConstants.limelightToTopArmOffset, 2) - 
        (2 * cameraToTargetDistance * VisionConstants.limelightToTopArmOffset * Math.cos((Math.PI / 2) - (getTargetPitch() + VisionConstants.limelightPitchRadians))));
    }

    public double getHorizontalDistanceToTarget(){
        horizontalDistance = Math.cos(cameraPitch + getTargetPitch()) * cameraToTargetDistance;
        return horizontalDistance;
    }

    public void periodic(){
        SmartDashboard.putNumber("The Camera Yaw", getTargetYaw());
        SmartDashboard.putNumber("The Camera Pitch", getTargetYaw());
        SmartDashboard.putNumber("The Camera Horizontal Distance", getHorizontalDistanceToTarget());
        
    }

    public double strafeAlign(){
        double driveDistance;
        if(getTargetYaw()>=0){
           driveDistance = (Math.cos(90-getTargetYaw()) * getHorizontalDistanceToTarget()) - VisionConstants.limelightOffset;
        }
        else{
            driveDistance = (Math.cos(90-getTargetYaw()) * getHorizontalDistanceToTarget()) + VisionConstants.limelightOffset;            
        }
        return driveDistance;
    }

    public boolean strafeFinished(){
        return (Math.cos(90-getTargetYaw()) * getHorizontalDistanceToTarget()) == VisionConstants.limelightOffset;
    }

    public boolean rotateFinished(){
        return false;
    }

    public double rotateArmValue(){

        double sinRotateAngle = Math.sin((Math.PI / 2) - (getTargetPitch() + VisionConstants.limelightPitchRadians));
        return Math.asin(sinRotateAngle);
    }
}
