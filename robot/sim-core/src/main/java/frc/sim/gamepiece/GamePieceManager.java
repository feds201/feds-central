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
    public static final double CHUNK_SIZE = 2.0;

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

    /** Speed above which a ball is considered "moving" and becomes a wake zone (m/s). */
    private static final double MOVING_SPEED_THRESHOLD = 0.5;
    /** Speed below which a ball is considered "settled" and eligible for sleep (m/s). */
    private static final double SLEEP_SPEED_THRESHOLD = 0.1;

    private static final double MOVING_SPEED_THRESHOLD_SQ = MOVING_SPEED_THRESHOLD * MOVING_SPEED_THRESHOLD;
    private static final double SLEEP_SPEED_THRESHOLD_SQ = SLEEP_SPEED_THRESHOLD * SLEEP_SPEED_THRESHOLD;

    // Reusable set to avoid per-tick allocation
    private final Set<Long> activeChunks = new HashSet<>();

    /**
     * Proximity-based body activation for performance using a Minecraft-style chunk system.
     *
     * <p>The field is divided into chunks (e.g., 2x2 meters). Active chunks include
     * the chunk the robot is in, chunks containing any fast-moving piece, and the
     * neighbors of all those chunks (neighborhood radius derived from {@code wakeRadius}).
     * Pieces in active chunks have their physics initialized (if needed) and enabled.
     * Pieces in inactive chunks that have settled are disabled to save CPU.
     *
     * <p>Call this each tick BEFORE {@link frc.sim.core.PhysicsWorld#step(double)}.
     *
     * @param robotPos    robot position on the field (2D)
     * @param wakeRadius  used to compute the chunk neighborhood radius (in meters)
     * @param sleepRadius (unused; sleep behavior is implicit: slow pieces outside active chunks are disabled)
     */
    public void updateProximity(Translation2d robotPos, double wakeRadius, double sleepRadius) {
        int chunkRadius = Math.max(1, (int) Math.ceil(wakeRadius / CHUNK_SIZE));
        activeChunks.clear();

        // Add robot chunk and its neighbors
        int robotCx = (int) Math.floor(robotPos.getX() / CHUNK_SIZE);
        int robotCy = (int) Math.floor(robotPos.getY() / CHUNK_SIZE);
        addChunkAndNeighbors(activeChunks, robotCx, robotCy, chunkRadius);

        // Add fast-moving pieces' chunks
        for (GamePiece piece : pieces) {
            if (!piece.isActive() || !piece.hasPhysics() || !piece.getBody().isEnabled()) continue;
            DVector3C vel = piece.getBody().getLinearVel();
            double speed2 = vel.get0() * vel.get0() + vel.get1() * vel.get1() + vel.get2() * vel.get2();
            if (speed2 >= MOVING_SPEED_THRESHOLD_SQ) {
                Translation3d pos = piece.getPosition3d();
                int cx = (int) Math.floor(pos.getX() / CHUNK_SIZE);
                int cy = (int) Math.floor(pos.getY() / CHUNK_SIZE);
                addChunkAndNeighbors(activeChunks, cx, cy, chunkRadius);
            }
        }

        // Enable/disable pieces based on active chunks
        for (GamePiece piece : pieces) {
            if (!piece.isActive()) continue;

            Translation3d pos = piece.getPosition3d();
            int cx = (int) Math.floor(pos.getX() / CHUNK_SIZE);
            int cy = (int) Math.floor(pos.getY() / CHUNK_SIZE);
            long chunkKey = packChunk(cx, cy);

            if (activeChunks.contains(chunkKey)) {
                if (!piece.hasPhysics()) {
                    piece.initializePhysics();
                }
                if (!piece.getBody().isEnabled()) {
                    piece.getBody().enable();
                }
            } else if (piece.hasPhysics() && piece.getBody().isEnabled()) {
                DVector3C vel = piece.getBody().getLinearVel();
                double speed2 = vel.get0() * vel.get0() + vel.get1() * vel.get1() + vel.get2() * vel.get2();
                if (speed2 < SLEEP_SPEED_THRESHOLD_SQ) {
                    piece.getBody().disable();
                }
            }
        }
    }

    private void addChunkAndNeighbors(Set<Long> chunks, int cx, int cy, int radius) {
        for (int i = -radius; i <= radius; i++) {
            for (int j = -radius; j <= radius; j++) {
                chunks.add(packChunk(cx + i, cy + j));
            }
        }
    }

    private long packChunk(int cx, int cy) {
        return ((long) cx << 32) | (cy & 0xFFFFFFFFL);
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
