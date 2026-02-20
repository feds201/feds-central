package frc.sim.core;

/**
 * Contact material properties for different surface types.
 * Used by PhysicsWorld to set per-collision friction and bounce.
 */
public class TerrainSurface {
    // Soft contacts: allow slight penetration to prevent jitter in ball clusters
    public static final TerrainSurface CARPET = new TerrainSurface(1.0, 0.1, 0.02, 0.5, 0.01);
    public static final TerrainSurface POLYCARBONATE = new TerrainSurface(0.4, 0.5, 0.2, 0.5, 0.01);
    public static final TerrainSurface RUBBER = new TerrainSurface(1.2, 0.6, 0.1, 0.5, 0.01);

    // Hard contacts: walls must be solid — no penetration allowed
    public static final TerrainSurface WALL = new TerrainSurface(0.8, 0.3, 0.1, 0.8, 0.0001);

    private final double friction;
    private final double bounce;
    private final double bounceVel;
    private final double softErp;
    private final double softCfm;

    /** Create a surface with default soft contact parameters. */
    public TerrainSurface(double friction, double bounce, double bounceVel) {
        this(friction, bounce, bounceVel, 0.5, 0.01);
    }

    /** Create a surface with explicit soft contact parameters. */
    public TerrainSurface(double friction, double bounce, double bounceVel,
                          double softErp, double softCfm) {
        this.friction = friction;
        this.bounce = bounce;
        this.bounceVel = bounceVel;
        this.softErp = softErp;
        this.softCfm = softCfm;
    }

    public double getFriction() { return friction; }
    public double getBounce() { return bounce; }
    public double getBounceVel() { return bounceVel; }
    public double getSoftErp() { return softErp; }
    public double getSoftCfm() { return softCfm; }
}
