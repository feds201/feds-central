package frc.robot.subsystems;

import edu.wpi.first.wpilibj2.command.SubsystemBase;

import javax.xml.transform.Result;

import org.photonvision.*;
import org.photonvision.PhotonCamera;


public class Vision extends SubsystemBase{

    private PhotonCamera camera;
    private double cameraYaw;
    private double cameraPitch;
    private double cameraRoll;
    public Vision(){
        camera = new PhotonCamera("limelightCamera");
    }



    public double getYaw(){
        return cameraYaw;
    }

    public double getPitch(){
        return cameraPitch;
    }

    public double getCameraRoll(){
        return cameraRoll;
    }

    
}
