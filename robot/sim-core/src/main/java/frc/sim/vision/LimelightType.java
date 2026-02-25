package frc.sim.vision;

/**
 * Hardware type discriminator for Limelight cameras.
 *
 * <p>FPS values represent the AprilTag pipeline frame rate (not raw camera FPS).
 * These are conservative starting points — real hardware may run faster.
 */
public enum LimelightType {
    LL3(30),
    LL4(60);

    private final int fps;

    LimelightType(int fps) {
        this.fps = fps;
    }

    /** AprilTag pipeline frame rate (frames per second). */
    public int fps() {
        return fps;
    }
}
