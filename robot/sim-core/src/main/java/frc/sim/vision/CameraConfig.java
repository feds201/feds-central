package frc.sim.vision;

import edu.wpi.first.math.geometry.Transform3d;

/**
 * Per-camera configuration for a simulated Limelight.
 *
 * <p>{@code type} provides hardware specs (FPS, latency, FOV) used for
 * publish timing, frustum construction, and future noise modeling.
 * {@code robotToCamera} provides the mount transform used for direction
 * line visualization, camera pose computation, and frustum attachment.
 *
 * @param name          NT table name, e.g. "limelight-two"
 * @param type          hardware type (LL3 or LL4)
 * @param robotToCamera mount position on robot
 */
public record CameraConfig(
        String name,
        LimelightType type,
        Transform3d robotToCamera) {
}
