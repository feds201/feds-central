package frc.sim.vision;

import edu.wpi.first.math.geometry.Transform3d;

/**
 * Per-camera configuration for a simulated Limelight.
 *
 * <p>{@code type} and {@code robotToCamera} are stored for future use —
 * V0 writes exact pose so they don't affect output yet. When we add
 * real tag visibility checks, type determines FOV/noise model and
 * robotToCamera determines which tags the camera can actually see.
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
