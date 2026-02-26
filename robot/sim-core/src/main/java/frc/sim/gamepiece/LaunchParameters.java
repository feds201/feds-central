package frc.sim.gamepiece;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Translation3d;

/**
 * Parameters for launching a game piece from the robot.
 * Computes the 3D velocity vector from hood angle + robot heading + robot velocity.
 *
 * <p>Example: If the robot faces +X (heading = 0) with a 45° hood angle and 10 m/s
 * launch speed, the ball gets vx = 7.07, vy = 0, vz = 7.07 m/s. If the robot is
 * also moving at 2 m/s in +X, the ball gets vx = 9.07 (robot velocity is added).
 *
 * <p>If the turret offset is π/4 (45°), the horizontal velocity is rotated 45°
 * counterclockwise from the robot's heading.
 *
 * <p>Supports dual-barrel launchers via {@link #muzzleForwardOffsetM} and
 * {@link #barrelLateralOffsetM}. Use {@link #getLaunchPositions(Pose2d)} to get
 * left and right barrel spawn points offset from the robot center.
 */
public class LaunchParameters {
    /** Launch speed magnitude (m/s). */
    private final double velocityMagnitude;
    /** Hood elevation angle: 0 = horizontal, π/2 = straight up (radians). */
    private final double hoodAngleRad;
    /** Height above ground at which the piece spawns (meters). */
    private final double launchHeightM;
    /** Horizontal angular offset from robot heading for the turret (radians, 0 = turretless). */
    private final double turretOffsetRad;
    /** Forward distance from robot center along launch heading to the muzzle (meters). */
    private final double muzzleForwardOffsetM;
    /** Lateral distance from centerline for each barrel (meters). */
    private final double barrelLateralOffsetM;

    /**
     * @param velocityMagnitude     launch speed in m/s
     * @param hoodAngleRad          hood elevation angle in radians (0 = horizontal, π/2 = vertical)
     * @param launchHeightM         spawn height above ground in meters
     * @param turretOffsetRad       horizontal offset from robot heading in radians (0 for turretless)
     * @param muzzleForwardOffsetM  forward offset from robot center to muzzle in meters
     * @param barrelLateralOffsetM  lateral offset from centerline per barrel in meters
     */
    public LaunchParameters(double velocityMagnitude, double hoodAngleRad,
                           double launchHeightM, double turretOffsetRad,
                           double muzzleForwardOffsetM, double barrelLateralOffsetM) {
        this.velocityMagnitude = velocityMagnitude;
        this.hoodAngleRad = hoodAngleRad;
        this.launchHeightM = launchHeightM;
        this.turretOffsetRad = turretOffsetRad;
        this.muzzleForwardOffsetM = muzzleForwardOffsetM;
        this.barrelLateralOffsetM = barrelLateralOffsetM;
    }

    /**
     * @param velocityMagnitude launch speed in m/s
     * @param hoodAngleRad      hood elevation angle in radians (0 = horizontal, π/2 = vertical)
     * @param launchHeightM     spawn height above ground in meters
     * @param turretOffsetRad   horizontal offset from robot heading in radians (0 for turretless)
     */
    public LaunchParameters(double velocityMagnitude, double hoodAngleRad,
                           double launchHeightM, double turretOffsetRad) {
        this(velocityMagnitude, hoodAngleRad, launchHeightM, turretOffsetRad, 0, 0);
    }

    /**
     * Compute the world-frame launch position based on robot pose (single barrel, center).
     */
    public Translation3d getLaunchPosition(Pose2d robotPose) {
        double heading = robotPose.getRotation().getRadians() + turretOffsetRad;
        double x = robotPose.getX() + Math.cos(heading) * muzzleForwardOffsetM;
        double y = robotPose.getY() + Math.sin(heading) * muzzleForwardOffsetM;
        return new Translation3d(x, y, launchHeightM);
    }

    /**
     * Compute world-frame launch positions for left and right barrels.
     *
     * @param robotPose current robot 2D pose
     * @return array of two Translation3d: [left barrel, right barrel]
     */
    public Translation3d[] getLaunchPositions(Pose2d robotPose) {
        double heading = robotPose.getRotation().getRadians() + turretOffsetRad;
        double cosH = Math.cos(heading);
        double sinH = Math.sin(heading);

        // Forward offset along launch heading
        double fwdX = cosH * muzzleForwardOffsetM;
        double fwdY = sinH * muzzleForwardOffsetM;

        // Lateral perpendicular (left = +90° from heading)
        double latX = -sinH * barrelLateralOffsetM;
        double latY = cosH * barrelLateralOffsetM;

        double baseX = robotPose.getX() + fwdX;
        double baseY = robotPose.getY() + fwdY;

        return new Translation3d[] {
            new Translation3d(baseX + latX, baseY + latY, launchHeightM),  // left barrel
            new Translation3d(baseX - latX, baseY - latY, launchHeightM)   // right barrel
        };
    }

    /**
     * Compute the world-frame launch velocity vector.
     *
     * <p>Splits the launch speed into horizontal and vertical components using the
     * hood angle, then rotates the horizontal component by the robot heading +
     * turret offset. Finally, adds the robot's world-frame velocity so the ball
     * inherits the robot's momentum (important for shooting while moving).
     *
     * @param robotPose    current robot pose (heading used for launch direction)
     * @param robotVxWorld robot X velocity in world frame (m/s), added to launch velocity
     * @param robotVyWorld robot Y velocity in world frame (m/s), added to launch velocity
     * @return launch velocity in world frame (m/s)
     */
    public Translation3d getLaunchVelocity(Pose2d robotPose, double robotVxWorld, double robotVyWorld) {
        // Launch direction = robot heading + turret offset (in world frame)
        double heading = robotPose.getRotation().getRadians() + turretOffsetRad;

        // Split speed into horizontal (XY plane) and vertical (Z) components
        double horizontalSpeed = velocityMagnitude * Math.cos(hoodAngleRad);
        double verticalSpeed = velocityMagnitude * Math.sin(hoodAngleRad);

        // Rotate horizontal component by launch heading, then add robot velocity
        double vx = horizontalSpeed * Math.cos(heading) + robotVxWorld;
        double vy = horizontalSpeed * Math.sin(heading) + robotVyWorld;
        double vz = verticalSpeed;

        return new Translation3d(vx, vy, vz);
    }

    public double getVelocityMagnitude() { return velocityMagnitude; }
    public double getHoodAngleRad() { return hoodAngleRad; }
    public double getLaunchHeightM() { return launchHeightM; }
    public double getTurretOffsetRad() { return turretOffsetRad; }
    public double getMuzzleForwardOffsetM() { return muzzleForwardOffsetM; }
    public double getBarrelLateralOffsetM() { return barrelLateralOffsetM; }
}
