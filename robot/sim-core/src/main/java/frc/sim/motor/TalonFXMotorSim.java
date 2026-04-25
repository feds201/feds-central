package frc.sim.motor;

import static edu.wpi.first.units.Units.Rotations;
import static edu.wpi.first.units.Units.RotationsPerSecond;

import com.ctre.phoenix6.sim.TalonFXSimState;
import edu.wpi.first.wpilibj.simulation.DCMotorSim;

/**
 * Wraps a WPILib DCMotorSim and a CTRE TalonFXSimState into the standard
 * 5-step motor simulation pattern used for flywheel-style mechanisms.
 *
 * <p>The 5-step pattern each tick:
 * <ol>
 *   <li>Set supply voltage on the TalonFX sim state</li>
 *   <li>Read commanded motor voltage (negate if invertWriteback)</li>
 *   <li>Feed voltage into the physics sim</li>
 *   <li>Step the physics sim</li>
 *   <li>Write back position and velocity to the TalonFX sim state</li>
 * </ol>
 */
public class TalonFXMotorSim implements SimMotor {
    private final TalonFXSimState simState;
    private final DCMotorSim physicsSim;
    private final double gearRatio;
    private final double sign;

    /**
     * @param simState        CTRE TalonFX sim state for voltage read and encoder writeback
     * @param physicsSim      WPILib DCMotorSim for physics integration
     * @param gearRatio       motor rotations per mechanism rotation
     * @param invertWriteback true for Clockwise_Positive motors (negates voltage read AND position/velocity writeback),
     *                        false for CounterClockwise_Positive motors
     */
    public TalonFXMotorSim(TalonFXSimState simState, DCMotorSim physicsSim, double gearRatio, boolean invertWriteback) {
        this.simState = simState;
        this.physicsSim = physicsSim;
        this.gearRatio = gearRatio;
        this.sign = invertWriteback ? -1.0 : 1.0;
    }

    @Override
    public void update(double dt, double supplyVoltage) {
        simState.setSupplyVoltage(supplyVoltage);
        double voltage = sign * simState.getMotorVoltage();
        physicsSim.setInputVoltage(voltage);
        physicsSim.update(dt);
        simState.setRawRotorPosition(
            Rotations.of(sign * gearRatio * physicsSim.getAngularPositionRotations()));
        simState.setRotorVelocity(
            RotationsPerSecond.of(sign * gearRatio * physicsSim.getAngularVelocityRPM() / 60.0));
    }

    @Override
    public double getCurrentDrawAmps() {
        return physicsSim.getCurrentDrawAmps();
    }

    public double getAngularVelocityRPS() {
        return physicsSim.getAngularVelocityRPM() / 60.0;
    }

    public double getAngularVelocityRadPerSec() {
        return physicsSim.getAngularVelocityRadPerSec();
    }

    /**
     * Returns mechanism-side angular position in rotations (unsigned, raw physics value,
     * not gear-ratio-scaled). Callers that need rotor-side rotations should apply gearRatio.
     */
    public double getAngularPositionRotations() {
        return physicsSim.getAngularPositionRotations();
    }
}
