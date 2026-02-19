package frc.sim.gamepiece;

import edu.wpi.first.math.geometry.Pose3d;
import edu.wpi.first.math.geometry.Translation3d;
import frc.sim.core.PhysicsWorld;
import frc.sim.core.SimMath;
import frc.sim.core.TerrainSurface;
import org.ode4j.math.DVector3C;
import org.ode4j.ode.*;

import static org.ode4j.ode.OdeHelper.*;

/**
 * A game piece with ODE4J rigid body physics.
 * Supports sphere, cylinder, and box shapes.
 *
 * <p>Consumed pieces are moved to {@link #CONSUMED_Z} and detected via
 * {@link #isOffField()}. This uses Z position as the single source of truth —
 * if a piece is at z=-100 it is definitively off the field, with no risk of
 * a boolean flag and position getting out of sync.
 */
public class GamePiece {
    /** Z coordinate for consumed (off-field) pieces. */
    public static final double CONSUMED_Z = -100.0;

    /** Threshold for detecting consumed pieces — anything below this is off-field. */
    private static final double OFF_FIELD_Z_THRESHOLD = -50.0;

    public enum State {
        ON_FIELD,   // Free on the field, physics active
        IN_FLIGHT,  // Launched, physics active
        AT_REST     // Settled after flight (auto-disabled)
    }

    private final GamePieceConfig config;
    private State state;
    private final DBody body;
    private final DGeom geom;

    public GamePiece(PhysicsWorld world, GamePieceConfig config, double x, double y, double z) {
        this.config = config;
        this.state = State.ON_FIELD;

        body = OdeHelper.createBody(world.getWorld());
        body.setPosition(x, y, z);

        DMass mass = OdeHelper.createMass();

        switch (config.getShape()) {
            case SPHERE:
                geom = OdeHelper.createSphere(world.getSpace(), config.getRadius());
                mass.setSphereTotal(config.getMassKg(), config.getRadius());
                break;
            case CYLINDER:
                geom = OdeHelper.createCylinder(world.getSpace(), config.getRadius(), config.getLength());
                mass.setCylinderTotal(config.getMassKg(), 3, config.getRadius(), config.getLength());
                break;
            case BOX:
                geom = OdeHelper.createBox(world.getSpace(),
                        config.getRadius() * 2, config.getWidth(), config.getLength());
                mass.setBoxTotal(config.getMassKg(),
                        config.getRadius() * 2, config.getWidth(), config.getLength());
                break;
            default:
                throw new IllegalArgumentException("Unknown shape: " + config.getShape());
        }

        body.setMass(mass);
        geom.setBody(body);
        body.setAutoDisableFlag(true);

        // Set surface properties for this game piece
        world.setGeomSurface(geom, new TerrainSurface(config.getFriction(), config.getBounce(), 0.02));
    }

    /** Mark as consumed (removed from field by intake). Disables physics and moves off-field. */
    public void consume() {
        body.disable();
        body.setPosition(0, 0, CONSUMED_Z);
    }

    /** Launch the piece with a 3D velocity from a position. */
    public void launch(Translation3d position, Translation3d velocity) {
        state = State.IN_FLIGHT;
        body.setPosition(position.getX(), position.getY(), position.getZ());
        body.setLinearVel(velocity.getX(), velocity.getY(), velocity.getZ());
        body.setAngularVel(0, 0, 0);
        body.enable();
    }

    /** Update state based on whether the body has auto-disabled. */
    public void updateState() {
        if ((state == State.IN_FLIGHT || state == State.ON_FIELD) && !body.isEnabled()) {
            state = State.AT_REST;
        }
    }

    /** Get the 3D pose, or identity if consumed (off-field). */
    public Pose3d getPose3d() {
        if (isOffField()) return new Pose3d();
        return SimMath.odeToPose3d(body);
    }

    public Translation3d getPosition3d() {
        DVector3C pos = body.getPosition();
        return new Translation3d(pos.get0(), pos.get1(), pos.get2());
    }

    public GamePieceConfig getConfig() { return config; }
    public State getState() { return state; }
    public DBody getBody() { return body; }
    public DGeom getGeom() { return geom; }

    /**
     * Check if the piece has been consumed and moved off the field.
     * Uses Z position as the single source of truth: consumed pieces
     * are placed at {@link #CONSUMED_Z} by {@link #consume()}.
     */
    public boolean isOffField() {
        return body.getPosition().get2() < OFF_FIELD_Z_THRESHOLD;
    }

    /** Check if the piece is still active on the field (not consumed). */
    public boolean isActive() {
        return !isOffField();
    }
}
