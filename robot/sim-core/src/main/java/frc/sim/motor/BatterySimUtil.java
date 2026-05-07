package frc.sim.motor;

import edu.wpi.first.wpilibj.simulation.BatterySim;
import edu.wpi.first.wpilibj.simulation.RoboRioSim;

/**
 * Utility for computing simulated battery voltage from motor current draws.
 *
 * <p>Encapsulates the ordering requirement: RoboRioSim voltage must be set
 * BEFORE motor sim updates so that DCMotorSim's internal voltage clamp
 * uses the correct value.
 */
public final class BatterySimUtil {
    private BatterySimUtil() {}

    /**
     * Compute battery voltage from current draws, clamp to [minVoltage, maxVoltage],
     * set RoboRioSim voltage, and return the result.
     *
     * @param minVoltage      minimum voltage clamp
     * @param maxVoltage      maximum voltage clamp
     * @param currentDrawAmps current draw values from each motor sim
     * @return the clamped battery voltage
     */
    public static double updateBatteryVoltage(double minVoltage, double maxVoltage, double... currentDrawAmps) {
        double voltage = BatterySim.calculateDefaultBatteryLoadedVoltage(currentDrawAmps);
        voltage = Math.max(minVoltage, Math.min(maxVoltage, voltage));
        RoboRioSim.setVInVoltage(voltage);
        return voltage;
    }
}
