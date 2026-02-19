package frc.sim.telemetry;

import org.ode4j.math.DVector3C;
import org.ode4j.ode.DBody;

/**
 * Tracks how high the robot chassis is above the ground.
 * Useful for detecting ramp climbing and airborne states.
 */
public class GroundClearance {
    private final DBody chassisBody;
    private final double halfHeight;

    public GroundClearance(DBody chassisBody, double chassisHeight) {
        this.chassisBody = chassisBody;
        this.halfHeight = chassisHeight / 2.0;
    }

    /** Get the current ground clearance (bottom of chassis to z=0). */
    public double getClearance() {
        return chassisBody.getPosition().get2() - halfHeight;
    }

    /** Check if the robot is fully off the ground (>5cm). */
    public boolean isAirborne() {
        return getClearance() > 0.05;
    }
}
