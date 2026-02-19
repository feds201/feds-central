package frc.robot.sim;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Translation3d;
import frc.sim.gamepiece.GamePieceConfig;
import frc.sim.gamepiece.GamePieceManager;
import frc.sim.gamepiece.LaunchParameters;

import java.util.function.BooleanSupplier;
import java.util.function.DoubleSupplier;
import java.util.function.Supplier;

/**
 * Connects the shooter subsystem state to the sim game piece system.
 * When the shooter fires, spawns a ball with velocity based on
 * flywheel speed + hood angle.
 *
 * Note: backspin/topspin on launched balls is a stretch goal.
 * Currently balls are launched with pure translational velocity.
 */
public class ShooterSim {
    private final GamePieceManager gamePieceManager;
    private final GamePieceConfig fuelConfig;
    private final Supplier<Pose2d> robotPoseSupplier;
    private final DoubleSupplier hoodAngleSupplier;       // rad
    private final DoubleSupplier launchVelocitySupplier;  // m/s
    private final BooleanSupplier shootingSupplier;
    private final DoubleSupplier robotVxSupplier;  // world frame m/s
    private final DoubleSupplier robotVySupplier;  // world frame m/s

    /** Height above ground where the ball exits the shooter (placeholder, meters).
     *  Should match the physical shooter exit point on the robot CAD. */
    private static final double LAUNCH_HEIGHT = 0.6;

    // Cooldown between shots (to avoid launching too many balls per second)
    private static final double SHOT_COOLDOWN = 0.1; // seconds
    private double cooldownTimer = 0;

    /**
     * Create the shooter simulation bridge.
     *
     * @param gamePieceManager     manages piece lifecycle (intake counter and spawning)
     * @param fuelConfig           game piece config for launched balls
     * @param robotPoseSupplier    supplies the current robot 2D pose (for launch direction)
     * @param hoodAngleSupplier    supplies the current hood angle in radians (0 = horizontal)
     * @param launchVelocitySupplier supplies the launch speed in m/s
     * @param shootingSupplier     returns true when the shooter is actively firing
     * @param robotVxSupplier      supplies the robot's world-frame X velocity (m/s)
     * @param robotVySupplier      supplies the robot's world-frame Y velocity (m/s)
     */
    public ShooterSim(GamePieceManager gamePieceManager, GamePieceConfig fuelConfig,
                      Supplier<Pose2d> robotPoseSupplier,
                      DoubleSupplier hoodAngleSupplier,
                      DoubleSupplier launchVelocitySupplier,
                      BooleanSupplier shootingSupplier,
                      DoubleSupplier robotVxSupplier,
                      DoubleSupplier robotVySupplier) {
        this.gamePieceManager = gamePieceManager;
        this.fuelConfig = fuelConfig;
        this.robotPoseSupplier = robotPoseSupplier;
        this.hoodAngleSupplier = hoodAngleSupplier;
        this.launchVelocitySupplier = launchVelocitySupplier;
        this.shootingSupplier = shootingSupplier;
        this.robotVxSupplier = robotVxSupplier;
        this.robotVySupplier = robotVySupplier;
    }

    /**
     * Call each tick. If shooting and cooldown expired, launch a ball.
     * @param dt timestep in seconds
     */
    public void update(double dt) {
        cooldownTimer = Math.max(0, cooldownTimer - dt);

        if (shootingSupplier.getAsBoolean() && cooldownTimer <= 0 && gamePieceManager.getHeldCount() > 0) {
            Pose2d robotPose = robotPoseSupplier.get();
            if (robotPose == null) return;

            LaunchParameters params = new LaunchParameters(
                    launchVelocitySupplier.getAsDouble(),
                    hoodAngleSupplier.getAsDouble(),
                    LAUNCH_HEIGHT,
                    0  // no turret offset (turretless robot)
            );

            Translation3d position = params.getLaunchPosition(robotPose);
            Translation3d velocity = params.getLaunchVelocity(robotPose,
                    robotVxSupplier.getAsDouble(), robotVySupplier.getAsDouble());

            gamePieceManager.launchPiece(fuelConfig, position, velocity);
            cooldownTimer = SHOT_COOLDOWN;
        }
    }
}
