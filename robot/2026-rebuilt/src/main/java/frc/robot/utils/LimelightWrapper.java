package frc.robot.utils;

import static edu.wpi.first.units.Units.Celsius;

import limelight.Limelight;

public class LimelightWrapper extends Limelight{
    public LimelightWrapper(String limelightName){
        super(limelightName);
        SubsystemStatusManager.addSubsystem(limelightName, ()-> this.getNTTable().getTopic("tv").exists());
        DeviceTempReporter.addDevice(limelightName, ()-> Celsius.of(this.getNTTable().getEntry("hw").getDoubleArray(new Double[4])[3]));
    }


    
}
