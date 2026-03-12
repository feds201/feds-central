# Robot Design - 2026 REBUILT

> **Status:** Late design phase / starting manufacturing - some details subject to change

## Overview

Ball-scoring robot for the REBUILT game. Collects fuel (balls) from the floor, stores them in a hopper, and shoots them at targets. Uses turret-less design - horizontal aiming requires rotating the entire robot.

## Systems

### Drivetrain
- Swerve drive (same design as 2025 Stringray, with some changes to gear ratios)
- Handles all horizontal aiming / angling for shooter (ie we do not have a turret)

### Intake
- Roller-based pickup on one side of the robot
- Collects balls from the floor
- Feeds into hopper
- Limelight 3 aimed at the floor does ball detection

### Hopper
- Storage capacity: ~70 balls max in theory (currently 25)
- Sits between intake and feeder

### Feeder
- Located on the backside of the robot
- a bunch of wheels controlled by a few different motors
- Pulls balls from hopper and feeds up to shooter

### Shooter
- Dual barrel design
- Single set of flywheel rollers (shared between barrels)
- Adjustable hood controls vertical angle of release
- No horizontal turret - robot rotation aims left/right
- Limelight 4 with Hailo 8 coprocessor detects APRIL tags to aims us towards the target

### Climber (not designed yet)
- On one side of the robot
- Hook design that can pull it up off the ground
- uses the Limelight 4 to detect APRIL tags for adjusting the robot position

## Simulation

The robot has a full physics simulation that lets you test driving, intake, shooting, and scoring without a real robot. It uses a **dual-engine architecture**:

- **MapleSim (IronMaple)** -- handles all swerve drivetrain physics: motor models, tire dynamics, encoder/gyro feedback. This is the proven FRC drivetrain simulator.
- **ODE4J (via the sim-core library)** -- handles game piece physics (spawning, intake, launching, scoring), field collisions (walls, bumps, ramps), and 3D terrain effects.

`RebuiltSimManager` orchestrates both engines each tick at 50 Hz (20ms).

### Running the Simulation

From the `robot/2026-rebuilt` directory:

```bash
./gradlew simulateJava
```

Or use the WPILib VS Code extension: open the command palette and run **WPILib: Simulate Robot Code**.

Connect AdvantageScope to see the 3D view with the robot and ~400 fuel balls on the field.

### What You'll See

- The robot driving around the REBUILT field with swerve physics
- ~400 fuel balls spawned across the neutral zone and depots (plus 8 pre-loaded in the hopper)
- Balls getting picked up when you drive over them with the intake running
- Balls launching from the shooter with hood angle and velocity
- Balls scoring when they enter the hub funnel
- The robot riding over bumps and ramps (chassis pitch/roll from ODE4J)

### Per-Tick Simulation Loop

Each call to `RebuiltSimManager.periodic()`:

1. **MapleSim steps the drivetrain** -- motor physics, tire model, encoder feedback
2. **Read pose and chassis speeds** from MapleSim
3. **Convert robot-relative speeds to world frame** (rotation by yaw angle)
4. **Set ODE4J chassis velocity** -- corrective forces to match MapleSim (kinematic follower). ODE4J handles Z/pitch/roll from ramp contacts.
5. **Proximity activation** -- wake game piece bodies near the robot; distant settled balls stay asleep (performance: ~400 pieces but only ~20 active)
6. **Check intake zone** (before physics step -- prevents re-consuming just-launched balls)
7. **ODE4J physics step** -- adaptive sub-stepping prevents fast balls tunneling through thin walls
8. **Sync gyro** from MapleSim pose
9. **Update game piece states**
10. **Check scoring sensor zones** -- balls entering the hub funnel trigger score events
11. **Update shooter** -- launch balls with cooldown when shooter is firing
12. **Publish telemetry** to NetworkTables / AdvantageKit (robot pose, component poses, game piece poses, score, ground clearance)

### Game Piece Flow

```
Field spawn -> proximity wake -> intake zone check -> consume (hopper counter++)
  -> shoot (counter--, new body with launch velocity) -> flight physics
  -> scoring zone contact -> consume & record score
```

The hopper is counter-based (no internal physics). The intake zone is a robot-relative bounding box that checks for overlapping balls when the intake rollers are active. Launching spawns a new physics body with velocity computed from the hood angle, flywheel speed, and robot heading.

### Key Classes

| Class | Location | Role |
|---|---|---|
| `RebuiltSimManager` | `src/main/java/frc/robot/sim/` | Orchestrates MapleSim + ODE4J each tick |
| `RebuiltField` | `src/main/java/frc/robot/sim/` | REBUILT field layout, scoring zones, fuel spawning |
| `RebuiltGamePieces` | `src/main/java/frc/robot/sim/` | Fuel ball config (sphere, r=0.075m, 0.2kg) |
| `ShooterSim` | `src/main/java/frc/robot/sim/` | Bridges shooter subsystem state to game piece launches |

The sim-core library (in `robot/sim-core/`) provides the underlying physics engine, chassis simulation, game piece management, and telemetry. See `robot/sim-core/README.md` for details.

### Tuning Placeholder Values

`RebuiltSimManager` has clearly marked placeholder constants at the top of the file. These should be updated as the physical robot design is finalized:

To tune these, open `RebuiltSimManager.java` and `ShooterSim.java`, update the constants, and re-run the sim. No other files need to change.
