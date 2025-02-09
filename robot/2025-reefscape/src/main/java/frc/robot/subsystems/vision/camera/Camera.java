package frc.robot.subsystems.vision.camera;

import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.wpilibj2.command.Command;
import frc.robot.utils.*;
import edu.wpi.first.networktables.GenericEntry;
import edu.wpi.first.networktables.NetworkTableEntry;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;


public class Camera extends VisionABC {
	private ObjectType object;
	public int lastseenAprilTag;
	public GenericEntry lastseentag_sim;
	private String limelightName;
	
	public Camera(Subsystems vision, String networkTable, ObjectType objectType, String limelightName) {
		super(vision, networkTable);
		lastseenAprilTag = -1;
		object = objectType;
		this.limelightName = limelightName;
		lastseentag_sim =  tab.add("AprilTag"+ objectType.getName(), -1).getEntry();
		controller = new PIDController(0,0,0);
		controller.setSetpoint(5);

		
		controller.calculate(10);
	}

	@Override
	public boolean CheckTarget() {
		// Implementation needed
		return false;
	}

	@Override
	public Translation2d GetTarget(VisionObject object) {
		// Implementation needed
		return null;
	}

	@Override
	public void setPipeline(int pipeline) {
		// Implementation needed
	}

	@Override
	public void setLEDMode(int mode) {
		// Implementation needed
	}

	@Override
	public void setCamMode(int mode) {
		// Implementation needed
	}

	@Override
	public Command BlinkLED() {
		// Implementation needed
		return null;
	}

	@Override
	public Command TurnOffLED() {
		// Implementation needed
		return null;
	}

	@Override
	public void simulationPeriodic() {
		lastseenAprilTag = (int)  lastseentag_sim.getDouble(-1);
	}


	@Override
	public void periodic() {
		// lastseenAprilTag = GetAprilTag();
		
	}

	@Override
	public void setDefaultCmd() {
		// Implementation needed
	}

	@Override
	public boolean isHealthy() {
		return true;
	}

	@Override
	public void Failsafe() {
	}

	/**
	 * Front_Camera is a subsystem that extends VisionABC and is responsible for
	 * handling
	 * vision processing related to the front camera of the robot. It primarily
	 * deals with
	 * detecting and processing AprilTags.
	 * 
	 * @return the primary april tag ID (if one is in view)
	 */
	public int GetAprilTag() {
		
		NetworkTableEntry entry = LimelightHelpers.getLimelightNTTableEntry(limelightName, "tid");
		if (entry.exists()) {
			SmartDashboard.putNumber("leftBumperTag", entry.getDouble(0));
			return (int) entry.getDouble(0);
		}
		return -1;
	}

	@Override 
	public String getName() {
		return  object.getTable();
	}

	public int getLastseenAprilTag() {
		return lastseenAprilTag;
	}


	
	public PoseAllocate getRobotPose() {
		LimelightHelpers.PoseEstimate pose = LimelightHelpers.getBotPoseEstimate(limelightName, "botpose_orb_wpiblue", true);
		if(pose!=null){
			double time = pose.timestampSeconds;
			return new PoseAllocate(pose, time);
		}
		return null;
	}

	public void SetRobotOrientation(double headingDeg, double yawRate, double pitch, double pitchRate, double roll, double rollRate) {
		LimelightHelpers.SetRobotOrientation(limelightName, headingDeg, yawRate, pitch, pitchRate, roll, rollRate);
	}

}