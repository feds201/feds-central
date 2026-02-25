package frc.sim.chassis;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Pose3d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.geometry.Translation2d;
import frc.sim.core.PhysicsWorld;
import frc.sim.core.SimMath;
import org.ode4j.math.DMatrix3;
import org.ode4j.math.DMatrix3C;
import org.ode4j.math.DVector3C;
import org.ode4j.ode.*;

import static org.ode4j.ode.OdeHelper.*;

/**
 * ODE4J rigid body representation of the robot chassis.
 * Accepts pre-computed world-frame forces (from MapleSim module physics)
 * and applies them to the ODE4J body for 3D collision response.
 *
 * The chassis body lives in the same PhysicsWorld as game pieces and field
 * geometry, enabling automatic cross-body collisions.
 */
public class ChassisSimulation {
    private final PhysicsWorld physicsWorld;
    private final ChassisConfig config;

    private final DBody chassisBody;
    private final DGeom chassisGeom;

    public ChassisSimulation(PhysicsWorld physicsWorld, ChassisConfig config, Pose2d startingPose) {
        this.physicsWorld = physicsWorld;
        this.config = config;

        // Create ODE4J body
        DWorld world = physicsWorld.getWorld();
        DSpace space = physicsWorld.getSpace();

        chassisBody = OdeHelper.createBody(world);
        chassisBody.setAutoDisableFlag(false); // Chassis must always be active

        // Set initial pose
        double startX = startingPose.getX();
        double startY = startingPose.getY();
        chassisBody.setPosition(startX, startY, config.getBumperHeight() / 2.0);

        // Set initial rotation (yaw only)
        double yaw = startingPose.getRotation().getRadians();
        DMatrix3 rotation = new DMatrix3();
        rotation.set00(Math.cos(yaw)); rotation.set01(-Math.sin(yaw)); rotation.set02(0);
        rotation.set10(Math.sin(yaw)); rotation.set11(Math.cos(yaw));  rotation.set12(0);
        rotation.set20(0);             rotation.set21(0);              rotation.set22(1);
        chassisBody.setRotation(rotation);

        // Mass and inertia
        DMass mass = OdeHelper.createMass();
        mass.setBoxTotal(config.getRobotMassKg(),
                config.getBumperLengthX(),
                config.getBumperWidthY(),
                config.getBumperHeight());
        chassisBody.setMass(mass);

        // Box geom for collisions
        chassisGeom = OdeHelper.createBox(space,
                config.getBumperLengthX(),
                config.getBumperWidthY(),
                config.getBumperHeight());
        chassisGeom.setBody(chassisBody);

        // Near-zero friction vs ground plane so the chassis slides freely
        // when driven by forces (applyForces) or kinematic velocity (setVelocity).
        // Normal friction against walls/game pieces is preserved.
        physicsWorld.registerTireModelGeom(chassisGeom);
    }

    /**
     * Apply pre-computed world-frame forces to the chassis.
     * Call this BEFORE physicsWorld.step().
     *
     * @param worldFx net force in world X (Newtons)
     * @param worldFy net force in world Y (Newtons)
     * @param torqueZ net torque about Z axis (N*m)
     */
    public void applyForces(double worldFx, double worldFy, double torqueZ) {
        // Apply as pure force at center of mass (no parasitic pitch/roll torque)
        chassisBody.addForce(worldFx, worldFy, 0);

        // Apply yaw torque
        chassisBody.addTorque(0, 0, torqueZ);

        // Angular damping to prevent spinning oscillation
        DVector3C angVel = chassisBody.getAngularVel();
        double dampingFactor = 2.0;
        chassisBody.addTorque(
            -angVel.get0() * dampingFactor,
            -angVel.get1() * dampingFactor,
            -angVel.get2() * dampingFactor);
    }

    // --- Kinematic Mode ---

    /**
     * Set the chassis X, Y, and yaw from an external source (e.g., MapleSim).
     * Preserves Z, pitch, and roll from ODE4J so the chassis can ride over bumps/ramps.
     */
    public void setPose(Pose2d pose) {
        // X, Y from MapleSim; Z from ODE4J (gravity + contacts)
        double currentZ = chassisBody.getPosition().get2();
        chassisBody.setPosition(pose.getX(), pose.getY(), currentZ);

        // Extract current pitch and roll from ODE4J's rotation matrix using
        // ZYX Euler angle decomposition (see SimMath.odeRotationToRotation3d for
        // the full matrix layout). We only extract pitch/roll here because yaw
        // comes from MapleSim.
        //
        // From R = Rz(yaw) * Ry(pitch) * Rx(roll):
        //   cosPitch = sqrt(R[0,0]^2 + R[1,0]^2) = |cos(pitch)| (always >= 0)
        //   pitch    = atan2(-R[2,0], cosPitch)
        //   roll     = atan2(R[2,1], R[2,2])
        DMatrix3C cur = chassisBody.getRotation();
        double cosPitch = Math.sqrt(cur.get00() * cur.get00() + cur.get10() * cur.get10());
        double pitch = Math.atan2(-cur.get20(), cosPitch);
        double roll = Math.atan2(cur.get21(), cur.get22());

        // Recompose the full rotation matrix: R = Rz(newYaw) * Ry(pitch) * Rx(roll)
        double yaw = pose.getRotation().getRadians();
        double cy = Math.cos(yaw), sy = Math.sin(yaw);
        double cp = Math.cos(pitch), sp = Math.sin(pitch);
        double cr = Math.cos(roll), sr = Math.sin(roll);

        DMatrix3 r = new DMatrix3();
        r.set00(cy*cp);  r.set01(cy*sp*sr - sy*cr);  r.set02(cy*sp*cr + sy*sr);
        r.set10(sy*cp);  r.set11(sy*sp*sr + cy*cr);  r.set12(sy*sp*cr - cy*sr);
        r.set20(-sp);    r.set21(cp*sr);              r.set22(cp*cr);
        chassisBody.setRotation(r);
    }

    /**
     * Drive the chassis toward the desired X/Y velocity and yaw rate using
     * corrective forces. Unlike a direct velocity override, this lets
     * ODE4J contact constraints naturally oppose wall penetration.
     *
     * <p>Uses an "instant corrective force" model: {@code F = m * (v_desired - v_current) / dt}.
     * This reaches the desired velocity in exactly one timestep when unobstructed.
     * When the chassis is against a wall, ODE4J's contact solver opposes the force
     * and the chassis stops naturally. This is not physically realistic (infinite
     * acceleration), but is appropriate for kinematic following of an external
     * drivetrain simulation (MapleSim).
     *
     * <p>Z velocity and pitch/roll rates are left entirely to ODE4J (gravity + ramp contacts).
     *
     * @param vx    desired world-frame X velocity (m/s)
     * @param vy    desired world-frame Y velocity (m/s)
     * @param omega desired angular velocity about Z axis (rad/s)
     * @param dt    physics timestep (seconds)
     */
    public void setVelocity(double vx, double vy, double omega, double dt) {
        double mass = config.getRobotMassKg();
        double moi = config.getRobotMOI();

        double currentVx = chassisBody.getLinearVel().get0();
        double currentVy = chassisBody.getLinearVel().get1();
        chassisBody.addForce(
                mass * (vx - currentVx) / dt,
                mass * (vy - currentVy) / dt,
                0);

        double currentOmega = chassisBody.getAngularVel().get2();
        chassisBody.addTorque(0, 0, moi * (omega - currentOmega) / dt);
    }

    // --- Accessors ---

    /** Get the 2D pose of the chassis. */
    public Pose2d getPose2d() {
        DVector3C pos = chassisBody.getPosition();
        return new Pose2d(pos.get0(), pos.get1(), new Rotation2d(getYawRad()));
    }

    /** Get the full 3D pose of the chassis. */
    public Pose3d getPose3d() {
        return SimMath.odeToPose3d(chassisBody);
    }

    /** Extract yaw from ODE4J rotation matrix. */
    public double getYawRad() {
        DMatrix3C rot = chassisBody.getRotation();
        return Math.atan2(rot.get10(), rot.get00());
    }

    /** Get angular velocity about Z axis (rad/s). */
    public double getAngularVelocityZ() {
        return chassisBody.getAngularVel().get2();
    }

    /** Get the linear velocity in world frame. */
    public DVector3C getLinearVelocity() {
        return chassisBody.getLinearVel();
    }

    /** Get the underlying ODE4J body. */
    public DBody getBody() { return chassisBody; }

    /** Get the underlying ODE4J geom. */
    public DGeom getGeom() { return chassisGeom; }

    /** Get the config. */
    public ChassisConfig getConfig() { return config; }
}
