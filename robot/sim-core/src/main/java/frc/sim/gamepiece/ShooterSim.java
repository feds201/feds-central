package frc.sim.gamepiece;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Translation3d;

import java.util.function.BooleanSupplier;
import java.util.function.DoubleSupplier;
import java.util.function.Supplier;

/**
 * Connects the shooter subsystem state to the sim game piece system.
 * When the shooter fires, spawns a ball with velocity based on
 * flywheel speed + hood angle.
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

    private final double launchHeight;
    private final double muzzleForwardOffset;
    private final double barrelLateralOffset;
    private final double shotsPerSecond;

    private double cooldownTimer = 0;

    /**
     * Create the shooter simulation bridge.
     *
     * @param gamePieceManager       manages piece lifecycle (intake counter and spawning)
     * @param fuelConfig             game piece config for launched balls
     * @param robotPoseSupplier      supplies the current robot 2D pose (for launch direction)
     * @param hoodAngleSupplier      supplies the current hood angle in radians (0 = horizontal)
     * @param launchVelocitySupplier supplies the launch speed in m/s
     * @param shootingSupplier       returns true when the shooter is actively firing
     * @param robotVxSupplier        supplies the robot's world-frame X velocity (m/s)
     * @param robotVySupplier        supplies the robot's world-frame Y velocity (m/s)
     * @param launchHeight           height above ground at which balls spawn (m)
     * @param muzzleForwardOffset    forward offset from robot center to muzzle (m)
     * @param barrelLateralOffset    lateral offset from centerline per barrel (m)
     * @param shotsPerSecond         number of shot events per second (each fires both barrels)
     */
    public ShooterSim(GamePieceManager gamePieceManager, GamePieceConfig fuelConfig,
                      Supplier<Pose2d> robotPoseSupplier,
                      DoubleSupplier hoodAngleSupplier,
                      DoubleSupplier launchVelocitySupplier,
                      BooleanSupplier shootingSupplier,
                      DoubleSupplier robotVxSupplier,
                      DoubleSupplier robotVySupplier,
                      double launchHeight,
                      double muzzleForwardOffset,
                      double barrelLateralOffset,
                      double shotsPerSecond) {
        this.gamePieceManager = gamePieceManager;
        this.fuelConfig = fuelConfig;
        this.robotPoseSupplier = robotPoseSupplier;
        this.hoodAngleSupplier = hoodAngleSupplier;
        this.launchVelocitySupplier = launchVelocitySupplier;
        this.shootingSupplier = shootingSupplier;
        this.robotVxSupplier = robotVxSupplier;
        this.robotVySupplier = robotVySupplier;
        this.launchHeight = launchHeight;
        this.muzzleForwardOffset = muzzleForwardOffset;
        this.barrelLateralOffset = barrelLateralOffset;
        this.shotsPerSecond = shotsPerSecond;
    }

    /**
     * Call each tick. If shooting and cooldown expired, launch from both barrels.
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
                    launchHeight,
                    0,  // no turret offset
                    muzzleForwardOffset,
                    barrelLateralOffset
            );

            Translation3d velocity = params.getLaunchVelocity(robotPose,
                    robotVxSupplier.getAsDouble(), robotVySupplier.getAsDouble());
            Translation3d[] positions = params.getLaunchPositions(robotPose);

            // Fire from both barrels (left then right), checking held count before each
            for (Translation3d pos : positions) {
                if (gamePieceManager.getHeldCount() > 0) {
                    gamePieceManager.launchPiece(fuelConfig, pos, velocity);
                }
            }

            cooldownTimer = 1.0 / shotsPerSecond;
        }
    }
}
