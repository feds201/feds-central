package frc.sim.vision;

import edu.wpi.first.math.geometry.Pose2d;

/**
 * Orchestrates simulated Limelight cameras.
 *
 * <p>Creates one {@link LimelightSim} per {@link CameraConfig} and forwards
 * the true sim pose to each camera every tick.
 */
public class VisionSimManager {

    private final LimelightSim[] cameras;

    /**
     * Create the vision sim manager with one simulated camera per config.
     *
     * @param configs camera configurations
     */
    public VisionSimManager(CameraConfig... configs) {
        cameras = new LimelightSim[configs.length];
        for (int i = 0; i < configs.length; i++) {
            cameras[i] = new LimelightSim(configs[i]);
        }
    }

    /**
     * Write the true pose to all simulated cameras' NT entries.
     *
     * @param truePose the ground-truth robot pose from MapleSim
     */
    public void update(Pose2d truePose) {
        for (LimelightSim camera : cameras) {
            camera.update(truePose);
        }
    }
}
