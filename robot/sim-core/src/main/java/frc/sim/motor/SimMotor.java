package frc.sim.motor;

/**
 * Common interface for TalonFX motor simulations so battery util
 * and sim managers can treat TalonFXMotorSim and TalonFXArmSim uniformly.
 */
public interface SimMotor {
    /**
     * Step the physics sim forward and sync position/velocity back to the TalonFX sim state.
     *
     * @param dt            timestep in seconds
     * @param supplyVoltage battery/supply voltage to set on the TalonFX sim state before the tick
     */
    void update(double dt, double supplyVoltage);

    /**
     * @return current draw from the underlying physics sim, in amps
     */
    double getCurrentDrawAmps();
}
