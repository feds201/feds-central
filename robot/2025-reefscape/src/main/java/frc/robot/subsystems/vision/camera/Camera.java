package frc.robot.subsystems.vision.camera;

import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.wpilibj2.command.Command;
import frc.robot.utils.ObjectType;
import frc.robot.utils.Subsystems;
import frc.robot.utils.VisionABC;
import frc.robot.utils.VisionObject;
import edu.wpi.first.networktables.GenericEntry;
import edu.wpi.first.networktables.NetworkTableEntry;

public class Camera extends VisionABC {
	private ObjectType object;
	public int lastseenAprilTag;
	public GenericEntry lastseentag_sim;
	
	public Camera(Subsystems vision, String networkTable, ObjectType objectType) {
		super(vision, networkTable);
		lastseenAprilTag = -1;
		object = objectType;
		lastseentag_sim =  tab.add("AprilTag"+ objectType.getName(), -1).getEntry();
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
	public void init() {
		// Implementation needed
	}

	@Override
	public void periodic() {
		lastseenAprilTag = GetAprilTag();
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
	 * @return the last seen AprilTag
	 */
	public int GetAprilTag() {
		NetworkTableEntry entry = object.getNetworkTable().getEntry("tid");
		if (entry.exists()) {
			return (int) entry.getDouble(0);
		}
		return lastseenAprilTag;
	}

	@Override 
	public String getName() {
		return  object.getTable();
	}

	public int getLastseenAprilTag() {
		return lastseenAprilTag;
	}
	

}