package frc.sim.vision;

/**
 * Hardware specs for each Limelight type.
 * Add future per-type values here (e.g. hFovDeg, vFovDeg, noise model params).
 */
public enum LimelightType {
    LL3(30, 25.0),
    LL4(60, 20.0);

    /** AprilTag pipeline frame rate. */
    public final int fps;

    /** Total latency in ms: capture + pipeline.
     *  https://www.chiefdelphi.com/t/determining-limelight-latency/411597 */
    public final double latencyMs;

    LimelightType(int fps, double latencyMs) {
        this.fps = fps;
        this.latencyMs = latencyMs;
    }
}
