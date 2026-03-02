package frc.sim.vision;

/**
 * Hardware specs for each Limelight type.
 * Add future per-type values here (e.g. noise model params).
 */
public enum LimelightType {
    LL3(/* fps */ 30, /* latencyMs */ 25.0, /* hFovDeg */ 63.3, /* vFovDeg */ 49.7),
    LL4(/* fps */ 60, /* latencyMs */ 20.0, /* hFovDeg */ 82.0, /* vFovDeg */ 56.2);

    /** AprilTag pipeline frame rate. */
    public final int fps;

    /** Total latency in ms: capture + pipeline.
     *  https://www.chiefdelphi.com/t/determining-limelight-latency/411597 */
    public final double latencyMs;

    /** Horizontal field of view in degrees. */
    public final double horizontalFovDegrees;

    /** Vertical field of view in degrees. */
    public final double verticalFovDegrees;

    LimelightType(int fps, double latencyMs, double horizontalFovDegrees, double verticalFovDegrees) {
        this.fps = fps;
        this.latencyMs = latencyMs;
        this.horizontalFovDegrees = horizontalFovDegrees;
        this.verticalFovDegrees = verticalFovDegrees;
    }
}
