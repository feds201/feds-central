# sim-core -- FRC Physics Simulation Framework

Reusable rigid body physics library for FRC robot simulation, built on [ODE4J](https://github.com/tzaeschke/ode4j). Provides 3D field collision, game piece lifecycle management, terrain surface materials, and chassis simulation -- independent of any specific game or robot design.

Used by the 2026 REBUILT robot sim (and the 2025 Reefscape sim before it). Designed to run alongside MapleSim (which handles drivetrain/tire physics), but can also drive the chassis standalone with its own force-based motor model.

## Module Structure

```
src/main/java/frc/sim/
├── core/                        -- Physics engine wrapper
│   ├── PhysicsWorld.java          ODE4J world, collision detection, adaptive sub-stepping
│   ├── FieldGeometry.java         Loads OBJ meshes as collision trimeshes + boundary walls
│   ├── TerrainSurface.java        Contact material presets (CARPET, WALL, RUBBER, POLYCARBONATE)
│   └── SimMath.java               ODE4J <-> WPILib type conversions (Euler angles, Pose3d)
│
├── chassis/                     -- Robot body simulation
│   ├── ChassisSimulation.java     ODE4J rigid body (force-based, kinematic, or velocity-follow modes)
│   ├── ChassisConfig.java         Immutable config (mass, MOI, bumper dimensions, module positions)
│   └── SwerveModuleSim.java       DC motor model: voltage -> wheel force (standalone, not used with MapleSim)
│
├── gamepiece/                   -- Game piece physics and lifecycle
│   ├── GamePiece.java             Individual piece with ODE4J body (sphere, cylinder, or box)
│   ├── GamePieceConfig.java       Piece properties (shape, mass, radius, bounce, friction)
│   ├── GamePieceManager.java      Spawning, counter-based intake, launching, proximity sleep/wake
│   ├── IntakeZone.java            Robot-relative bounding box for intake detection
│   └── LaunchParameters.java      Computes 3D launch velocity from hood angle + robot heading
│
├── scoring/
│   └── ScoringTracker.java        Score accumulator with event log
│
└── telemetry/
    ├── SimTelemetry.java          Collects robot pose + component poses for AdvantageScope
    └── GroundClearance.java       Tracks chassis height above ground (ramp/bump detection)
```

## Key Features

### Adaptive Sub-stepping
Fast objects (e.g., a ball shot at 30 m/s) can tunnel through thin walls in a single 20ms step. `PhysicsWorld.step()` automatically detects the fastest body and subdivides the timestep so no object moves more than `minCollisionThickness` (default 0.1m) per sub-step. Most frames use 1 sub-step (zero overhead); extra sub-steps only kick in during fast events like shooter launches.

### Proximity Sleep/Wake
With 360-400 balls on the field, simulating every one each tick is expensive. `GamePieceManager.updateProximity()` only enables bodies near the robot (within `wakeRadius`). Distant settled balls are disabled and cost nearly zero CPU. Fast-moving balls (like a launched shot) also become wake zones, so pieces near the landing area wake up for collision response.

### Sensor Geoms
Scoring zones use ODE4J sensors -- they detect overlap with game piece bodies without creating contact joints. This lets balls pass through the scoring zone trigger while the system records the score event.

### Terrain Surfaces
Four built-in contact material presets control friction, bounce, and softness:
- `CARPET` -- high friction, low bounce, soft contacts (prevents jitter in ball clusters)
- `WALL` -- hard contacts, moderate bounce
- `RUBBER` -- high friction, moderate bounce
- `POLYCARBONATE` -- low friction, moderate bounce

Per-geom surface overrides let you assign different materials to different field elements.

### Chassis Control Modes
`ChassisSimulation` supports three modes:
- **Velocity-follow** (`setVelocity`) -- kinematic follower for an external drivetrain sim (MapleSim). Applies corrective forces to match desired velocity; ODE4J still handles Z/pitch/roll from ramp contacts.
- **Force-based** (`applyForces`) -- apply pre-computed world-frame forces directly.
- **Standalone motor model** (`SwerveModuleSim`) -- DC motor voltage-to-force model for running without MapleSim.

## Usage

Basic setup pattern for a game-specific simulation:

```java
// 1. Create the physics world
PhysicsWorld world = new PhysicsWorld();

// 2. Load field geometry
FieldGeometry field = new FieldGeometry(world);
field.loadMesh(getClass().getResourceAsStream("/field_collision.obj"), TerrainSurface.CARPET);
field.addBoundaryWalls(16.54, 8.07, 0.5, 0.1);

// 3. Create chassis
ChassisConfig config = new ChassisConfig.Builder()
    .withModulePositions(modulePositions)
    .withRobotMass(55.0)
    .withRobotMOI(6.0)
    .withBumperSize(0.8, 0.8, 0.25)
    .build();
ChassisSimulation chassis = new ChassisSimulation(world, config, startPose);

// 4. Spawn game pieces
GamePieceManager pieces = new GamePieceManager(world);
pieces.spawnPiece(myGamePieceConfig, x, y, z);

// 5. Each tick (50 Hz):
chassis.setVelocity(vx, vy, omega, 0.02);       // follow MapleSim
pieces.updateProximity(robotPos, 1.5, 3.0);      // wake nearby balls
world.step(0.02);                                 // physics step
pieces.update();                                  // update piece states
```

## Dependencies

| Dependency | Version | Purpose |
|---|---|---|
| ODE4J | 0.5.4 | Rigid body physics engine |
| JavaGL OBJ | 0.4.0 | OBJ mesh file loader |
| WPILib | 2026.1.1 | Geometry types (Pose3d, Translation3d, etc.) |
| JUnit 5 | 5.10.1 | Testing |

Java 17 required.

## Running Tests

```bash
cd robot/sim-core
./gradlew test
```

Test report is generated at `build/reports/tests/test/index.html`.

## API Overview

| Class | What it does |
|---|---|
| `PhysicsWorld` | Creates the ODE4J world with gravity, ground plane, collision detection. Call `step(dt)` each tick. Load field meshes with `loadFieldMesh()`. Register sensors with `registerSensor()`. |
| `FieldGeometry` | Loads an OBJ file as a static collision trimesh. Adds boundary walls with `addBoundaryWalls()`. |
| `TerrainSurface` | Contact material (friction, bounce, softness). Assign to geoms via `PhysicsWorld.setGeomSurface()`. |
| `SimMath` | Converts between ODE4J rotation matrices and WPILib `Pose3d` / `Rotation3d`. |
| `ChassisSimulation` | Robot rigid body. Use `setVelocity()` for kinematic following, `applyForces()` for direct force control. Outputs `getPose2d()` / `getPose3d()`. |
| `ChassisConfig` | Immutable builder-pattern config: mass, MOI, bumper dimensions, module positions. |
| `SwerveModuleSim` | Standalone DC motor model (voltage to wheel force). Not used when MapleSim handles the drivetrain. |
| `GamePiece` | Single physics body. States: active, consumed (off-field), launched (in flight). |
| `GamePieceConfig` | Immutable builder-pattern config: shape (SPHERE/CYLINDER/BOX), mass, radius, bounce, friction. |
| `GamePieceManager` | Spawns pieces, manages counter-based intake (`intakePiece`), launches (`launchPiece`), proximity sleep/wake, and pose publishing. |
| `IntakeZone` | Robot-relative bounding box. Each tick, checks if any active piece overlaps the zone and the intake is running. |
| `LaunchParameters` | Computes world-frame launch position and velocity from hood angle, launch speed, and robot pose/heading. |
| `ScoringTracker` | Accumulates score events with timestamps. |
| `SimTelemetry` | Collects robot and component poses for AdvantageScope visualization. |
| `GroundClearance` | Reports chassis height above ground (detects ramp climbing, airborne state). |
