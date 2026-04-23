package frc.sim.gamepiece;

import edu.wpi.first.math.geometry.Pose3d;
import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.math.geometry.Translation3d;
import frc.sim.core.PhysicsWorld;
import org.ode4j.math.DVector3;
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
        return launchPiece(config, position, velocity, new DVector3(0, 0, 0));
    }

    /**
     * Launch a piece from the robot with initial angular velocity (e.g., backspin).
     * @param config          piece type to launch
     * @param position        launch position (world frame)
     * @param velocity        launch velocity (world frame)
     * @param angularVelocity initial angular velocity (rad/s, world frame)
     * @return the launched piece, or null if nothing to launch
     */
    public GamePiece launchPiece(GamePieceConfig config, Translation3d position, Translation3d velocity, DVector3 angularVelocity) {
        if (heldCount <= 0) return null;

        heldCount--;
        String name = config.getName();
        GamePiece piece = new GamePiece(physicsWorld, config, position.getX(), position.getY(), position.getZ());
        piece.launch(position, velocity, angularVelocity);
        pieces.add(piece);
        piecesByType.computeIfAbsent(name, k -> new ArrayList<>()).add(piece);
        publishKeys.computeIfAbsent(name, k -> "Sim/GamePieces/" + k);
        growBuffer(name);
        return piece;
    }

    /** Update all piece states */
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

    /** Speed above which a ball is considered "moving" and becomes a wake zone (m/s). */
    private static final double MOVING_SPEED_THRESHOLD = 1.0;
    /** Speed below which a ball is considered "settled" and eligible for sleep (m/s). */
    private static final double SLEEP_SPEED_THRESHOLD = 0.1;

    private static final double MOVING_SPEED_THRESHOLD_SQ = MOVING_SPEED_THRESHOLD * MOVING_SPEED_THRESHOLD;
    private static final double SLEEP_SPEED_THRESHOLD_SQ = SLEEP_SPEED_THRESHOLD * SLEEP_SPEED_THRESHOLD;

    /**
     * Tight wake radius around fast-moving pieces — much smaller than the robot wake radius.
     * A flying ball only needs enough lookahead to not tunnel through its next neighbor.
     * Tuned just above (max-ball-speed × tick-dt) with a little slack.
     */
    private static final double MOVER_WAKE_RADIUS = 0.3;
    private static final double MOVER_SLEEP_RADIUS = 0.5;
    private static final double MOVER_WAKE_RADIUS_SQ = MOVER_WAKE_RADIUS * MOVER_WAKE_RADIUS;
    private static final double MOVER_SLEEP_RADIUS_SQ = MOVER_SLEEP_RADIUS * MOVER_SLEEP_RADIUS;

    /**
     * Proximity-based body activation for performance using a squared-distance wake radius.
     *
     * <p>A piece is kept awake (physics enabled) if its 2D position is within
     * {@code robotWakeRadius} of the robot, OR within the much tighter {@link #MOVER_WAKE_RADIUS}
     * of any currently-awake fast-moving piece. The asymmetry is deliberate: the robot needs
     * a predictable intake/collision volume, but a flying ball only needs enough lookahead
     * to not tunnel through its next neighbor — without the split, every collision-knocked
     * ball becomes its own big wake source and you get a chain reaction across a cluster.
     *
     * <p>Pieces outside BOTH sleep radii that have settled (speed below threshold) get
     * their ODE body disabled to save CPU. The wake/sleep bands form a hysteresis gap
     * to prevent flicker at the boundary.
     *
     * <p>Lazy physics init is preserved: {@link GamePiece#getPosition3d()} returns the
     * piece's spawn position when no body has been created yet, so distance checks on
     * never-initialized pieces are free. {@link GamePiece#initializePhysics()} is only
     * called the first time a piece enters the wake band.
     *
     * <p>Call this each tick BEFORE {@link frc.sim.core.PhysicsWorld#step(double)}.
     *
     * <p>Note: we compare squared distances against squared radii to avoid a per-piece
     * {@code sqrt()} — same circle, cheaper check.
     *
     * @param robotPos         robot position on the field (2D)
     * @param robotWakeRadius  pieces within this distance of the robot are enabled (meters)
     * @param robotSleepRadius pieces farther than this from the robot (and from any
     *                         fast-mover's sleep radius) that are settled get disabled
     */
    public void updateProximity(Translation2d robotPos, double robotWakeRadius, double robotSleepRadius) {
        final double robotWakeSq = robotWakeRadius * robotWakeRadius;
        final double robotSleepSq = robotSleepRadius * robotSleepRadius;
        final double robotX = robotPos.getX();
        final double robotY = robotPos.getY();

        // Gather fast-mover wake points: currently-awake pieces moving above the threshold.
        // Stored as flat (x, y) pairs to avoid per-point allocations. These get a MUCH tighter
        // wake radius than the robot (see MOVER_WAKE_RADIUS) — a flying ball only needs enough
        // lookahead to not tunnel through its nearest neighbor, not to wake the whole region.
        double[] moverXs = new double[pieces.size()];
        double[] moverYs = new double[pieces.size()];
        int moverCount = 0;

        for (GamePiece piece : pieces) {
            if (!piece.isActive() || !piece.hasPhysics() || !piece.getBody().isEnabled()) continue;
            DVector3C vel = piece.getBody().getLinearVel();
            double speed2 = vel.get0() * vel.get0() + vel.get1() * vel.get1() + vel.get2() * vel.get2();
            if (speed2 >= MOVING_SPEED_THRESHOLD_SQ) {
                Translation3d pos = piece.getPosition3d();
                moverXs[moverCount] = pos.getX();
                moverYs[moverCount] = pos.getY();
                moverCount++;
            }
        }

        // Apply wake/sleep/hysteresis to every active piece.
        for (GamePiece piece : pieces) {
            if (!piece.isActive()) continue;

            Translation3d pos = piece.getPosition3d();
            double px = pos.getX();
            double py = pos.getY();

            // Squared-distance to robot.
            double rdx = px - robotX;
            double rdy = py - robotY;
            double robotDistSq = rdx * rdx + rdy * rdy;

            // Squared-distance to nearest fast-mover.
            double moverDistSq = Double.POSITIVE_INFINITY;
            for (int i = 0; i < moverCount; i++) {
                double dx = px - moverXs[i];
                double dy = py - moverYs[i];
                double d2 = dx * dx + dy * dy;
                if (d2 < moverDistSq) moverDistSq = d2;
            }

            // Wake band: within robot's radius OR within mover's (much tighter) radius.
            boolean inWakeBand = robotDistSq < robotWakeSq || moverDistSq < MOVER_WAKE_RADIUS_SQ;
            // Sleep band: outside BOTH radii.
            boolean outsideSleepBand = robotDistSq > robotSleepSq && moverDistSq > MOVER_SLEEP_RADIUS_SQ;

            if (inWakeBand) {
                // Lazy-init physics on first entry.
                if (!piece.hasPhysics()) {
                    piece.initializePhysics();
                }
                if (!piece.getBody().isEnabled()) {
                    piece.getBody().enable();
                }
            } else if (outsideSleepBand && piece.hasPhysics() && piece.getBody().isEnabled()) {
                DVector3C vel = piece.getBody().getLinearVel();
                double speed2 = vel.get0() * vel.get0() + vel.get1() * vel.get1() + vel.get2() * vel.get2();
                if (speed2 < SLEEP_SPEED_THRESHOLD_SQ) {
                    piece.getBody().disable();
                }
            }
            // Hysteresis band (wakeSq <= minSq <= sleepSq): keep current state.
        }
    }

    /**
     * Disable all piece bodies (e.g., after spawning starting fuel so
     * they don't all simulate at once).
     */
    public void disableAll() {
        for (GamePiece piece : pieces) {
            if (piece.isActive() && piece.hasPhysics()) {
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
