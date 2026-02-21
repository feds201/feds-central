package frc.robot.sim;

import edu.wpi.first.math.geometry.Pose3d;
import org.ironmaple.simulation.SimulatedArena;
import org.littletonrobotics.junction.Logger;

/**
 * Publishes maple-sim game piece positions to AdvantageKit each robot loop tick.
 * The physics simulation itself is driven by MapleSimSwerveDrivetrain's Notifier;
 * this class only handles logging game piece state for AdvantageScope's 3D view.
 */
public class SimulationManager {

    public SimulationManager() {
        SimulatedArena.getInstance().resetFieldForAuto();
    }

    /** Call from Robot.simulationPeriodic() to publish game piece positions. */
    public void periodic() {
        Pose3d[] coralPoses = SimulatedArena.getInstance().getGamePiecesArrayByType("Coral");
        Pose3d[] algaePoses = SimulatedArena.getInstance().getGamePiecesArrayByType("Algae");

        Logger.recordOutput("GamePieces/Coral", coralPoses);
        Logger.recordOutput("GamePieces/Algae", algaePoses);
    }
}
