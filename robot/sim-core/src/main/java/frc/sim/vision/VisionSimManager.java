package frc.sim.vision;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Pose3d;
import edu.wpi.first.math.interpolation.TimeInterpolatableBuffer;
import edu.wpi.first.wpilibj.Timer;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Orchestrates simulated Limelight cameras.
 *
 * <p>Maintains a timestamped pose history buffer and forwards it to each
 * {@link LimelightSim} every tick. Each camera decides independently
 * whether to publish based on its own FPS.
 *
 * <p>Handles both AprilTag and game piece cameras. AprilTag cameras use
 * {@link #update(Pose2d)} for latency-aware pose publishing. Game piece
 * cameras use {@link #prepareGamePieces()} and {@link #updateGamePieces()}
 * around the physics step. Mode guards inside {@link LimelightSim} ensure
 * each camera only responds to the calls relevant to its mode.
 */
public class VisionSimManager {

    /** Pose history for latency lookback. 2s is plenty of headroom. */
    private final TimeInterpolatableBuffer<Pose2d> poseHistory =
            TimeInterpolatableBuffer.createBuffer(2.0);

    private final LimelightSim[] cameras;

    /**
     * Create the vision sim manager with pre-built camera instances.
     *
     * @param cameras simulated Limelight cameras (AprilTag and/or game piece mode)
     */
    public VisionSimManager(LimelightSim... cameras) {
        this.cameras = cameras;
    }

    /**
     * Record the true pose and let each camera decide whether to publish.
     * AprilTag cameras will publish; game piece cameras ignore this call.
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

    /**
     * Enable/disable game piece sensors based on FPS gating.
     * Must be called BEFORE {@code physicsWorld.step()}.
     * AprilTag cameras ignore this call.
     */
    public void prepareGamePieces() {
        for (LimelightSim camera : cameras) {
            camera.prepareGamePiece();
        }
    }

    /**
     * Read sensor contacts and publish game piece detection to NT.
     * Must be called AFTER {@code physicsWorld.step()}.
     * AprilTag cameras ignore this call.
     */
    public void updateGamePieces() {
        for (LimelightSim camera : cameras) {
            camera.updateGamePiece();
        }
    }

    /**
     * Compute direction lines for all cameras in field coordinates.
     *
     * @param robotPose the robot's current 3D pose in field coordinates
     * @return map of camera name to direction line (two-element Pose3d array)
     */
    public Map<String, Pose3d[]> getDirectionLines(Pose3d robotPose) {
        Map<String, Pose3d[]> lines = new LinkedHashMap<>();
        for (LimelightSim camera : cameras) {
            lines.put(camera.getName(), camera.getDirectionLine(robotPose));
        }
        return lines;
    }
}
