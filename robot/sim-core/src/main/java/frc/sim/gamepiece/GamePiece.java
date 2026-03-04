package frc.sim.gamepiece;

import edu.wpi.first.math.geometry.Pose3d;
import edu.wpi.first.math.geometry.Translation3d;
import frc.sim.core.PhysicsWorld;
import frc.sim.core.SimMath;
import frc.sim.core.TerrainSurface;
import org.ode4j.math.DVector3C;
import org.ode4j.ode.*;

import static org.ode4j.ode.OdeHelper.*;

public class GamePiece {
    public static final double CONSUMED_Z = -100.0;
    private static final double OFF_FIELD_Z_THRESHOLD = -50.0;
    private static final double NEAR_GROUND_Z = 0.3;
    private static final double GROUND_LINEAR_DAMPING = 0.05;
    private static final double GROUND_ANGULAR_DAMPING = 0.1;

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
        return body != null && geom != null;
    }

    public void initializePhysics() {
        if (hasPhysics()) return;

        DBody newBody = OdeHelper.createBody(physicsWorld.getWorld());
        newBody.setPosition(initialX, initialY, initialZ);

        DMass mass = OdeHelper.createMass();
        DGeom newGeom;

        switch (config.getShape()) {
            case SPHERE:
                newGeom = OdeHelper.createSphere(physicsWorld.getSpace(), config.getRadius());
                mass.setSphereTotal(config.getMassKg(), config.getRadius());
                break;
            case CYLINDER:
                newGeom = OdeHelper.createCylinder(physicsWorld.getSpace(), config.getRadius(), config.getLength());
                mass.setCylinderTotal(config.getMassKg(), 3, config.getRadius(), config.getLength());
                break;
            case BOX:
                newGeom = OdeHelper.createBox(physicsWorld.getSpace(),
                        config.getRadius() * 2, config.getWidth(), config.getLength());
                mass.setBoxTotal(config.getMassKg(),
                        config.getRadius() * 2, config.getWidth(), config.getLength());
                break;
            default:
                newBody.destroy();
                throw new IllegalArgumentException("Unknown shape: " + config.getShape());
        }

        newBody.setMass(mass);
        newGeom.setBody(newBody);
        newBody.setAutoDisableFlag(true);

        physicsWorld.setGeomSurface(newGeom, new TerrainSurface(config.getFriction(), config.getBounce(), 0.02));

        // Assign fields only after successful creation
        this.body = newBody;
        this.geom = newGeom;
    }

    public void consume() {
        initialZ = CONSUMED_Z;
        if (hasPhysics()) {
            body.disable();
            body.setPosition(0, 0, CONSUMED_Z);
        }
    }

    public void launch(Translation3d position, Translation3d velocity) {
        state = State.IN_FLIGHT;
        initialX = position.getX();
        initialY = position.getY();
        initialZ = position.getZ();
        if (!hasPhysics()) {
            initializePhysics();
        }
        body.setPosition(position.getX(), position.getY(), position.getZ());
        body.setLinearVel(velocity.getX(), velocity.getY(), velocity.getZ());
        body.setAngularVel(0, 0, 0);
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
                body.setLinearDamping(0);
                body.setAngularDamping(0);
            }
        }
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
        if (!hasPhysics()) {
            throw new IllegalStateException("Physics is not initialized for this GamePiece; call initializePhysics() or check hasPhysics() before accessing the body.");
        }
        return body;
    }

    public DGeom getGeom() {
        if (!hasPhysics()) {
            throw new IllegalStateException("Physics is not initialized for this GamePiece; call initializePhysics() or check hasPhysics() before accessing the geom.");
        }
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
