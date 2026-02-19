package frc.robot.sim;

import frc.sim.core.FieldGeometry;
import frc.sim.core.PhysicsWorld;
import frc.sim.core.TerrainSurface;
import frc.sim.gamepiece.GamePieceConfig;
import frc.sim.gamepiece.GamePieceManager;
import org.ode4j.ode.DGeom;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Random;

/**
 * 2026 REBUILT field configuration.
 * Loads the field collision mesh, adds boundary walls,
 * and spawns starting fuel positions.
 */
public class RebuiltField {
    public static final double FIELD_LENGTH = 16.540; // meters (651.2in, matches generate_field.py)
    public static final double FIELD_WIDTH = 8.070;   // meters (317.7in, matches generate_field.py)

    // ── Hub geometry (from REBUILT game manual / generate_field.py) ─────────

    /** Distance from alliance wall to hub near face (meters). */
    private static final double HUB_DIST = 4.034;
    /** Hub footprint size (square, meters). */
    private static final double HUB_SIZE = 1.194;
    /** Top of rectangular hub box = bottom of hex funnel (meters). */
    private static final double HUB_BOX_TOP = 1.200;
    /** Funnel bottom circumradius (meters), flat-to-flat ≈ 0.52m. */
    private static final double HUB_BOT_HEX_CR = 0.300;

    /** Scoring sensor zone XY size — approximates hex opening (meters). */
    private static final double SCORING_ZONE_XY = 0.50;
    /** Scoring sensor zone Z thickness (meters). */
    private static final double SCORING_ZONE_Z = 0.30;

    // ── Neutral zone dimensions (from game manual) ─────────────────────────

    /** Neutral zone width along field X axis (meters). */
    private static final double NEUTRAL_ZONE_X = 1.83;
    /** Neutral zone length along field Y axis (meters). */
    private static final double NEUTRAL_ZONE_Y = 5.23;
    /** Center divider half-width (meters). */
    private static final double DIVIDER_HALF_WIDTH = 0.0508 / 2.0;

    /** Depot grid: rows along Y. */
    private static final int DEPOT_ROWS = 6;
    /** Depot grid: columns along X. */
    private static final int DEPOT_COLS = 4;

    /** Minimum neutral zone ball count (inclusive). */
    private static final int NEUTRAL_MIN_COUNT = 360;
    /** Range above minimum for random neutral zone count. */
    private static final int NEUTRAL_COUNT_RANGE = 41;

    /** Number of fuel balls pre-loaded in the hopper at start. */
    private static final int PRELOAD_COUNT = 8;

    private final FieldGeometry fieldGeometry;
    private final List<DGeom> scoringZones = new ArrayList<>();

    /**
     * Initialize the REBUILT field: load collision mesh, add boundary walls,
     * and create scoring sensor zones at each hub.
     *
     * @param world the physics world to add field geometry to
     */
    public RebuiltField(PhysicsWorld world) {
        fieldGeometry = new FieldGeometry(world);

        // Try to load field mesh from deploy directory
        try {
            InputStream meshStream = getClass().getResourceAsStream("/field_collision.obj");
            if (meshStream == null) {
                // Fall back to classpath (when running from deploy dir)
                meshStream = getClass().getClassLoader().getResourceAsStream("field_collision.obj");
            }
            if (meshStream != null) {
                fieldGeometry.loadMesh(meshStream, TerrainSurface.CARPET);
                System.out.println("[RebuiltField] Loaded field_collision.obj successfully");
            } else {
                System.err.println("[RebuiltField] WARNING: field_collision.obj NOT FOUND on classpath!");
            }
        } catch (IOException e) {
            System.err.println("[RebuiltField] Warning: Could not load field mesh: " + e.getMessage());
        }

        // Add boundary walls
        fieldGeometry.addBoundaryWalls(FIELD_LENGTH, FIELD_WIDTH, 0.5, 0.1);

        // Add scoring zone sensors
        createScoringZones(world);
    }

    /**
     * Create sensor boxes at the bottom of each hub's hex funnel for scoring detection.
     * A ball passing through the narrow funnel bottom triggers a score event.
     *
     * Hub geometry (from generate_field.py):
     *   HUB_DIST    = 4.034m  (alliance wall to hub near face)
     *   HUB_SIZE    = 1.194m  (hub footprint), hub_half = 0.597m
     *   HUB_BOX_TOP = 1.200m  (top of rectangular box = bottom of hex funnel)
     *   HUB_BOT_HEX_CR = 0.300m  (funnel bottom circumradius, flat-to-flat ≈ 0.52m)
     */
    private void createScoringZones(PhysicsWorld world) {
        double hubHalf = HUB_SIZE / 2.0;
        double blueHubCX = HUB_DIST + hubHalf;
        double hubCY = FIELD_WIDTH / 2.0;
        double funnelBottomZ = HUB_BOX_TOP;

        // Blue hub: funnel bottom
        DGeom blueGoal = world.addStaticBox(
                SCORING_ZONE_XY, SCORING_ZONE_XY, SCORING_ZONE_Z,
                blueHubCX, hubCY, funnelBottomZ
        );
        world.registerSensor(blueGoal);
        scoringZones.add(blueGoal);

        // Red hub: 180° rotation about field center (mirrors both X and Y)
        DGeom redGoal = world.addStaticBox(
                SCORING_ZONE_XY, SCORING_ZONE_XY, SCORING_ZONE_Z,
                FIELD_LENGTH - blueHubCX, FIELD_WIDTH - hubCY, funnelBottomZ
        );
        world.registerSensor(redGoal);
        scoringZones.add(redGoal);
    }

    /** Get the scoring zone sensor geoms for checking ball-in-goal contacts. */
    public List<DGeom> getScoringZones() {
        return Collections.unmodifiableList(scoringZones);
    }

    // Depot dimensions from generate_field.py
    private static final double DEPOT_D = 0.686;   // depth in X (27in)
    private static final double DEPOT_W = 1.070;   // width in Y (42in)
    private static final double DEPOT_H = 0.029;   // raised lip height (~1.125in)
    private static final double TOWER_BASE_W = 0.991;
    private static final double DEPOT_GAP_FROM_TOWER = 0.950; // along Y
    // Depot is against the alliance wall (x=0), 1.2m from tower along Y
    private static final double BLUE_DEPOT_Y1 = FIELD_WIDTH / 2.0 + TOWER_BASE_W / 2.0 + DEPOT_GAP_FROM_TOWER; // ~5.731

    /**
     * Spawn starting fuel balls on the field.
     *
     * <p>REBUILT field layout:
     * <ul>
     *   <li>Neutral zone: 360-400 balls in a grid across the center, split by a divider</li>
     *   <li>Blue depot: 6x4 grid of balls against the blue alliance wall</li>
     *   <li>Red depot: mirrored 6x4 grid against the red alliance wall</li>
     *   <li>Preload: 8 balls start in the hopper</li>
     * </ul>
     *
     * @param manager the game piece manager to spawn pieces into
     */
    public void spawnStartingFuel(GamePieceManager manager) {
        GamePieceConfig fuel = RebuiltGamePieces.FUEL;
        Random rand = new Random();
        double r = fuel.getRadius();          // 0.075m
        double diameter = r * 2;              // 0.15m
        double spacing = diameter + 0.005;    // small gap between ball centers
        // Max jitter per ball: half the gap, so two neighbors can't overlap
        // gap = spacing - diameter = 0.005m, maxJitter = gap/2 = 0.0025m
        double maxJitter = (spacing - diameter) / 2.0;

        double centerX = FIELD_LENGTH / 2.0;  // 8.255m
        double centerY = FIELD_WIDTH / 2.0;   // 4.035m

        // ── Neutral zone ──────────────────────────────────────────────────
        // Long axis along field WIDTH (Y), short axis along field LENGTH (X).
        // A center divider ~5cm wide splits the zone along the x-axis.

        int neutralCount = NEUTRAL_MIN_COUNT + rand.nextInt(NEUTRAL_COUNT_RANGE); // 360-400 inclusive

        int cols = (int) (NEUTRAL_ZONE_X / spacing);  // along X
        int rows = (int) (NEUTRAL_ZONE_Y / spacing);  // along Y

        double zoneStartX = centerX - NEUTRAL_ZONE_X / 2.0;
        double zoneStartY = centerY - NEUTRAL_ZONE_Y / 2.0;

        int spawned = 0;
        for (int row = 0; row < rows && spawned < neutralCount; row++) {
            for (int col = 0; col < cols && spawned < neutralCount; col++) {
                double baseX = zoneStartX + col * spacing + r;
                double baseY = zoneStartY + row * spacing + r;

                double x = baseX + (rand.nextDouble() * 2 - 1) * maxJitter;
                double y = baseY + (rand.nextDouble() * 2 - 1) * maxJitter;

                // Skip the center divider gap
                if (Math.abs(x - centerX) < DIVIDER_HALF_WIDTH + r) {
                    continue;
                }

                manager.spawnPiece(fuel, x, y, r + 0.001);
                spawned++;
            }
        }

        // ── Depots ────────────────────────────────────────────────────────
        // Against alliance wall (x=0 for blue), 1.2m from tower along Y.
        // Blue depot: x=0..0.686, y=5.731..6.801
        // 6 rows along Y, 4 cols along X, on top of the raised lip.
        double depotJitter = maxJitter; // same safe limit as neutral zone
        double depotZ = DEPOT_H + r + 0.001; // on top of the raised lip

        // Blue depot: against blue alliance wall (x=0)
        for (int row = 0; row < DEPOT_ROWS; row++) {
            for (int col = 0; col < DEPOT_COLS; col++) {
                double x = r + col * spacing + (rand.nextDouble() * 2 - 1) * depotJitter;
                double y = BLUE_DEPOT_Y1 + r + row * spacing + (rand.nextDouble() * 2 - 1) * depotJitter;
                manager.spawnPiece(fuel, x, y, depotZ);
            }
        }

        // Red depot: mirrored (against red wall, y mirrored)
        double redDepotY1 = FIELD_WIDTH - BLUE_DEPOT_Y1 - DEPOT_W;
        for (int row = 0; row < DEPOT_ROWS; row++) {
            for (int col = 0; col < DEPOT_COLS; col++) {
                double x = FIELD_LENGTH - r - col * spacing + (rand.nextDouble() * 2 - 1) * depotJitter;
                double y = redDepotY1 + r + row * spacing + (rand.nextDouble() * 2 - 1) * depotJitter;
                manager.spawnPiece(fuel, x, y, depotZ);
            }
        }

        // ── Preload ───────────────────────────────────────────────────────
        manager.setHeldCount(PRELOAD_COUNT);
    }

    /** Get the underlying field geometry (for adding additional obstacles). */
    public FieldGeometry getFieldGeometry() { return fieldGeometry; }
}
