package frc.robot.subsystems;

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

    public void setFieldMode(){
        table.getEntry("ledMode").setNumber(1);
    }

    public void setResult(){
        if(table.getEntry("tv").getDouble(0) == 1){
            cameraYaw = table.getEntry("tx").getDouble(0);
            cameraPitch = table.getEntry("ty").getDouble(0);
            cameraArea = table.getEntry("ta").getDouble(0);
        }
    }

    public double getTargetYaw(){
        setResult();
        return Math.toRadians(cameraYaw);
    }

    public double getTargetPitch(){
        setResult();
        return Math.toRadians(cameraPitch);
    }

    public double getTargetDistance(){
        return (VisionConstants.limelightheight - VisionConstants.highTargetHeight) / (Math.cos((Math.PI/2) - getTargetPitch()));
    }

    public double getHorizontalDistanceToTarget(){
        return Math.tan((Math.PI/2) + getTargetPitch()) * (VisionConstants.limelightheight - VisionConstants.highTargetHeight);
    }

    @Override
    public void periodic() {
        {
            
        }
    }

    public double getStrafeAlignDistance() {
        double driveDistance;
        driveDistance = Math.sin(getTargetYaw()) * getHorizontalDistanceToTarget();
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


