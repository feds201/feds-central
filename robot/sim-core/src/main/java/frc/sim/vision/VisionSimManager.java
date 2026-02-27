package frc.sim.vision;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.interpolation.TimeInterpolatableBuffer;
import edu.wpi.first.wpilibj.Timer;

/**
 * Orchestrates simulated Limelight cameras.
 *
 * <p>Maintains a timestamped pose history buffer and forwards it to each
 * {@link LimelightSim} every tick. Each camera decides independently
 * whether to publish based on its own FPS.
 */
public class VisionSimManager {

    /** Pose history for latency lookback. 2s is plenty of headroom. */
    private final TimeInterpolatableBuffer<Pose2d> poseHistory =
            TimeInterpolatableBuffer.createBuffer(2.0);

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
     * Record the true pose and let each camera decide whether to publish.
     *
     * @param truePose the ground-truth robot pose from MapleSim
     */
    public void update(Pose2d truePose) {
        double now = Timer.getFPGATimestamp();
        poseHistory.addSample(now, truePose);

        for (LimelightSim camera : cameras) {
            camera.update(poseHistory, now);
        }
    }
}
