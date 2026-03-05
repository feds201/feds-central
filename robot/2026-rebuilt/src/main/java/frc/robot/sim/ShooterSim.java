package frc.robot.sim;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Translation3d;
import frc.sim.gamepiece.GamePieceConfig;
import frc.sim.gamepiece.GamePieceManager;
import frc.sim.gamepiece.LaunchParameters;

import java.util.function.BooleanSupplier;
import java.util.function.DoubleSupplier;
import java.util.function.Supplier;
import org.littletonrobotics.junction.Logger;

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
    private final DoubleSupplier hoodAngleSupplier;       // rotations
    private final DoubleSupplier flywheelVelocitySupplier; // rps
    private final BooleanSupplier shootingSupplier;
    private final DoubleSupplier robotVxSupplier;  // world frame m/s
    private final DoubleSupplier robotVySupplier;  // world frame m/s

    /** Height above ground where the ball exits the shooter (placeholder, meters).
     *  Should match the physical shooter exit point on the robot CAD. */
    private static final double LAUNCH_HEIGHT = 0.6;

    /** Forward distance from robot center to muzzle along launch heading (meters).
     *  Must clear chassis half-length (0.4m) + ball radius (0.075m) with margin. */
    private static final double MUZZLE_FORWARD_OFFSET = 0.6;

    /** Lateral distance from centerline for each barrel (meters). */
    private static final double BARREL_LATERAL_OFFSET = 0.08;

    /** Number of shot events per second (each event fires both barrels). */
    private static final double SHOTS_PER_SECOND = 8;

    private double cooldownTimer = 0;

    /** Wheel diameter in meters. */
    private static final double WHEEL_DIAMETER = 0.1016; // 4 inches

    /** Velocity loss factor due to ball slip/compression (placeholder). */
    private static final double LAUNCH_EFFICIENCY = 0.8;

    /**
     * Create the shooter simulation bridge.
     *
     * @param gamePieceManager       manages piece lifecycle (intake counter and spawning)
     * @param fuelConfig             game piece config for launched balls
     * @param robotPoseSupplier      supplies the current robot 2D pose (for launch direction)
     * @param hoodAngleSupplier      supplies the current hood angle in rotations (0 = horizontal)
     * @param flywheelVelocitySupplier supplies the flywheel velocity in rotations per second
     * @param shootingSupplier       returns true when the shooter is actively firing
     * @param robotVxSupplier        supplies the robot's world-frame X velocity (m/s)
     * @param robotVySupplier        supplies the robot's world-frame Y velocity (m/s)
     */
    public ShooterSim(GamePieceManager gamePieceManager, GamePieceConfig fuelConfig,
                      Supplier<Pose2d> robotPoseSupplier,
                      DoubleSupplier hoodAngleSupplier,
                      DoubleSupplier flywheelVelocitySupplier,
                      BooleanSupplier shootingSupplier,
                      DoubleSupplier robotVxSupplier,
                      DoubleSupplier robotVySupplier) {
        this.gamePieceManager = gamePieceManager;
        this.fuelConfig = fuelConfig;
        this.robotPoseSupplier = robotPoseSupplier;
        this.hoodAngleSupplier = hoodAngleSupplier;
        this.flywheelVelocitySupplier = flywheelVelocitySupplier;
        this.shootingSupplier = shootingSupplier;
        this.robotVxSupplier = robotVxSupplier;
        this.robotVySupplier = robotVySupplier;
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

            // Convert flywheel velocity (RPS) to linear launch velocity (m/s)
            // v = omega * r = (RPS * 2pi) * (diameter / 2) = RPS * pi * diameter
            double launchSpeed = flywheelVelocitySupplier.getAsDouble() * Math.PI * WHEEL_DIAMETER * LAUNCH_EFFICIENCY;

            // Convert hood rotations to radians (assuming 1 rotation = 360 degrees for sim bridge)
            double hoodAngleRad = hoodAngleSupplier.getAsDouble() * 2 * Math.PI;

        LaunchParameters params = new LaunchParameters(
                    launchSpeed,
                    hoodAngleRad,
                    LAUNCH_HEIGHT,
                    0,  // no turret offset (turretless robot)
                    MUZZLE_FORWARD_OFFSET,
                    BARREL_LATERAL_OFFSET
            );

        // Record telemetry so we can see launches in Shuffleboard / AdvantageScope
        Logger.recordOutput("Sim/Shooter/LastLaunchSpeed_mps", launchSpeed);
        Logger.recordOutput("Sim/Shooter/LastHoodRotations", hoodAngleSupplier.getAsDouble());
        Logger.recordOutput("Sim/Shooter/HeldBeforeLaunch", gamePieceManager.getHeldCount());

        Translation3d velocity = params.getLaunchVelocity(robotPose,
            robotVxSupplier.getAsDouble(), robotVySupplier.getAsDouble());
            Translation3d[] positions = params.getLaunchPositions(robotPose);

            // Fire from both barrels (left then right), checking held count before each
            for (Translation3d pos : positions) {
                if (gamePieceManager.getHeldCount() > 0) {
                    gamePieceManager.launchPiece(fuelConfig, pos, velocity);
                }
            }

            cooldownTimer = 1.0 / SHOTS_PER_SECOND;
        }
    }

    /**
     * Force a single spawn using current subsystem state (ignores cooldown and shootingSupplier).
     * Useful for debugging/troubleshooting to immediately shoot a ball from the current pose.
     */
    public void forceSpawn() {
        Pose2d robotPose = robotPoseSupplier.get();
        if (robotPose == null) return;

        double launchSpeed = flywheelVelocitySupplier.getAsDouble() * Math.PI * WHEEL_DIAMETER * LAUNCH_EFFICIENCY;
        double hoodAngleRad = hoodAngleSupplier.getAsDouble() * 2 * Math.PI;

        LaunchParameters params = new LaunchParameters(
                launchSpeed,
                hoodAngleRad,
                LAUNCH_HEIGHT,
                0,
                MUZZLE_FORWARD_OFFSET,
                BARREL_LATERAL_OFFSET
        );

        Logger.recordOutput("Sim/Shooter/ForceSpawnSpeed_mps", launchSpeed);
        Logger.recordOutput("Sim/Shooter/ForceSpawnHoodRotations", hoodAngleSupplier.getAsDouble());
        Logger.recordOutput("Sim/Shooter/ForceSpawnHeldBefore", gamePieceManager.getHeldCount());

        Translation3d velocity = params.getLaunchVelocity(robotPose,
                robotVxSupplier.getAsDouble(), robotVySupplier.getAsDouble());
        Translation3d[] positions = params.getLaunchPositions(robotPose);

        for (Translation3d pos : positions) {
            if (gamePieceManager.getHeldCount() > 0) {
                gamePieceManager.launchPiece(fuelConfig, pos, velocity);
            }
        }
    }
}
