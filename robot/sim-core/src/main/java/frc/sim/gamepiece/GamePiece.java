package frc.sim.gamepiece;

import edu.wpi.first.math.geometry.Pose3d;
import edu.wpi.first.math.geometry.Translation3d;
import frc.sim.core.PhysicsWorld;
import frc.sim.core.SimMath;
import frc.sim.core.TerrainSurface;
import org.ode4j.math.DVector3;
import org.ode4j.math.DVector3C;
import org.ode4j.ode.*;

import static org.ode4j.ode.OdeHelper.*;

public class GamePiece {
    public static final double CONSUMED_Z = -100.0;
    private static final double OFF_FIELD_Z_THRESHOLD = -50.0;
    private static final double NEAR_GROUND_Z = 0.3;

    // TODO: flight-physics constants shouldn't be hardcoded globals — different game pieces
    // have different drag, damping, and "in flight" thresholds. A smooth foam ball (2026 FUEL),
    // a hollow spongy torus (2024 NOTE), and a heavy hex disc all behave differently in the air
    // and on the ground. Move these onto GamePieceConfig (like mass/radius/bounce already are)
    // so each piece type can specify its own values. Today every piece uses the same numbers.
    private static final double GROUND_LINEAR_DAMPING = 0.05;
    private static final double GROUND_ANGULAR_DAMPING = 0.1;
    /** In-flight air drag (velocity-proportional). Only applied when airborne AND fast. */
    private static final double AIR_LINEAR_DAMPING = 0.005;
    /** Squared speed threshold above which a ball counts as "in flight". */
    private static final double FLIGHT_SPEED_THRESHOLD_SQ = 2.0 * 2.0;

    public enum State {
        ON_FIELD,
        IN_FLIGHT,
        AT_REST
    }

    private final GamePieceConfig config;
    private final PhysicsWorld physicsWorld;
    private State state;
    private DBody body;
    private DGeom geom;

    private double initialX;
    private double initialY;
    private double initialZ;

    public GamePiece(PhysicsWorld world, GamePieceConfig config, double x, double y, double z) {
        this.physicsWorld = world;
        this.config = config;
        this.state = State.ON_FIELD;
        this.initialX = x;
        this.initialY = y;
        this.initialZ = z;
    }

    public boolean hasPhysics() {
        return body != null;
    }

    public void initializePhysics() {
        if (hasPhysics()) return;

        body = OdeHelper.createBody(physicsWorld.getWorld());
        body.setPosition(initialX, initialY, initialZ);

        DMass mass = OdeHelper.createMass();

        switch (config.getShape()) {
            case SPHERE:
                geom = OdeHelper.createSphere(physicsWorld.getSpace(), config.getRadius());
                mass.setSphereTotal(config.getMassKg(), config.getRadius());
                break;
            case CYLINDER:
                geom = OdeHelper.createCylinder(physicsWorld.getSpace(), config.getRadius(), config.getLength());
                mass.setCylinderTotal(config.getMassKg(), 3, config.getRadius(), config.getLength());
                break;
            case BOX:
                geom = OdeHelper.createBox(physicsWorld.getSpace(),
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

        physicsWorld.setGeomSurface(geom, new TerrainSurface(config.getFriction(), config.getBounce(), 0.02));
    }

    public void consume() {
        initialZ = CONSUMED_Z;
        if (hasPhysics()) {
            body.disable();
            body.setPosition(0, 0, CONSUMED_Z);
        }
    }

    public void launch(Translation3d position, Translation3d velocity) {
        launch(position, velocity, new DVector3(0, 0, 0));
    }

    public void launch(Translation3d position, Translation3d velocity, DVector3 angularVelocity) {
        state = State.IN_FLIGHT;
        initialX = position.getX();
        initialY = position.getY();
        initialZ = position.getZ();
        if (!hasPhysics()) {
            initializePhysics();
        }
        body.setPosition(position.getX(), position.getY(), position.getZ());
        body.setLinearVel(velocity.getX(), velocity.getY(), velocity.getZ());
        body.setAngularVel(angularVelocity.get0(), angularVelocity.get1(), angularVelocity.get2());
        body.setLinearDamping(0);
        body.setAngularDamping(0);
        body.enable();
    }

    public void updateState() {
        if (!hasPhysics()) return;
        if ((state == State.IN_FLIGHT || state == State.ON_FIELD) && !body.isEnabled()) {
            state = State.AT_REST;
        }

        if (body.isEnabled() && !isOffField()) {
            if (body.getPosition().get2() < NEAR_GROUND_Z) {
                body.setLinearDamping(GROUND_LINEAR_DAMPING);
                body.setAngularDamping(GROUND_ANGULAR_DAMPING);
            } else {
                // Airborne: apply air drag only when moving fast enough to be "in flight".
                // Keeps slow-drifting balls cheap and doesn't nudge floating-during-collision cases.
                // Angular damping stays 0 so any spin persists through the shot.
                body.setLinearDamping(isInFlight() ? AIR_LINEAR_DAMPING : 0);
                body.setAngularDamping(0);
            }
        }
    }

    /** True when the ball is airborne AND moving fast enough for flight-physics (eg drag) to matter. */
    public boolean isInFlight() {
        if (!hasPhysics() || !body.isEnabled()) return false;
        if (body.getPosition().get2() < NEAR_GROUND_Z) return false;
        DVector3C v = body.getLinearVel();
        double speed2 = v.get0() * v.get0() + v.get1() * v.get1() + v.get2() * v.get2();
        return speed2 >= FLIGHT_SPEED_THRESHOLD_SQ;
    }

    public Pose3d getPose3d() {
        if (isOffField()) return new Pose3d();
        if (!hasPhysics()) return new Pose3d(new Translation3d(initialX, initialY, initialZ), new edu.wpi.first.math.geometry.Rotation3d());
        return SimMath.odeToPose3d(body);
    }

    public Translation3d getPosition3d() {
        if (!hasPhysics()) return new Translation3d(initialX, initialY, initialZ);
        DVector3C pos = body.getPosition();
        return new Translation3d(pos.get0(), pos.get1(), pos.get2());
    }

    public GamePieceConfig getConfig() { return config; }
    public State getState() { return state; }

    public DBody getBody() {
        if (!hasPhysics()) initializePhysics();
        return body;
    }

    public DGeom getGeom() {
        if (!hasPhysics()) initializePhysics();
        return geom;
    }

    public boolean isOffField() {
        if (!hasPhysics()) return initialZ < OFF_FIELD_Z_THRESHOLD;
        return body.getPosition().get2() < OFF_FIELD_Z_THRESHOLD;
    }

    public boolean isActive() {
        return !isOffField();
    }
}
