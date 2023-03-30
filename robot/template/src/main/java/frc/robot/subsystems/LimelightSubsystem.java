package frc.robot.subsystems;
import org.photonvision.PhotonUtils;

import edu.wpi.first.networktables.NetworkTable;
import edu.wpi.first.networktables.NetworkTableInstance;

import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.constants.VisionConstants;

public class LimelightSubsystem extends SubsystemBase{
    private double cameraYaw;
    private double cameraPitch;
    private boolean isTargetLow;
    private double cameraDistanceToTarget;
    private double horizontalDistance;
    private double cameraArea;

    private NetworkTable table;


    public LimelightSubsystem(){
        table = NetworkTableInstance.getDefault().getTable("limelight");

    }

    public void setResult(){
        if(table.getEntry("tv").getDouble(0) == 1){
            cameraYaw = table.getEntry("tx").getDouble(0);
            cameraPitch = table.getEntry("ty").getDouble(0);
            cameraArea = table.getEntry("ta").getDouble(0);
        }
    }

    public double getTargetYaw(){
        return Math.toRadians(cameraYaw);
    }

    public double getTargetPitch(){
        return Math.toRadians(cameraPitch);
    }

    public double getTargetDistance(){
        if(Math.abs(getTargetPitch()) < 0.3){
            cameraDistanceToTarget = PhotonUtils.calculateDistanceToTargetMeters(0, 
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

    public double strafeAlignDistance() {
        double driveDistance;
        driveDistance = Math.abs(Math.sin(getTargetYaw())) * getHorizontalDistanceToTarget();
        return driveDistance;
    }

    public boolean strafeDirection(){
        return cameraYaw > 0;
    }

    public boolean rotateFinished() {
        return false;
    }

    public double rotateAlign() {
        return getTargetYaw();
    }
}


