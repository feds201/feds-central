package frc.sim.core;

import de.javagl.obj.Obj;
import de.javagl.obj.ObjReader;
import de.javagl.obj.ObjUtils;
import org.ode4j.math.DVector3;
import org.ode4j.math.DVector3C;
import org.ode4j.ode.*;

import java.io.IOException;
import java.io.InputStream;
import java.util.*;
import java.util.function.BiConsumer;

import static org.ode4j.ode.OdeHelper.*;

/**
 * Wraps ODE4J's rigid body dynamics world for the simulation framework.
 * Provides gravity, ground plane, collision detection, stepping, and
 * field mesh loading.
 *
 * <p>Z-up coordinate system matching WPILib/AdvantageScope.
 *
 * <p>Each simulation creates its own instance. However, the ODE4J native
 * library is initialized once globally via a static flag (ODE4J requires
 * exactly one {@code initODE2()} call per process).
 */
public class PhysicsWorld {
    private final DWorld world;
    private final DSpace space;
    private final DJointGroup contactGroup;
    private final DGeom groundPlane;

    // Default contact parameters
    private TerrainSurface defaultSurface = TerrainSurface.CARPET;
    private int maxContacts = 6;

    // Per-geom surface overrides
    private final Map<DGeom, TerrainSurface> geomSurfaces = new HashMap<>();

    // Geoms whose traction is handled by an external tire model (e.g., MapleSim).
    // These get near-zero friction (0.01) against the ground plane only, so ODE4J
    // doesn't double-count traction that the tire model already provides.
    // Normal friction is preserved against walls and game pieces.
    private final Set<DGeom> tireModelGeoms = new HashSet<>();

    // Sensor geoms — collisions detected but no contact joints created
    private final Set<DGeom> sensorGeoms = new HashSet<>();

    // Bodies that contacted a sensor this step, keyed by sensor geom
    private final Map<DGeom, Set<DBody>> sensorContacts = new HashMap<>();

    // Optional user collision callback for game-specific logic
    private BiConsumer<DGeom, DGeom> userCollisionCallback;

    // Adaptive sub-stepping: prevent tunneling for fast-moving objects.
    // Any body whose per-step displacement exceeds minCollisionThickness
    // triggers sub-stepping so that each sub-step stays under the threshold.
    private double minCollisionThickness = 0.1; // meters (match thinnest wall)
    private int maxSubSteps = 10;

    // ODE4J native library requires exactly one initODE2() call per process.
    // This static flag ensures it runs once regardless of how many PhysicsWorld
    // instances are created.
    private static boolean odeInitialized = false;

    public PhysicsWorld() {
        if (!odeInitialized) {
            initODE2(0);
            odeInitialized = true;
        }

        world = OdeHelper.createWorld();
        world.setGravity(0, 0, -9.81);

        // Auto-disable for sleeping bodies (performance)
        world.setAutoDisableFlag(true);
        world.setAutoDisableLinearThreshold(0.02);
        world.setAutoDisableAngularThreshold(0.02);
        world.setAutoDisableSteps(10);
        world.setAutoDisableTime(0.3);

        // Per-step velocity damping — bleeds energy between collisions
        // so pieces don't bounce/slide forever (rolling friction + air drag analog)
        world.setLinearDamping(0.05);
        world.setAngularDamping(0.1);
        world.setLinearDampingThreshold(0.01);
        world.setAngularDampingThreshold(0.01);

        // Stability parameters
        world.setERP(0.8);
        world.setCFM(1e-5);

        // QuickStep iterations for constraint solving
        world.setQuickStepNumIterations(25);

        space = OdeHelper.createHashSpace(null);
        contactGroup = OdeHelper.createJointGroup();

        // Ground plane at z=0
        groundPlane = OdeHelper.createPlane(space, 0, 0, 1, 0);
    }

    /**
     * Step the physics world with adaptive sub-stepping.
     *
     * <p><b>Why sub-stepping:</b> A fast-moving object (e.g., a ball shot at 30 m/s)
     * travels 60 cm in one 20ms step. If a wall is only 10 cm thick, the ball
     * would pass clean through without ever registering a collision — this is
     * called "tunneling". Sub-stepping divides the timestep so that no body
     * moves more than {@code minCollisionThickness} per sub-step, giving the
     * collision detector a chance to catch every contact.
     *
     * <p><b>Algorithm:</b> Scans all active bodies for the fastest one. If its
     * per-step displacement exceeds {@code minCollisionThickness} (default 0.1m,
     * matching the thinnest wall), the timestep is split into
     * {@code ceil(displacement / thickness)} sub-steps, capped at {@code maxSubSteps}.
     *
     * <p>Most frames everything is slow and only 1 sub-step runs (zero overhead).
     * Extra sub-steps are only needed during fast events like shooter launches.
     *
     * @param dt timestep in seconds (typically 0.02 for 50Hz)
     */
    public void step(double dt) {
        // Clear sensor contact tracking
        for (Set<DBody> contacts : sensorContacts.values()) {
            contacts.clear();
        }

        int subSteps = computeSubSteps(dt);
        double subDt = dt / subSteps;

        for (int i = 0; i < subSteps; i++) {
            space.collide(null, this::nearCallback);
            world.quickStep(subDt);
            contactGroup.empty();
        }
    }

    /**
     * Determine how many sub-steps are needed so that the fastest body's
     * displacement per sub-step stays under {@code minCollisionThickness}.
     */
    private int computeSubSteps(double dt) {
        double maxSpeedSq = 0;
        int numGeoms = space.getNumGeoms();
        for (int i = 0; i < numGeoms; i++) {
            DGeom geom = space.getGeom(i);
            DBody body = geom.getBody();
            if (body == null || !body.isEnabled()) continue;
            DVector3C vel = body.getLinearVel();
            double speedSq = vel.get0() * vel.get0()
                           + vel.get1() * vel.get1()
                           + vel.get2() * vel.get2();
            if (speedSq > maxSpeedSq) maxSpeedSq = speedSq;
        }

        double maxDisplacement = Math.sqrt(maxSpeedSq) * dt;
        if (maxDisplacement <= minCollisionThickness) return 1;
        return Math.min(maxSubSteps, (int) Math.ceil(maxDisplacement / minCollisionThickness));
    }

    private void nearCallback(Object data, DGeom o1, DGeom o2) {
        DBody b1 = o1.getBody();
        DBody b2 = o2.getBody();

        // Don't collide two static geoms
        if (b1 == null && b2 == null) return;

        // Check if either geom is a sensor
        boolean o1Sensor = sensorGeoms.contains(o1);
        boolean o2Sensor = sensorGeoms.contains(o2);

        if (o1Sensor || o2Sensor) {
            // Sensor-only: detect overlap but do NOT create contact joints
            DContactBuffer contacts = new DContactBuffer(1);
            int numContacts = OdeHelper.collide(o1, o2, 1, contacts.getGeomBuffer());
            if (numContacts > 0) {
                if (o1Sensor) {
                    DBody other = b2;
                    if (other != null) {
                        sensorContacts.computeIfAbsent(o1, k -> new HashSet<>()).add(other);
                    }
                }
                if (o2Sensor) {
                    DBody other = b1;
                    if (other != null) {
                        sensorContacts.computeIfAbsent(o2, k -> new HashSet<>()).add(other);
                    }
                }
            }
            return;
        }

        // Fire user callback if set
        if (userCollisionCallback != null) {
            userCollisionCallback.accept(o1, o2);
        }

        // Normal physics collision
        DContactBuffer contacts = new DContactBuffer(maxContacts);
        int numContacts = OdeHelper.collide(o1, o2, maxContacts, contacts.getGeomBuffer());

        // Determine surface properties.
        // Tire-model geoms use near-zero friction against the ground plane only
        // (the tire model already handles traction). Against walls/pieces, use normal friction.
        boolean tireVsGround =
                (o1 == groundPlane && tireModelGeoms.contains(o2)) ||
                (o2 == groundPlane && tireModelGeoms.contains(o1));

        TerrainSurface surface = tireVsGround
                ? new TerrainSurface(0.01, 0.0, 0.0)
                : geomSurfaces.getOrDefault(o1, geomSurfaces.getOrDefault(o2, defaultSurface));

        for (int i = 0; i < numContacts; i++) {
            DContact contact = contacts.get(i);
            if (tireVsGround) {
                // Hard contacts for chassis vs ground — no soft ERP/CFM.
                // Soft contacts create a dt-dependent spring, so when adaptive
                // sub-stepping changes dt (e.g., fast ball triggers more sub-steps),
                // the equilibrium Z shifts and the chassis "hops".
                contact.surface.mode = OdeConstants.dContactBounce | OdeConstants.dContactApprox1;
            } else {
                contact.surface.mode = OdeConstants.dContactBounce | OdeConstants.dContactApprox1
                        | OdeConstants.dContactSoftERP | OdeConstants.dContactSoftCFM;
                contact.surface.soft_erp = surface.getSoftErp();
                contact.surface.soft_cfm = surface.getSoftCfm();
            }
            contact.surface.mu = surface.getFriction();
            contact.surface.bounce = surface.getBounce();
            contact.surface.bounce_vel = surface.getBounceVel();

            DJoint joint = OdeHelper.createContactJoint(world, contactGroup, contact);
            joint.attach(b1, b2);
        }
    }

    // --- Field Geometry ---

    /**
     * Load an OBJ mesh file as a static trimesh geometry for field collision.
     * @param objStream input stream of the OBJ file
     * @return the created trimesh geom
     */
    public DGeom loadFieldMesh(InputStream objStream) throws IOException {
        Obj obj = ObjReader.read(objStream);
        obj = ObjUtils.convertToRenderable(obj);

        int numVertices = obj.getNumVertices();
        int numFaces = obj.getNumFaces();

        // Build vertex array
        float[] vertices = new float[numVertices * 3];
        for (int i = 0; i < numVertices; i++) {
            var v = obj.getVertex(i);
            vertices[i * 3] = v.getX();
            vertices[i * 3 + 1] = v.getY();
            vertices[i * 3 + 2] = v.getZ();
        }

        // Build index array
        int[] indices = new int[numFaces * 3];
        for (int i = 0; i < numFaces; i++) {
            var face = obj.getFace(i);
            indices[i * 3] = face.getVertexIndex(0);
            indices[i * 3 + 1] = face.getVertexIndex(1);
            indices[i * 3 + 2] = face.getVertexIndex(2);
        }

        DTriMeshData meshData = OdeHelper.createTriMeshData();
        meshData.build(vertices, indices);

        DGeom trimesh = OdeHelper.createTriMesh(space, meshData, null, null, null);
        trimesh.setPosition(0, 0, 0);

        return trimesh;
    }

    /**
     * Add a static box to the world (e.g., field walls).
     * @return the created box geom
     */
    public DGeom addStaticBox(double lx, double ly, double lz, double px, double py, double pz) {
        DGeom box = OdeHelper.createBox(space, lx, ly, lz);
        box.setPosition(px, py, pz);
        return box;
    }

    // --- Sensor API ---

    /** Register a geom as using a tire model (near-zero friction vs ground only). */
    public void registerTireModelGeom(DGeom geom) {
        tireModelGeoms.add(geom);
    }

    /** Register a geom as a sensor (collisions detected but no contact joints). */
    public void registerSensor(DGeom geom) {
        sensorGeoms.add(geom);
        sensorContacts.put(geom, new HashSet<>());
    }

    /** Get bodies that contacted a sensor this step. */
    public Set<DBody> getSensorContacts(DGeom sensorGeom) {
        return sensorContacts.getOrDefault(sensorGeom, Collections.emptySet());
    }

    // --- Configuration ---

    public void setDefaultSurface(TerrainSurface surface) {
        this.defaultSurface = surface;
    }

    public void setGeomSurface(DGeom geom, TerrainSurface surface) {
        geomSurfaces.put(geom, surface);
    }

    public void setMaxContacts(int maxContacts) {
        this.maxContacts = maxContacts;
    }

    public void setUserCollisionCallback(BiConsumer<DGeom, DGeom> callback) {
        this.userCollisionCallback = callback;
    }

    public void setMinCollisionThickness(double thickness) {
        this.minCollisionThickness = thickness;
    }

    public void setMaxSubSteps(int max) {
        this.maxSubSteps = max;
    }

    // --- Accessors ---

    public DWorld getWorld() { return world; }
    public DSpace getSpace() { return space; }
    public DGeom getGroundPlane() { return groundPlane; }
}
