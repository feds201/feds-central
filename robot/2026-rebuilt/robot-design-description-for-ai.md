# Robot Design - 2026 REBUILT

> **Status:** Early design phase - details subject to change

## Overview

Ball-scoring robot for the REBUILT game. Collects fuel (balls) from the floor, stores them in a hopper, and shoots them at targets. Uses turret-less design - horizontal aiming requires rotating the entire robot.

## Mechanical Systems

### Drivetrain
- Swerve drive (same base as 2025 Stringray)
- Handles all horizontal aiming for shooter

### Intake
- Roller-based pickup on one side of the robot
- Collects balls from the floor
- Feeds into hopper

### Hopper
- Storage capacity: ~70 balls max
- Sits between intake and feeder

### Feeder
- Located at base of robot
- 2-wheel mechanism
- Pulls balls from hopper and feeds up to shooter

### Shooter
- Dual barrel design
- Single set of flywheel rollers (shared between barrels)
- Adjustable hood controls vertical angle of release
- No horizontal turret - robot rotation aims left/right

## Control Summary

| Mechanism | Actuation |
|-----------|-----------|
| Intake rollers | Motor (in/out) |
| Feeder wheels | Motor (feed rate) |
| Shooter flywheels | Motor (variable RPM for distance) |
| Hood | Motor/servo (angle adjustment) |
| Horizontal aim | Drivetrain rotation |

## Open Questions

- Exact hopper geometry and ball flow
- Hood angle range and resolution
- Sensor placement for ball counting/detection
- Intake deployment (fixed vs deployable?)
