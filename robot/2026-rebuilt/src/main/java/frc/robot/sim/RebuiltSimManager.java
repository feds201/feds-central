package frc.robot.sim;

import static edu.wpi.first.units.Units.*;

import com.ctre.phoenix6.hardware.CANcoder;
import com.ctre.phoenix6.hardware.TalonFX;
import com.ctre.phoenix6.sim.CANcoderSimState;
import com.ctre.phoenix6.sim.Pigeon2SimState;
import com.ctre.phoenix6.sim.TalonFXSimState;
import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Pose3d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.geometry.Rotation3d;
import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.math.geometry.Translation3d;
import edu.wpi.first.math.kinematics.ChassisSpeeds;
import edu.wpi.first.math.system.plant.DCMotor;
import edu.wpi.first.units.measure.*;

import org.ironmaple.simulation.SimulatedArena;
import org.ironmaple.simulation.drivesims.SwerveDriveSimulation;
import org.ironmaple.simulation.drivesims.SwerveModuleSimulation;
import org.ironmaple.simulation.drivesims.configs.DriveTrainSimulationConfig;
import org.ironmaple.simulation.drivesims.configs.SwerveModuleSimulationConfig;
import org.ironmaple.simulation.motorsims.SimulatedBattery;
import org.ironmaple.simulation.motorsims.SimulatedMotorController;
import org.littletonrobotics.junction.Logger;
import org.ode4j.ode.DBody;
import org.ode4j.ode.DGeom;
import frc.robot.subsystems.intake.Intake;
import frc.robot.subsystems.shooter.Shooter;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.subsystems.swerve.generated.TunerConstants;

import java.util.List;
import java.util.Set;

import frc.sim.chassis.ChassisSimulation;
import frc.sim.chassis.ChassisConfig;
import frc.sim.gamepiece.GamePieceManager;
import frc.sim.gamepiece.IntakeZone;
import frc.sim.scoring.ScoringTracker;
import frc.sim.telemetry.GroundClearance;
import frc.sim.telemetry.SimTelemetry;

/**
 * Orchestrates the full simulation for the 2026 REBUILT game.
 *
 * MapleSim owns the entire drivetrain (motor physics, tire model, chassis
 * dynamics).
 * The ODE4J chassis is a kinematic follower that exists only for game piece
 * collisions.
 *
 * Architecture:
 * - MapleSim: steps drivetrain, computes pose and velocities, writes encoder
 * state
 * - ODE4J chassis: kinematically follows MapleSim pose, provides collision body
 * for game pieces
 */
public class RebuiltSimManager {
    /** Simulation timestep — 50 Hz to match robot periodic. */
    private static final double DT = 0.02;

    // ── Placeholder robot parameters (tune to match actual robot) ──────────

    /**
     * Swerve module center offset from robot center (placeholder: 10.5in =
     * 0.2667m).
     */
    private static final double MODULE_OFFSET_M = 0.2667;

    /** Wheel coefficient of friction against carpet (placeholder). */
    private static final double WHEEL_COF = 1.2;

    /** Total robot mass including bumpers (placeholder, kg). */
    private static final double ROBOT_MASS_KG = 55.0;

    /** Robot moment of inertia about Z axis (placeholder, kg*m^2). */
    private static final double ROBOT_MOI = 6.0;

    /** Bumper frame length and width (placeholder, meters). */
    private static final double BUMPER_LENGTH_M = 0.8;
    private static final double BUMPER_WIDTH_M = 0.8;

    /** Bumper frame height (placeholder, meters). */
    private static final double BUMPER_HEIGHT_M = 0.25;

    /** Maximum fuel balls the hopper can hold (placeholder). */
    private static final int HOPPER_CAPACITY = 70;

    // ── Intake zone bounds (robot-relative, placeholder) ───────────────────

    /** Intake zone forward start distance from robot center (meters). */
    private static final double INTAKE_X_MIN = 0.35;
    /** Intake zone forward end distance from robot center (meters). */
    private static final double INTAKE_X_MAX = 0.5;
    /** Intake zone left/right half-width from robot center (meters). */
    private static final double INTAKE_Y_MIN = -0.25;
    private static final double INTAKE_Y_MAX = 0.25;
    /** Intake zone max height — balls above this are ignored (meters). */
    private static final double INTAKE_Z_MAX = 0.2;

    // ── Proximity activation radii ─────────────────────────────────────────

    /** Wake sleeping game pieces within this distance of the robot (meters). */
    private static final double PROXIMITY_WAKE_RADIUS = 1.5;
    /**
     * Put game pieces to sleep beyond this distance from all wake zones (meters).
     */
    private static final double PROXIMITY_SLEEP_RADIUS = 3.0;

    // ── Component animation speeds (rad/s) ─────────────────────────────────

    private static final double INTAKE_ROLLER_SPEED = 10.0;
    private static final double FEEDER_ROLLER_SPEED = 15.0;
    private static final double SHOOTER_ROLLER_SPEED = 30.0;

    /** Cached origin translation for telemetry component poses. */
    private static final Translation3d ORIGIN = new Translation3d(0, 0, 0);

    private final frc.sim.core.PhysicsWorld physicsWorld;
    private final ChassisSimulation chassis;
    private final RebuiltField field;
    private final GamePieceManager gamePieceManager;
    private final IntakeZone intakeZone;
    private final ShooterSim shooterSim;
    private final ScoringTracker scoringTracker;
    private final GroundClearance groundClearance;
    private final SimTelemetry telemetry;

    // MapleSim swerve simulation
    private final SwerveDriveSimulation mapleSimDrive;
    private final SwerveModuleSimulation[] moduleSimulations;

    // References to robot subsystems
    private final CommandSwerveDrivetrain drivetrain;
    private final Shooter shooter;
    private final Intake intake;

    // CTRE sim state (for gyro only — MapleSim handles motor/encoder sim state)
    private final Pigeon2SimState pigeonSimState;

    // Animation angle accumulators (radians)
    private double rollerAngleAccum = 0;
    private double feederAngleAccum = 0;
    private double shooterRollerAngleAccum = 0;

    /**
     * Create the simulation manager and initialize both physics engines.
     *
     * <p>
     * Sets up MapleSim for drivetrain physics and ODE4J for game piece physics,
     * wires motor controller adapters, spawns starting fuel, and configures
     * intake/shooter/scoring systems.
     *
     * @param drivetrain the swerve drivetrain subsystem (motor and encoder
     *                   references)
     * @param shooter    the shooter subsystem (hood angle and shooting state)
     * @param intake     the intake subsystem (roller active state)
     */
    public RebuiltSimManager(CommandSwerveDrivetrain drivetrain, Shooter shooter, Intake intake) {
        this.drivetrain = drivetrain;
        this.shooter = shooter;
        this.intake = intake;

        // --- MapleSim timing ---
        // Use AddRampCollider=false so MapleSim only blocks on the hub (47x47),
        // not the hub+ramps (47x217). ODE4J handles ramp climbing in 3D.
        SimulatedArena.overrideInstance(
                new org.ironmaple.simulation.seasonspecific.rebuilt2026.Arena2026Rebuilt(false));
        SimulatedArena.overrideSimulationTimings(Seconds.of(DT), 1);

        // --- MapleSim swerve drive simulation ---
        Translation2d[] modulePositions = new Translation2d[] {
                new Translation2d(MODULE_OFFSET_M, MODULE_OFFSET_M), // FL
                new Translation2d(MODULE_OFFSET_M, -MODULE_OFFSET_M), // FR
                new Translation2d(-MODULE_OFFSET_M, MODULE_OFFSET_M), // BL
                new Translation2d(-MODULE_OFFSET_M, -MODULE_OFFSET_M) // BR
        };

        SwerveModuleSimulationConfig moduleSimConfig = new SwerveModuleSimulationConfig(
                DCMotor.getFalcon500(1),
                DCMotor.getFalcon500(1),
                TunerConstants.FrontLeft.DriveMotorGearRatio,
                TunerConstants.FrontLeft.SteerMotorGearRatio,
                Volts.of(TunerConstants.FrontLeft.DriveFrictionVoltage),
                Volts.of(TunerConstants.FrontLeft.SteerFrictionVoltage),
                Meters.of(TunerConstants.FrontLeft.WheelRadius),
                KilogramSquareMeters.of(TunerConstants.FrontLeft.SteerInertia),
                WHEEL_COF);

        DriveTrainSimulationConfig driveSimConfig = DriveTrainSimulationConfig.Default()
                .withRobotMass(Kilograms.of(ROBOT_MASS_KG))
                .withBumperSize(Meters.of(BUMPER_LENGTH_M), Meters.of(BUMPER_WIDTH_M))
                .withCustomModuleTranslations(modulePositions)
                .withSwerveModule(moduleSimConfig);

        Pose2d startingPose = new Pose2d(.5, .5, Rotation2d.kZero);
        mapleSimDrive = new SwerveDriveSimulation(driveSimConfig, startingPose);

        // MapleSim owns and steps the drivetrain; ODE4J chassis is a kinematic follower
        SimulatedArena.getInstance().addDriveTrainSimulation(mapleSimDrive);

        // --- Wire motor controller adapters ---
        moduleSimulations = mapleSimDrive.getModules();
        for (int i = 0; i < 4; i++) {
            moduleSimulations[i].useDriveMotorController(
                    new TalonFXMotorControllerSim(drivetrain.getDriveMotor(i)));
            moduleSimulations[i].useSteerMotorController(
                    new TalonFXMotorControllerWithRemoteCanCoderSim(
                            drivetrain.getSteerMotor(i), drivetrain.getModuleEncoder(i)));
        }

        // --- Stop CTRE sim thread (MapleSim owns encoder state now) ---
        drivetrain.stopSimNotifier();

        // --- Physics World (ODE4J) ---
        physicsWorld = new frc.sim.core.PhysicsWorld();

        // --- Chassis (ODE4J body for collisions) ---
        ChassisConfig chassisConfig = new ChassisConfig.Builder()
                .withModulePositions(modulePositions)
                .withRobotMass(ROBOT_MASS_KG)
                .withRobotMOI(ROBOT_MOI)
                .withBumperSize(BUMPER_LENGTH_M, BUMPER_WIDTH_M, BUMPER_HEIGHT_M)
                .build();

        chassis = new ChassisSimulation(physicsWorld, chassisConfig, startingPose);

        // --- Field ---
        field = new RebuiltField(physicsWorld);

        // --- Game Pieces ---
        gamePieceManager = new GamePieceManager(physicsWorld);
        gamePieceManager.setMaxCapacity(HOPPER_CAPACITY);
        field.spawnStartingFuel(gamePieceManager);
        gamePieceManager.disableAll();

        // --- Intake Zone ---
        intakeZone = new IntakeZone(INTAKE_X_MIN, INTAKE_X_MAX, INTAKE_Y_MIN, INTAKE_Y_MAX, INTAKE_Z_MAX,
                intake::isRollersActive,
                () -> chassis.getPose2d());

        // --- Shooter ---
        shooterSim = new ShooterSim(
                gamePieceManager,
                RebuiltGamePieces.FUEL,
                () -> chassis.getPose2d(),
                shooter::getHoodAngleRad,
                shooter::getLaunchVelocity,
                shooter::isShooting,
                () -> chassis.getBody().getLinearVel().get0(),
                () -> chassis.getBody().getLinearVel().get1());

        // --- Scoring & Telemetry ---
        scoringTracker = new ScoringTracker();
        groundClearance = new GroundClearance(chassis.getBody(), chassisConfig.getBumperHeight());
        telemetry = new SimTelemetry(chassis);

        // --- Cache gyro sim state ---
        pigeonSimState = drivetrain.getPigeonSimState();
    }

    /**
     * Run one simulation tick. Called from {@code Robot.simulationPeriodic()}.
     *
     * <p>
     * Sequence: MapleSim steps drivetrain → read pose/speeds → convert to world
     * frame
     * → set ODE4J chassis velocity → proximity activation → intake check → physics
     * step
     * → gyro sync → piece state update → scoring check → shooter update →
     * telemetry.
     */
    public void periodic() {
        // 1. MapleSim steps the drivetrain (motor physics, tire model, encoder
        // feedback)
        SimulatedArena.getInstance().simulationPeriodic();

        // 2. Read pose and speeds from MapleSim
        Pose2d pose = mapleSimDrive.getSimulatedDriveTrainPose();
        ChassisSpeeds robotSpeeds = mapleSimDrive.getDriveTrainSimulatedChassisSpeedsRobotRelative();

        // 3. Convert robot-relative chassis speeds to world-frame velocities for ODE4J.
        // MapleSim reports speeds in the robot's local frame (+X = forward, +Y = left).
        // ODE4J needs world-frame velocities, so we rotate by the robot's heading:
        // worldVx = vx*cos(θ) - vy*sin(θ)
        // worldVy = vx*sin(θ) + vy*cos(θ)
        double yaw = pose.getRotation().getRadians();
        double cos = Math.cos(yaw);
        double sin = Math.sin(yaw);
        double worldVx = robotSpeeds.vxMetersPerSecond * cos - robotSpeeds.vyMetersPerSecond * sin;
        double worldVy = robotSpeeds.vxMetersPerSecond * sin + robotSpeeds.vyMetersPerSecond * cos;

        // 4. Set velocity only — do NOT call setPose() before step.
        // setPose() overrides X every tick, which fights the ODE4J contact solver
        // and prevents the chassis from riding up ramps/bumps.
        // Velocity-only lets ODE4J integrate position naturally with ramp deflection.
        chassis.setVelocity(worldVx, worldVy, robotSpeeds.omegaRadiansPerSecond, DT);

        // 5. Proximity activation — only wake balls near the robot
        gamePieceManager.updateProximity(
                chassis.getPose2d().getTranslation(),
                PROXIMITY_WAKE_RADIUS, PROXIMITY_SLEEP_RADIUS);

        // 6. Check intake BEFORE physics step — if we step first, launched balls
        // that are still inside the robot's intake zone would get re-consumed
        // on the same tick they were shot. Checking before step ensures only
        // balls that were already in the zone from the previous frame are intaked.
        intakeZone.checkIntake(gamePieceManager, gamePieceManager.getPieces());

        // 7. Step physics world — ODE4J integrates position from velocity,
        // handles ramp/bump contacts (Z changes), game piece collisions
        physicsWorld.step(DT);

        // 8. Sync gyro from MapleSim pose (not ODE4J)
        pigeonSimState.setSupplyVoltage(SimulatedBattery.getBatteryVoltage().in(Volts));
        pigeonSimState.setRawYaw(Math.toDegrees(pose.getRotation().getRadians()));
        pigeonSimState.setAngularVelocityZ(Math.toDegrees(robotSpeeds.omegaRadiansPerSecond));

        // 9. Update game piece states
        gamePieceManager.update();

        // 10. Check scoring zones
        List<frc.sim.gamepiece.GamePiece> activePieces = gamePieceManager.getActivePieces();
        for (DGeom zone : field.getScoringZones()) {
            Set<DBody> contacts = physicsWorld.getSensorContacts(zone);
            for (DBody contactBody : contacts) {
                for (frc.sim.gamepiece.GamePiece piece : activePieces) {
                    if (piece.getBody() == contactBody) {
                        scoringTracker.markScore("Goal", 1);
                        piece.consume();
                        break;
                    }
                }
            }
        }

        // 11. Update shooter
        shooterSim.update(DT);

        // 12. Publish telemetry to NetworkTables
        publishTelemetry();
    }

    private void publishTelemetry() {
        // Robot pose
        Pose3d robotPose = chassis.getPose3d();
        Logger.recordOutput("Sim/Robot/Pose3d", robotPose);

        // Game piece held count
        Logger.recordOutput("Sim/Intake/HeldCount", gamePieceManager.getHeldCount());

        // Scoring
        Logger.recordOutput("Sim/Score/Total", scoringTracker.getTotalScore());

        // Ground clearance
        double clearance = groundClearance.getClearance();
        Logger.recordOutput("Sim/Robot/GroundClearance", clearance);
        Logger.recordOutput("Sim/Robot/IsAirborne", groundClearance.isAirborne());

        // Game piece poses for AdvantageScope
        gamePieceManager.publishPoses((key, poses) -> Logger.recordOutput(key, poses));

        // Component poses for articulated AdvantageScope robot model
        double hoodAngle = shooter.getHoodAngleRad();
        boolean shooting = shooter.isShooting();
        boolean intaking = intake.isRollersActive();

        Pose3d shooterHoodPose = new Pose3d(
                ORIGIN,
                new Rotation3d(hoodAngle - Math.PI / 4, 0, 0));

        if (intaking)
            rollerAngleAccum += INTAKE_ROLLER_SPEED * DT;
        double rollerAngle = intaking ? (rollerAngleAccum % (2 * Math.PI)) : 0;
        Pose3d intakeRollerPose = new Pose3d(
                ORIGIN,
                new Rotation3d(rollerAngle, 0, 0));

        if (shooting)
            feederAngleAccum += FEEDER_ROLLER_SPEED * DT;
        double feederAngle = shooting ? (feederAngleAccum % (2 * Math.PI)) : 0;
        Pose3d feederRollerPose = new Pose3d(
                ORIGIN,
                new Rotation3d(feederAngle, 0, 0));

        if (shooting)
            shooterRollerAngleAccum += SHOOTER_ROLLER_SPEED * DT;
        double shooterRollerAngle = shooting ? (shooterRollerAngleAccum % (2 * Math.PI)) : 0;
        Pose3d shooterRollerPose = new Pose3d(
                ORIGIN,
                new Rotation3d(shooterRollerAngle, 0, 0));

        Pose3d verticalFeederPose = new Pose3d(
                ORIGIN,
                new Rotation3d(0, feederAngle, 0));

        Pose3d climberPose = new Pose3d();

        Logger.recordOutput("Sim/Robot/ComponentPoses",
                new Pose3d[] {
                        shooterHoodPose,
                        intakeRollerPose,
                        feederRollerPose,
                        feederRollerPose,
                        verticalFeederPose,
                        verticalFeederPose,
                        shooterRollerPose,
                        climberPose
                });
    }

    /** Get the chassis simulation. */
    public ChassisSimulation getChassis() {
        return chassis;
    }

    /** Get the physics world. */
    public frc.sim.core.PhysicsWorld getPhysicsWorld() {
        return physicsWorld;
    }

    /** Get the game piece manager. */
    public GamePieceManager getGamePieceManager() {
        return gamePieceManager;
    }

    /** Get the scoring tracker. */
    public ScoringTracker getScoringTracker() {
        return scoringTracker;
    }

    // --- MapleSim motor controller adapters ---
    //
    // MapleSim owns the motor physics (voltage -> torque -> mechanism state) but
    // has
    // no knowledge of CTRE's TalonFX/CANcoder sim APIs. These adapters close the
    // loop:
    //
    // MapleSim ---(position, velocity)---> Adapter ---(setRawRotorPosition,
    // etc.)---> TalonFX SimState
    // MapleSim <---(commanded voltage)--- Adapter <---(getMotorVoltageMeasure)----
    // TalonFX SimState
    //
    // This lets robot code read realistic encoder values while MapleSim computes
    // the physics.

    /**
     * Adapter that bridges MapleSim's motor simulation API to a single CTRE
     * TalonFX.
     *
     * <p>
     * Each tick, MapleSim calls {@link #updateControlSignal} with the mechanism
     * state
     * it computed (position and velocity). This adapter writes those values into
     * the
     * TalonFX's sim state so that robot code sees realistic encoder readings, then
     * returns the motor's commanded voltage back to MapleSim for force computation.
     *
     * <p>
     * Battery voltage is sourced from {@link SimulatedBattery} so brownout effects
     * propagate through to the motor controller.
     */
    private static class TalonFXMotorControllerSim implements SimulatedMotorController {
        private final TalonFXSimState talonFXSimState;

        TalonFXMotorControllerSim(TalonFX talonFX) {
            this.talonFXSimState = talonFX.getSimState();
        }

        @Override
        public Voltage updateControlSignal(
                Angle mechanismAngle,
                AngularVelocity mechanismVelocity,
                Angle encoderAngle,
                AngularVelocity encoderVelocity) {
            talonFXSimState.setRawRotorPosition(encoderAngle);
            talonFXSimState.setRotorVelocity(encoderVelocity);
            talonFXSimState.setSupplyVoltage(SimulatedBattery.getBatteryVoltage());
            return talonFXSimState.getMotorVoltageMeasure();
        }
    }

    /**
     * Extends the TalonFX adapter to also sync a remote CANcoder's sim state.
     *
     * <p>
     * Used for swerve steer modules where the TalonFX uses a fused/remote CANcoder
     * for absolute position feedback. MapleSim provides the mechanism angle
     * (steering
     * position), which this adapter writes to both the TalonFX rotor state and the
     * CANcoder's raw position so that both sensors agree.
     */
    private static class TalonFXMotorControllerWithRemoteCanCoderSim extends TalonFXMotorControllerSim {
        private final CANcoderSimState remoteCancoderSimState;

        TalonFXMotorControllerWithRemoteCanCoderSim(TalonFX talonFX, CANcoder cancoder) {
            super(talonFX);
            this.remoteCancoderSimState = cancoder.getSimState();
        }

        @Override
        public Voltage updateControlSignal(
                Angle mechanismAngle,
                AngularVelocity mechanismVelocity,
                Angle encoderAngle,
                AngularVelocity encoderVelocity) {
            remoteCancoderSimState.setSupplyVoltage(SimulatedBattery.getBatteryVoltage());
            remoteCancoderSimState.setRawPosition(mechanismAngle);
            remoteCancoderSimState.setVelocity(mechanismVelocity);
            return super.updateControlSignal(mechanismAngle, mechanismVelocity, encoderAngle, encoderVelocity);
        }
    }
}
