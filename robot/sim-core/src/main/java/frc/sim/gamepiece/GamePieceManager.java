package frc.sim.gamepiece;

import edu.wpi.first.math.geometry.Pose3d;
import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.math.geometry.Translation3d;
import frc.sim.core.PhysicsWorld;
import org.ode4j.math.DVector3C;

import java.util.*;
import java.util.function.BiConsumer;

/**
 * Manages all game pieces in the simulation: spawning, tracking,
 * lifecycle, intake consumption, launching, and NT publishing.
 */
public class GamePieceManager {
    private final PhysicsWorld physicsWorld;
    private final List<GamePiece> pieces = new ArrayList<>();
    private final Map<String, List<GamePiece>> piecesByType = new HashMap<>();
    private final Map<String, String> publishKeys = new HashMap<>();
    private final Map<String, Pose3d[]> poseBuffers = new HashMap<>();

    // Counter-based intake tracking
    private int heldCount = 0;
    private int maxCapacity = 70; // hopper capacity


    public GamePieceManager(PhysicsWorld physicsWorld) {
        this.physicsWorld = physicsWorld;
    }

    /** Set the maximum number of pieces the robot can hold. */
    public void setMaxCapacity(int capacity) {
        this.maxCapacity = capacity;
    }

    /** Spawn a new game piece at the given position. */
    public GamePiece spawnPiece(GamePieceConfig config, double x, double y, double z) {
        GamePiece piece = new GamePiece(physicsWorld, config, x, y, z);
        pieces.add(piece);
        String name = config.getName();
        piecesByType.computeIfAbsent(name, k -> new ArrayList<>()).add(piece);
        publishKeys.computeIfAbsent(name, k -> "Sim/GamePieces/" + k);
        growBuffer(name);
        return piece;
    }

    /**
     * Consume a piece via counter-based intake.
     *
     * <p>Removes the piece from the physics world (disables its body and moves it
     * off-field) and increments the held counter. The piece remains in the internal
     * list but will be skipped by all active-piece queries.
     *
     * <p><b>Contract:</b> {@code spawnPiece()} adds to the physics world but does NOT
     * affect the held counter. {@code intakePiece()} removes from the world and increments
     * the counter. {@code launchPiece()} decrements the counter and spawns a new physics body.
     *
     * @param piece the piece to consume
     * @return true if the piece was consumed, false if at capacity or already off-field
     */
    public boolean intakePiece(GamePiece piece) {
        if (heldCount >= maxCapacity) return false;
        if (piece.isOffField()) return false;

        piece.consume();
        heldCount++;
        return true;
    }

    /**
     * Launch a piece from the robot (e.g., shooter).
     * Spawns a new physics body with the given velocity.
     * @param config piece type to launch
     * @param position launch position (world frame)
     * @param velocity launch velocity (world frame)
     * @return the launched piece, or null if nothing to launch
     */
    public GamePiece launchPiece(GamePieceConfig config, Translation3d position, Translation3d velocity) {
        if (heldCount <= 0) return null;

        heldCount--;
        String name = config.getName();
        GamePiece piece = new GamePiece(physicsWorld, config, position.getX(), position.getY(), position.getZ());
        piece.launch(position, velocity);
        pieces.add(piece);
        piecesByType.computeIfAbsent(name, k -> new ArrayList<>()).add(piece);
        publishKeys.computeIfAbsent(name, k -> "Sim/GamePieces/" + k);
        growBuffer(name);
        return piece;
    }

    /** Update all piece states (check for auto-disable / at rest). */
    public void update() {
        for (GamePiece piece : pieces) {
            if (piece.isActive()) {
                piece.updateState();
            }
        }
    }

    /** Grow the reusable pose buffer when a new piece is added for a type. */
    private void growBuffer(String typeName) {
        int needed = piecesByType.get(typeName).size();
        Pose3d[] existing = poseBuffers.get(typeName);
        if (existing == null || existing.length < needed) {
            poseBuffers.put(typeName, new Pose3d[needed]);
        }
    }

    /**
     * Publish all piece poses, grouped by type.
     * @param publisher callback receiving (key, poses) — the caller decides how to publish
     */
    public void publishPoses(BiConsumer<String, Pose3d[]> publisher) {
        for (Map.Entry<String, List<GamePiece>> entry : piecesByType.entrySet()) {
            String typeName = entry.getKey();
            List<GamePiece> typePieces = entry.getValue();
            Pose3d[] buffer = poseBuffers.get(typeName);

            int count = 0;
            for (GamePiece piece : typePieces) {
                if (piece.isActive()) {
                    buffer[count++] = piece.getPose3d();
                }
            }

            Pose3d[] result = (count == buffer.length) ? buffer : Arrays.copyOf(buffer, count);
            publisher.accept(publishKeys.get(typeName), result);
        }
    }

    /** Get all pieces (including consumed). */
    public List<GamePiece> getPieces() { return pieces; }

    /** Get active (non-consumed) pieces. */
    public List<GamePiece> getActivePieces() {
        List<GamePiece> active = new ArrayList<>();
        for (GamePiece piece : pieces) {
            if (piece.isActive()) active.add(piece);
        }
        return active;
    }

    // Reusable lists to avoid allocation every tick
    private final List<double[]> wakeZones = new ArrayList<>();
    private static final int INITIAL_WAKE_ZONE_POOL = 32;
    private final List<double[]> wakeZonePool = new ArrayList<>();
    private int wakeZonePoolIndex = 0;

    /** Speed above which a ball is considered "moving" and becomes a wake zone (m/s). */
    private static final double MOVING_SPEED_THRESHOLD = 0.5;
    /** Speed below which a ball is considered "settled" and eligible for sleep (m/s). */
    private static final double SLEEP_SPEED_THRESHOLD = 0.1;

    private static final double MOVING_SPEED_THRESHOLD_SQ = MOVING_SPEED_THRESHOLD * MOVING_SPEED_THRESHOLD;
    private static final double SLEEP_SPEED_THRESHOLD_SQ = SLEEP_SPEED_THRESHOLD * SLEEP_SPEED_THRESHOLD;

    {
        // Pre-allocate wake zone coordinate pairs to avoid per-tick allocation
        for (int i = 0; i < INITIAL_WAKE_ZONE_POOL; i++) {
            wakeZonePool.add(new double[2]);
        }
    }

    /** Borrow a double[2] from the pool, growing the pool if needed. */
    private double[] borrowWakeZone(double x, double y) {
        if (wakeZonePoolIndex >= wakeZonePool.size()) {
            wakeZonePool.add(new double[2]);
        }
        double[] zone = wakeZonePool.get(wakeZonePoolIndex++);
        zone[0] = x;
        zone[1] = y;
        return zone;
    }

    /**
     * Proximity-based body activation for performance.
     *
     * <p>Wake zones include the robot position plus every fast-moving piece
     * (speed &gt; 0.5 m/s). Bodies within {@code wakeRadius} of any wake zone are
     * enabled; bodies beyond {@code sleepRadius} of ALL wake zones that have
     * settled (speed &lt; 0.1 m/s) are disabled. This means only pieces near the
     * action are simulated — distant settled balls cost nearly zero CPU.
     *
     * <p>Example: if the shooter launches a ball at 20 m/s, the ball itself becomes
     * a wake zone, so pieces near its landing spot wake up for collision response.
     *
     * <p>Call this each tick BEFORE {@link frc.sim.core.PhysicsWorld#step(double)}.
     *
     * @param robotPos    robot position on the field (2D)
     * @param wakeRadius  enable bodies within this distance of a wake zone (meters)
     * @param sleepRadius disable settled bodies beyond this distance of ALL wake zones (meters)
     */
    public void updateProximity(Translation2d robotPos, double wakeRadius, double sleepRadius) {
        double wakeR2 = wakeRadius * wakeRadius;
        double sleepR2 = sleepRadius * sleepRadius;

        // Build wake zones from pool: robot position + every fast-moving ball
        wakeZones.clear();
        wakeZonePoolIndex = 0;
        wakeZones.add(borrowWakeZone(robotPos.getX(), robotPos.getY()));

        for (GamePiece piece : pieces) {
            if (!piece.isActive() || !piece.getBody().isEnabled()) continue;
            DVector3C vel = piece.getBody().getLinearVel();
            double speed2 = vel.get0() * vel.get0() + vel.get1() * vel.get1() + vel.get2() * vel.get2();
            if (speed2 >= MOVING_SPEED_THRESHOLD_SQ) {
                DVector3C pos = piece.getBody().getPosition();
                wakeZones.add(borrowWakeZone(pos.get0(), pos.get1()));
            }
        }

        // Wake/sleep pieces based on proximity to ANY wake zone
        for (GamePiece piece : pieces) {
            if (!piece.isActive()) continue;

            DVector3C pos = piece.getBody().getPosition();
            double px = pos.get0();
            double py = pos.get1();

            // Find closest wake zone (squared distance avoids sqrt)
            double minDist2 = Double.MAX_VALUE;
            for (double[] zone : wakeZones) {
                double dx = px - zone[0];
                double dy = py - zone[1];
                double d2 = dx * dx + dy * dy;
                if (d2 < minDist2) minDist2 = d2;
            }

            if (minDist2 <= wakeR2) {
                if (!piece.getBody().isEnabled()) {
                    piece.getBody().enable();
                }
            } else if (minDist2 > sleepR2 && piece.getBody().isEnabled()) {
                // Only sleep if piece has actually settled — reuse the velocity
                // we already know is below MOVING threshold (otherwise it would
                // be a wake zone itself), so just check the tighter sleep threshold
                DVector3C vel = piece.getBody().getLinearVel();
                double speed2 = vel.get0() * vel.get0() + vel.get1() * vel.get1() + vel.get2() * vel.get2();
                if (speed2 < SLEEP_SPEED_THRESHOLD_SQ) {
                    piece.getBody().disable();
                }
            }
        }
    }

    /**
     * Disable all piece bodies (e.g., after spawning starting fuel so
     * they don't all simulate at once).
     */
    public void disableAll() {
        for (GamePiece piece : pieces) {
            if (piece.isActive()) {
                piece.getBody().disable();
            }
        }
    }

    /** Get current held count (intake counter). */
    public int getHeldCount() { return heldCount; }

    /** Set the held count directly (e.g., for starting configuration). */
    public void setHeldCount(int count) { this.heldCount = count; }

    /** Get total number of pieces spawned (including consumed). */
    public int getTotalPieceCount() { return pieces.size(); }
}
