package frc.robot.subsystems;

import edu.wpi.first.wpilibj2.command.SubsystemBase;

import javax.xml.transform.Result;

import org.photonvision.*;
import org.photonvision.PhotonCamera;
import org.photonvision.targeting.PhotonPipelineResult;


public class Vision extends SubsystemBase{

    private PhotonCamera camera;
    private double cameraYaw;
    private double cameraPitch;
    private double [] target = new double[2];
    private PhotonPipelineResult result;
    private double cameraRoll;
    private double distance;
    public Vision(){
        camera = new PhotonCamera("limelightCamera");
        result = new PhotonPipelineResult(100, null);
    }


    public boolean hastarget(){
        return result.hasTargets();
    }

    public double [] getTarget(){
        return target;
    }

    public double getYaw(){
        return cameraYaw;
    }

    public double getPitch(){
        return cameraPitch;
    }

    public double getDistance(){
        return distance;
    }

    
}
