package frc.sim.motor;

import static edu.wpi.first.units.Units.Rotations;
import static edu.wpi.first.units.Units.RotationsPerSecond;

import com.ctre.phoenix6.sim.TalonFXSimState;
import edu.wpi.first.wpilibj.simulation.SingleJointedArmSim;

/**
 * Wraps a WPILib SingleJointedArmSim and a CTRE TalonFXSimState into the standard
 * motor simulation pattern used for arm-style mechanisms.
 *
 * <p>Assumption: motor position 0 corresponds to minAngle.
 *
 * <p>Writeback at mechanism limits assumes SingleJointedArmSim clamps both angle and velocity.
 * If residual voltage drives past a limit within a single tick, the rotor position will stick
 * at the clamp and rotor velocity may briefly disagree; subsequent ticks resolve this.
 */
public class TalonFXArmSim implements SimMotor {
    private final TalonFXSimState simState;
    private final SingleJointedArmSim armSim;
    private final double minAngleRad;
    private final double angleRange;
    private final double motorRotationsAtMaxAngle;
    private final double sign;

    /**
     * @param simState                CTRE TalonFX sim state for voltage read and encoder writeback
     * @param armSim                  WPILib SingleJointedArmSim for physics integration
     * @param minAngleRad             minimum mechanism angle in radians (maps to motor position 0)
     * @param maxAngleRad             maximum mechanism angle in radians
     * @param motorRotationsAtMaxAngle motor rotations when arm is at maxAngle
     * @param invertVoltage           true to negate voltage read and writeback, false otherwise
     */
    public TalonFXArmSim(TalonFXSimState simState, SingleJointedArmSim armSim,
                          double minAngleRad, double maxAngleRad,
                          double motorRotationsAtMaxAngle, boolean invertVoltage) {
        this.simState = simState;
        this.armSim = armSim;
        this.minAngleRad = minAngleRad;
        this.angleRange = maxAngleRad - minAngleRad;
        this.motorRotationsAtMaxAngle = motorRotationsAtMaxAngle;
        this.sign = invertVoltage ? -1.0 : 1.0;
    }

    @Override
    public void update(double dt, double supplyVoltage) {
        simState.setSupplyVoltage(supplyVoltage);
        double voltage = sign * simState.getMotorVoltage();
        armSim.setInputVoltage(voltage);
        armSim.update(dt);
        double positionRot = (armSim.getAngleRads() - minAngleRad) / angleRange * motorRotationsAtMaxAngle;
        double velRotPerSec = armSim.getVelocityRadPerSec() / angleRange * motorRotationsAtMaxAngle;
        simState.setRawRotorPosition(Rotations.of(sign * positionRot));
        simState.setRotorVelocity(RotationsPerSecond.of(sign * velRotPerSec));
    }

    @Override
    public double getCurrentDrawAmps() {
        return armSim.getCurrentDrawAmps();
    }

    public double getAngleRads() {
        return armSim.getAngleRads();
    }

    public double getVelocityRadPerSec() {
        return armSim.getVelocityRadPerSec();
    }
}
