package frc.sim.telemetry;

import edu.wpi.first.math.geometry.Pose3d;
import frc.sim.chassis.ChassisSimulation;

/**
 * Collects telemetry data from the simulation for publishing.
 * Actual NT publishing is done by the game-specific sim manager
 * that has access to the full WPILib runtime.
 */
public class SimTelemetry {
    private final ChassisSimulation chassis;
    private Pose3d[] componentPoses = new Pose3d[0];

    public SimTelemetry(ChassisSimulation chassis) {
        this.chassis = chassis;
    }

    /** Get the full 6DOF robot pose. */
    public Pose3d getRobotPose() {
        return chassis.getPose3d();
    }

    /** Set the current component poses for the articulated model. */
    public void setComponentPoses(Pose3d... poses) {
        this.componentPoses = poses;
    }

    /** Get the current component poses. */
    public Pose3d[] getComponentPoses() {
        return componentPoses;
    }
}
