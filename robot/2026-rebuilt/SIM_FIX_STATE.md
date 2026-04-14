# Sim Fix — Full State Document

> Written so the team lead can resume after a conversation history clear.
> Teammates are still alive under team `sim-fix`.

---

## What We're Doing

Fixing the FRC robot simulation for Team FEDS 201 (2026 game "REBUILT"). Two main goals:
1. Switch from state-enum-based sim to motor-based sim (so the sim doesn't break when students refactor state machines)
2. Fix simgui keyboard mappings

## The Robot

Ball-scoring swerve-drive robot. Ball path: Intake (rack & pinion) -> Hopper -> Spindexer -> Feeder -> Shooter (dual barrel, adjustable hood). No turret — robot rotates to aim. Uses TalonFX (Kraken X60) motors everywhere.

## Architecture

Dual-engine sim:
- **MapleSim** (IronMaple): owns swerve drivetrain physics. DO NOT TOUCH.
- **ODE4J** (via sim-core library): owns game pieces, field collisions, vision, scoring.
- **RebuiltSimManager**: orchestrates both engines every 20ms tick.

Key files:
- `robot/2026-rebuilt/src/main/java/frc/robot/sim/RebuiltSimManager.java` — main orchestrator, ALL motor sims live here
- `robot/2026-rebuilt/src/main/java/frc/robot/sim/ShooterSim.java` — bridges shooter to game piece launches
- `robot/2026-rebuilt/src/main/java/frc/robot/sim/RebuiltField.java` — field layout (unchanged)
- `robot/2026-rebuilt/src/main/java/frc/robot/sim/RebuiltGamePieces.java` — fuel ball config (unchanged)
- `robot/sim-core/` — reusable physics library (modified for Magnus/backspin)

## Design Decisions

### Motor Simulation
ALL 6 non-drivetrain motors are simmed in RebuiltSimManager using the same pattern:
1. `talonFXSimState.setSupplyVoltage(batteryVoltage)`
2. `physicsSim.setInputVoltage(voltage from talonFXSimState)` — NEGATED for inverted motors
3. `physicsSim.update(0.02)`
4. `talonFXSimState.setRawRotorPosition(gearRatio * sim position)`
5. `talonFXSimState.setRotorVelocity(gearRatio * sim velocity)`

Motor sim classes used:
| Motor | Sim Class | Notes |
|-------|-----------|-------|
| Shooter (1 leader TalonFX) | DCMotorSim | Velocity + position for animation |
| Hood (1 TalonFX) | SingleJointedArmSim | Gravity, angle limits 35.5-67.4 deg |
| Feeder (1 TalonFX) | DCMotorSim | |
| Spindexer (1 TalonFX) | DCMotorSim | |
| Intake deploy (1 TalonFX) | DCMotorSim | Was in IntakeSubsystem, now consolidated here |
| Intake roller (1 TalonFX) | DCMotorSim | Was in IntakeSubsystem, now consolidated here |

### Motor Inversion
4 motors are inverted (Clockwise_Positive): shooter, hood, feeder, spindexer — voltage is NEGATED.
2 motors are NOT inverted (CounterClockwise_Positive): intake deploy, intake roller — voltage is NOT negated.

### Battery Simulation
BatterySim + RoboRioSim aggregate current draws from all 6 motors (shooter counts x4 for followers). Supply voltage set BEFORE motor sim steps.

### Shooting Gate
Balls launch when: `shooterMotorSim velocity > SHOOTER_VELOCITY_THRESHOLD_RPS AND feederMotorSim velocity > FEEDER_VELOCITY_THRESHOLD_RPS` (forward only — feeder washing machine reverse stops shooting).

### Launch Speed
Dynamic: `shooterMotorSim.getAngularVelocityRadPerSec() * SHOOTER_WHEEL_RADIUS_M * SLIP_FACTOR * BALL_TRANSLATIONAL_FRACTION`
- SLIP_FACTOR = 0.8 (wheel-to-ball friction efficiency)
- BALL_TRANSLATIONAL_FRACTION = 0.4 (hollow sphere energy split for single-sided roller)

### Backspin + Magnus (sim-core changes)
- GamePieceManager.launchPiece() has overload accepting angular velocity
- ShooterSim computes backspin axis (cross of launch dir and up) and magnitude
- Magnus force applied per-tick to all non-sleeping pieces: `F = MAGNUS_COEFFICIENT * cross(spin, velocity)`
- MAGNUS_COEFFICIENT = 0.5 * 1.225 * 0.5 * pi * 0.075^2

### Component Poses
All animation angles read directly from motor sim positions (no accumulators). Zero angle accumulators in RebuiltSimManager.

### Shared Constants
- Hood software limit: `RobotMap.ShooterConstants.HOOD_FORWARD_SOFT_LIMIT_ROT` (30.0) — shared between ShooterHood and sim
- Intake extend position: `IntakeSubsystem.EXTENDED_ROTATIONS` (18.0) — public static, shared

### Constants with TODO Placeholders (in RebuiltSimManager)
All MOIs use formulas:
- SHOOTER_MOI = 0.5 * 3.0 * 0.05 * 0.05 (3kg, 5cm radius)
- HOOD_MOI = SingleJointedArmSim.estimateMOI(0.23, 3.0) (23cm arm, 3kg)
- FEEDER_MOI = 4 * 0.5 * 0.75 * 0.025 * 0.025 (4 axles, 0.75kg each, 2.5cm radius)
- SPINDEXER_MOI = 2 * 0.5 * 0.5 * 0.04 * 0.04 (2 axles, 0.5kg each, 4cm radius)
- INTAKE_DEPLOY_MOI and INTAKE_ROLLER_MOI — placeholder values, need real specs

Other TODO placeholders: gear ratios, velocity thresholds, all geometry values.

### Keyboard Layout (simgui-ds.json)
Right side grouped by row = ball path through robot:
- Bottom row (`, . /`): Intake — extend+rollers, retract, reverse rollers
- Middle row (`;`): Feeder — reverse feeder+spindexer
- Top row (`P O [ ]`): Shooting — P=layup, O=halfcourt, [=aim hub+spinup, ]=gated fire
- Left side (WASD QE X): Driving (unchanged)

### Virtual Goal
`Sim/VirtualGoal` published as Pose3d using ShootOnTheMove.calculateVirtualGoal().

### Sim Code in Subsystems
All subsystem files that expose sim accessors have visual delimiters:
```
// ////////////////////////////////////////////////////////////////////////
// SIMULATION SUPPORT — Code below is used only by the simulator
// ////////////////////////////////////////////////////////////////////////
```
Files: IntakeSubsystem, ShooterWheels, ShooterHood, Feeder, Spindexer.
IntakeSubsystem.simulationPeriodic() has been DELETED — all motor sim is in RebuiltSimManager.

### Obsolete Telemetry Removed
- Robot/Shooter/FeederOn (was state-based boolean, misleading with PRUN)
- Robot/Shooter/SpindexerOn (same)
- Robot/Shooter/IsShooting (same)
- Robot/Intake/Extended (replaced with Robot/Intake/ExtensionPct)

### Debug Telemetry Added
16 entries under `Sim/Debug/` — motor velocities, voltages, gate status, battery, fuel held, intake zone active, hood angle, etc.

---

## Testing Status

### First Test Results (before motor consolidation/inversion fix)
- Driving: WORKS (WASD/QE)
- Intake component not moving: BROKEN — was caused by IntakeSubsystem's broken simulationPeriodic() + missing supply voltage. NOW FIXED (consolidated into RebuiltSimManager).
- Shooting ([+]): BROKEN — shooting gate never opened because motor velocities were negative (inversion). NOW FIXED (voltage negation).
- Hood not moving: BROKEN — same inversion issue. NOW FIXED.
- Feeder/spindexer/shooter/roller animations: WORKING (but velocities were negative)
- FuelHeld stayed at 8: BROKEN — shooting gate never opened

### Current State: UNTESTED after consolidation + inversion fix
Need to restart sim and retest ALL of:
1. Intake extends/retracts (hold `,` / press `.`)
2. Intake picks up balls when driving over them
3. Shooting works (hold `[` to aim, hold `]` to fire)
4. Layup works (hold `P`)
5. Halfcourt works (hold `O`)
6. Hood angle changes
7. Virtual goal visible in AdvantageScope
8. Component animations (all mechanisms)
9. Balls arc with backspin/Magnus
10. Scoring when balls enter hub

---

## What's Left To Do

1. **TEST the sim** — restart and go through the test list above
2. **Fix any remaining bugs** found during testing
3. **Update docs** (Architecture.mdx + QuickStart.mdx) — they're stale:
   - Keyboard layout completely changed
   - Motor sim consolidation (all in RebuiltSimManager, no split)
   - IntakeSubsystem.simulationPeriodic() deleted
   - Obsolete telemetry removed, ExtensionPct added
   - Debug telemetry section
4. **Final review** — one more cross-review pass after everything works

---

## Active Teammates (team: sim-fix)

| Name | Role | Status |
|------|------|--------|
| ws1-planner | Planned the motor sim refactor | Idle, can be shut down |
| ws1-reviewer | Reviews code, coordinates with executor | Active, responsive |
| ws1-executor | Implements changes | Unresponsive lately — ws1-reviewer has been implementing directly |
| ws2-planner | Planned simgui.json | Idle, can be shut down |
| ws2-reviewer | Reviewed simgui.json | Idle, can be shut down |
| ws2-executor | Created simgui.json | Idle, can be shut down |
| ws3-planner | Planned virtual goal | Idle, can be shut down |
| ws3-reviewer | Reviewed virtual goal | Idle, can be shut down |
| ws3-executor | Implemented virtual goal | Idle, can be shut down |
| ws4-docs | Updated docs | Idle, can be shut down |
| ws5-cleanup | Cleanup pass | Idle, can be shut down |
| cross-reviewer-1 | First cross-review | Idle, can be shut down |
| cross-reviewer-2 | Second cross-review | Idle, can be shut down |
| magnus-dev | Implemented backspin + Magnus | Idle, can be shut down |

**Recommended to keep alive:** ws1-reviewer (most context, has been doing executor work too).
**Safe to shut down:** All others.

---

## User Instructions (MUST FOLLOW)

1. **NEVER look at code yourself** — use teammates for ALL code reading, searching, and editing. Looking at code bloats conversation history and leads you astray.
2. **NEVER suggest committing without testing** — the sim must be tested and working first.
3. **NEVER run commands without user approval** — don't just fire off builds or greps.
4. **Do NOT fix robot subsystem code** unless it's sim-related (sim accessors, sim delimiter sections).
5. **Do NOT touch sim_models/** (AdvantageScope 3D configs).
6. **ALL constants in RebuiltSimManager** with `// TODO update placeholder` and formula + comment.
7. **Don't hardcode computed values** — always put the formula so it's clear what the inputs are.
8. **Don't use "flywheel" in variable names** — just say "shooter". The flywheel is part of the shooter wheel, not a separate component.
9. **Hood angles in degrees** (stored as DEG, converted to radians at point of use).
10. **Use teammates, not subagents** — teammates persist for follow-up questions.
11. **Keyboard layout philosophy**: left side = driving, right side = mechanisms grouped by row (bottom=intake, middle=feeder, top=shooting). Further right = more automation.
12. **Don't duplicate constants** — if a value exists in robot code, import it. Sim-only values stay in RebuiltSimManager.
13. **Sim code in subsystems gets visual delimiters** (////////) with javadocs.
