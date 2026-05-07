package frc.sim.gamepiece;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.geometry.Translation2d;

import java.util.List;
import java.util.function.BooleanSupplier;
import java.util.function.Supplier;

/**
 * Robot-relative bounding box for counter-based intake.
 * Each tick: checks if any piece overlaps the zone and the robot can intake
 * + counter is below max → removes the piece and increments the counter.
 */
public class IntakeZone {
    private final double xMin, xMax, yMin, yMax, zMax;
    private final BooleanSupplier canIntake;
    private final Supplier<Pose2d> robotPoseSupplier;

    /**
     * @param xMin  robot-relative X min (forward = +X)
     * @param xMax  robot-relative X max
     * @param yMin  robot-relative Y min (left = +Y)
     * @param yMax  robot-relative Y max
     * @param zMax  max height for intake (balls above this are ignored)
     * @param canIntake  supplier returning true when the robot is ready to intake game pieces
     * @param robotPoseSupplier  supplier of current robot 2D pose
     */
    public IntakeZone(double xMin, double xMax, double yMin, double yMax, double zMax,
                      BooleanSupplier canIntake, Supplier<Pose2d> robotPoseSupplier) {
        this.xMin = xMin;
        this.xMax = xMax;
        this.yMin = yMin;
        this.yMax = yMax;
        this.zMax = zMax;
        this.canIntake = canIntake;
        this.robotPoseSupplier = robotPoseSupplier;
    }

    /**
     * Check pieces against the intake zone and consume any that are inside.
     *
     * <p>Only pieces with physics enabled are considered — sleeping pieces are by
     * definition outside the wake radius (see {@link GamePieceManager#updateProximity})
     * and therefore can't overlap the intake zone. This lets us skip the full
     * world→robot-relative transform for the 200+ pieces elsewhere on the field.
     */
    public int checkIntake(GamePieceManager manager, List<GamePiece> pieces) {
        if (!canIntake.getAsBoolean()) return 0;

        Pose2d robotPose = robotPoseSupplier.get();
        int consumed = 0;

        for (GamePiece piece : pieces) {
            if (!piece.isActive()) continue;
            if (piece.isOffField()) continue;
            // Skip pieces whose physics was explicitly disabled — they're outside the wake
            // radius (see GamePieceManager.updateProximity) and can't be in the intake zone.
            if (piece.hasPhysics() && !piece.getBody().isEnabled()) continue;

            var worldPos = piece.getPosition3d();

            // Height check
            if (worldPos.getZ() > zMax) continue;

            // Transform piece world position into robot-relative coordinates.
            // 1. Translate: subtract robot position to get the offset vector
            // 2. Rotate: apply inverse of robot heading (rotate by -theta)
            //    to express the offset in the robot's local frame (+X = forward, +Y = left)
            Translation2d pieceWorld2d = new Translation2d(worldPos.getX(), worldPos.getY());
            Translation2d robotPos2d = robotPose.getTranslation();
            Rotation2d robotRot = robotPose.getRotation();

            Translation2d diff = pieceWorld2d.minus(robotPos2d);
            double cos = robotRot.getCos();
            double sin = robotRot.getSin();
            double relX = diff.getX() * cos + diff.getY() * sin;
            double relY = -diff.getX() * sin + diff.getY() * cos;

            // Bounding box check
            if (relX >= xMin && relX <= xMax && relY >= yMin && relY <= yMax) {
                if (manager.intakePiece(piece)) {
                    consumed++;
                }
            }
        }

        return consumed;
    }
}
