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
import edu.wpi.first.math.geometry.Transform3d;
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
import edu.wpi.first.wpilibj.simulation.BatterySim;
import edu.wpi.first.wpilibj.simulation.RoboRioSim;
import edu.wpi.first.wpilibj.simulation.SingleJointedArmSim;
import edu.wpi.first.wpilibj.simulation.DCMotorSim;
import edu.wpi.first.math.system.plant.LinearSystemId;
import frc.robot.RobotMap;
import frc.robot.subsystems.feeder.Feeder;
import frc.robot.subsystems.intake.IntakeSubsystem;
import frc.robot.subsystems.shooter.ShooterHood;
import frc.robot.subsystems.shooter.ShooterWheels;
import frc.robot.subsystems.spindexer.Spindexer;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.subsystems.swerve.generated.TunerConstants;
import frc.robot.utils.FieldConstants;
import frc.robot.utils.ShootOnTheMove;
import frc.sim.chassis.ChassisConfig;
import frc.sim.chassis.ChassisSimulation;
import frc.sim.core.PhysicsWorld;
import frc.sim.vision.CameraConfig;
import frc.sim.vision.LimelightSim;
import frc.sim.vision.LimelightType;
import frc.sim.vision.VisionSimManager;
import frc.sim.gamepiece.GamePiece;
import frc.sim.gamepiece.GamePieceManager;
import frc.sim.gamepiece.IntakeZone;
import frc.sim.scoring.ScoringTracker;
import frc.sim.telemetry.GroundClearance;

import java.util.List;
import java.util.Set;

/**
 * Orchestrates the full simulation for the 2026 REBUILT game.
 *
 * MapleSim owns the entire drivetrain (motor physics, tire model, chassis dynamics).
 * The ODE4J chassis is a kinematic follower that exists only for game piece collisions.
 *
 * Architecture:
 * - MapleSim: steps drivetrain, computes pose and velocities, writes encoder state
 * - ODE4J chassis: kinematically follows MapleSim pose, provides collision body for game pieces
 */
public class RebuiltSimManager {
    // All distances in meters, angles in radians (unless noted otherwise).

    /** Simulation timestep — 50 Hz to match robot periodic. */
    private static final double DT = 0.02;

    // ── Placeholder robot parameters (tune to match actual robot) ──────────

    /** Swerve module center offset from robot center (placeholder: 10.5in = 0.2667m). */
    private static final double MODULE_OFFSET_M = 0.2667;

    /** Wheel coefficient of friction against carpet (placeholder). */
    private static final double WHEEL_COF = 1.2;

    /** Total robot mass including bumpers (placeholder, kg). */
    private static final double ROBOT_MASS_KG = 55.0;

    /** Robot moment of inertia about Z axis (placeholder, kg*m^2). */
    private static final double ROBOT_MOI = 6.0;

    /** Bumper frame length and width (placeholder). */
    private static final double BUMPER_LENGTH_M = 0.8;
    private static final double BUMPER_WIDTH_M = 0.8;

    /** Bumper frame height (placeholder). */
    private static final double BUMPER_HEIGHT_M = 0.25;

    /** Starting pose for simulation. */
    public static final Pose2d STARTING_POSE = new Pose2d(0.5, 0.5, Rotation2d.kZero);

    /** Maximum fuel balls the hopper can hold (placeholder). */
    private static final int HOPPER_CAPACITY = 50;  // was 70; spec: hopper holds 50 balls

    // ── Intake zone bounds (robot-relative, placeholder) ───────────────────

    /** Intake zone forward start distance from robot center. (note: intake is behind us) */
    private static final double INTAKE_X_MIN = -0.50;
    /** Intake zone forward end distance from robot center. (note: intake is behind us) */
    private static final double INTAKE_X_MAX = -0.35;
    /** Intake zone left/right half-width from robot center. */
    private static final double INTAKE_Y_MIN = -0.25;
    private static final double INTAKE_Y_MAX = 0.25;
    /** Intake zone max height — balls above this are ignored. */
    private static final double INTAKE_Z_MAX = 0.2;

    // ── Proximity activation radii ─────────────────────────────────────────

    /** Wake sleeping game pieces within this distance of the robot. */
    private static final double PROXIMITY_WAKE_RADIUS = 1.5;
    /** Put game pieces to sleep beyond this distance from all wake zones. */
    private static final double PROXIMITY_SLEEP_RADIUS = 3.0;

    /** ODE4J→MapleSim position correction gain (1cm error → 0.5 m/s correction). */
    private static final double POSITION_CORRECTION_KP = 50.0;

    // ── Sim hood parameters ────────────────────────────────────────────────

    /** Angle changes by this much to visually match ball path */
    private static final double HOOD_VISUAL_OFFSET_RAD = Math.toRadians(70);

    // ── Shooter launch geometry ─────────────────────────────────────────────

    /** Forward X position of the shooter hood from robot center (meters). */
    private static final double SHOOTER_HOOD_FORWARD_X = 0.243;

    /**
     * These 2 values combined MUST ensure we clear the chassis otherwise
     * the physics engine will have balls colliding w/ the robot immediately
     * upon shooting
     */
    private static final double LAUNCH_HEIGHT = 0.55;
    private static final double MUZZLE_FORWARD_OFFSET = SHOOTER_HOOD_FORWARD_X - RebuiltGamePieces.FUEL.getRadius();

    /** Lateral distance from centerline for each barrel (meters). */
    private static final double BARREL_LATERAL_OFFSET = 0.08;

    /** Number of shot events per second (each event fires both barrels). */
    private static final double SHOTS_PER_SECOND = 8;

    // ── Motor physics constants (TODO: update with real measured values) ───────

    /** Shooter wheel moment of inertia (kg·m²). TODO update placeholder */
    private static final double SHOOTER_MOI = 0.5 * 3.0 * 0.05 * 0.05; // 0.5 × mass(3kg) × radius²(0.05m) — TODO update placeholder

    /** Shooter gear ratio (motor rotations / wheel rotations). TODO update placeholder */
    private static final double SHOOTER_GEAR_RATIO = 1.0;

    /** Shooter velocity threshold (RPS) above which wheels count as spinning. TODO update placeholder */
    private static final double SHOOTER_VELOCITY_THRESHOLD_RPS = 5.0;

    /** Shooter wheel radius (m) — used to convert flywheel RPS to launch speed (m/s). TODO update placeholder */
    private static final double SHOOTER_WHEEL_RADIUS_M = 0.05;

    /** Wheel-to-ball friction efficiency — accounts for slip at contact. TODO update placeholder */
    private static final double SLIP_FACTOR = 0.8;

    /** Fraction of contact energy that goes to translation vs backspin.
     *  For a hollow sphere (I = 2/3 mr²) with single-sided roller + static hood:
     *  translational = I / (I + mr²) = (2/3) / (2/3 + 1) = 2/5 = 0.4.
     *  TODO update placeholder — real value depends on ball compression and contact geometry. */
    private static final double BALL_TRANSLATIONAL_FRACTION = 0.4;

    /** Magnus effect coefficient for spinning balls in flight.
     *  F_magnus = MAGNUS_K * cross(angularVel, linearVel).
     *  Rough estimate from: 0.5 * rho_air(1.225) * Cl(0.5) * pi * r²(0.075²).
     *  NOT YET USED — placeholder for future Magnus flight physics. TODO update placeholder */
    private static final double MAGNUS_COEFFICIENT = 0.5 * 1.225 * 0.5 * Math.PI * 0.075 * 0.075;

    /** Hood motor gear ratio (motor rotations / mechanism rotations). TODO update placeholder */
    private static final double HOOD_GEAR_RATIO = 30.0;

    /** Hood mechanism moment of inertia (kg·m²), estimated via WPILib uniform-rod approximation.
     *  TODO update placeholder: measure arm length and mass from CAD. */
    private static final double HOOD_MOI_KGM2 = SingleJointedArmSim.estimateMOI(0.23, 3.0); // 23cm arm, 3kg

    /** Hood arm effective length for SingleJointedArmSim (m). TODO update placeholder */
    private static final double HOOD_ARM_LENGTH_M = 0.15;

    /** Hood minimum angle (degrees from horizontal) — motor position = 0. 35.5° from spec. */
    private static final double HOOD_MIN_ANGLE_DEG = 35.5;

    /** Hood maximum angle (degrees from horizontal) — motor position = 30 rotations. 67.4° from spec. */
    private static final double HOOD_MAX_ANGLE_DEG = 67.4;

    /** Feeder motor moment of inertia (kg·m²). TODO update placeholder */
    private static final double FEEDER_MOI = 4 * 0.5 * 0.75 * 0.025 * 0.025; // 4 axles × 0.5 × mass(0.75kg) × radius²(0.025m) — TODO update placeholder

    /** Feeder gear ratio (motor rotations / mechanism rotations). TODO update placeholder */
    private static final double FEEDER_GEAR_RATIO = 1.0;

    /** Feeder velocity threshold (RPS, forward-only) — negative velocity (reverse phase) stops shooting. TODO update placeholder */
    private static final double FEEDER_VELOCITY_THRESHOLD_RPS = 0.5;

    /** Spindexer motor moment of inertia (kg·m²). TODO update placeholder */
    private static final double SPINDEXER_MOI = 2 * 0.5 * 0.5 * 0.04 * 0.04; // 2 axles × 0.5 × mass(0.5kg) × radius²(0.04m) — TODO update placeholder

    /** Spindexer gear ratio (motor rotations / mechanism rotations). TODO update placeholder */
    private static final double SPINDEXER_GEAR_RATIO = 1.0;

    /** Intake roller velocity threshold (motor RPS) above which roller counts as spinning. TODO update placeholder */
    private static final double INTAKE_ROLLER_VELOCITY_THRESHOLD_RPS = 1.0;

    /** Intake deploy motor moment of inertia (kg·m²). Gear ratio 1.0 — position tracked in motor encoder rotations. TODO update placeholder */
    private static final double INTAKE_DEPLOY_MOI = 0.0005;

    /** Intake deploy gear ratio (motor rotations / mechanism rotations). */
    private static final double INTAKE_DEPLOY_GEAR_RATIO = 1.0;

    /** Intake roller motor moment of inertia (kg·m²). TODO update placeholder */
    private static final double INTAKE_ROLLER_MOI = 0.001;

    /** Intake roller gear ratio (motor rotations / mechanism rotations). */
    private static final double INTAKE_ROLLER_GEAR_RATIO = 1.0;

    // Intake extension translation (delta from retracted position)
    private static final double INTAKE_EXTEND_X = -0.302;
    private static final double INTAKE_EXTEND_Z = -0.098;

    // ── Fuel detection Limelight (limelight-one, rear-facing) ───────────────

    private static final String FUEL_LL_NAME = "limelight-one";
    private static final Transform3d FUEL_LL_MOUNT = new Transform3d(
            new Translation3d(-0.50, 0, 0.325),
            new Rotation3d(0, Math.toRadians(28), Math.toRadians(180)));
    /** Near plane distance for fuel detection frustum. */
    private static final double FUEL_LL_NEAR = 0.3;
    /** Far plane distance for fuel detection frustum. */
    private static final double FUEL_LL_FAR = 3.0;
    /** Detection rate for fuel detection camera. */
    private static final double FUEL_LL_FPS = 5.0;

    private final VisionSimManager visionSimManager;
    private final PhysicsWorld physicsWorld;
    private final ChassisSimulation chassis;
    private final RebuiltField field;
    private final GamePieceManager gamePieceManager;
    private final IntakeZone intakeZone;
    private final ShooterSim shooterSim;
    private final ScoringTracker scoringTracker;
    private final GroundClearance groundClearance;

    // MapleSim swerve simulation
    private final SwerveDriveSimulation mapleSimDrive;
    private final SwerveModuleSimulation[] moduleSimulations;

    // References to robot subsystems
    private final IntakeSubsystem intakeSubsystem;

    // CTRE sim state (for gyro only — MapleSim handles motor/encoder sim state)
    private final Pigeon2SimState pigeonSimState;

    // WPILib physics sims for non-drivetrain mechanisms.
    private final DCMotorSim shooterMotorSim;
    private final SingleJointedArmSim hoodArmSim;
    private final DCMotorSim feederMotorSim;
    private final DCMotorSim spindexerMotorSim;
    private final DCMotorSim intakeDeployMotorSim;
    private final DCMotorSim intakeRollerMotorSim;

    // CTRE sim states for the motors we simulate
    private final TalonFXSimState shooterLeaderSimState;
    private final TalonFXSimState hoodMotorSimState;
    private final TalonFXSimState feederMotorSimState;
    private final TalonFXSimState spindexerMotorSimState;
    private final TalonFXSimState intakeDeploySimState;
    private final TalonFXSimState intakeRollerSimState;

    // Last known pose and speeds from MapleSim (used for virtual goal telemetry)
    private Pose2d lastSimPose = STARTING_POSE;
    private ChassisSpeeds lastSimSpeeds = new ChassisSpeeds();

    /**
     * Create the simulation manager and initialize both physics engines.
     *
     * <p>Sets up MapleSim for drivetrain physics and ODE4J for game piece physics,
     * wires motor controller adapters, spawns starting fuel, and configures
     * intake/shooter/scoring systems.
     *
     * @param drivetrain      the swerve drivetrain subsystem (motor and encoder references)
     * @param intakeSubsystem the unified intake subsystem (deployment + roller state)
     * @param feeder          the feeder subsystem (run/stop state)
     * @param shooterWheels   the shooter wheels subsystem (flywheel state)
     * @param shooterHood     the shooter hood subsystem (aiming state)
     * @param spindexer       the spindexer subsystem (run/stop state)
     */
    public RebuiltSimManager(CommandSwerveDrivetrain drivetrain,
                             IntakeSubsystem intakeSubsystem, Feeder feeder,
                             ShooterWheels shooterWheels, ShooterHood shooterHood,
                             Spindexer spindexer) {
        this.intakeSubsystem = intakeSubsystem;

        // --- MapleSim timing ---
        // Use AddRampCollider=false so MapleSim only blocks on the hub (47x47),
        // not the hub+ramps (47x217). ODE4J handles ramp climbing in 3D.
        Logger.recordOutput("Sim/State", "Loading MapleSim");
        SimulatedArena.overrideInstance(
                new org.ironmaple.simulation.seasonspecific.rebuilt2026.Arena2026Rebuilt(false));
        SimulatedArena.overrideSimulationTimings(Seconds.of(DT), 1);

        // --- MapleSim swerve drive simulation ---
        Logger.recordOutput("Sim/State", "Loading drivetrain");
        Translation2d[] modulePositions = new Translation2d[] {
            new Translation2d(MODULE_OFFSET_M, MODULE_OFFSET_M),   // FL
            new Translation2d(MODULE_OFFSET_M, -MODULE_OFFSET_M),  // FR
            new Translation2d(-MODULE_OFFSET_M, MODULE_OFFSET_M),  // BL
            new Translation2d(-MODULE_OFFSET_M, -MODULE_OFFSET_M)  // BR
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

        mapleSimDrive = new SwerveDriveSimulation(driveSimConfig, STARTING_POSE);

        // MapleSim owns and steps the drivetrain; ODE4J chassis is a kinematic follower
        SimulatedArena.getInstance().addDriveTrainSimulation(mapleSimDrive);

        // --- Wire motor controller adapters ---
        Logger.recordOutput("Sim/State", "Wiring motors");
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
        Logger.recordOutput("Sim/State", "Loading physics");
        physicsWorld = new PhysicsWorld();

        // --- Chassis (ODE4J body for collisions) ---
        Logger.recordOutput("Sim/State", "Loading chassis");
        ChassisConfig chassisConfig = new ChassisConfig.Builder()
                .withModulePositions(modulePositions)
                .withRobotMass(ROBOT_MASS_KG)
                .withRobotMOI(ROBOT_MOI)
                .withBumperSize(BUMPER_LENGTH_M, BUMPER_WIDTH_M, BUMPER_HEIGHT_M)
                .build();

        chassis = new ChassisSimulation(physicsWorld, chassisConfig, STARTING_POSE);

        // --- Field ---
        Logger.recordOutput("Sim/State", "Loading field");
        field = new RebuiltField(physicsWorld);

        // --- Game Pieces ---
        Logger.recordOutput("Sim/State", "Spawning game pieces");
        gamePieceManager = new GamePieceManager(physicsWorld);
        gamePieceManager.setMaxCapacity(HOPPER_CAPACITY);
        field.spawnStartingFuel(gamePieceManager);
        gamePieceManager.disableAll();

        // --- Intake Zone ---
        Logger.recordOutput("Sim/State", "Loading intake");
        intakeZone = new IntakeZone(INTAKE_X_MIN, INTAKE_X_MAX, INTAKE_Y_MIN, INTAKE_Y_MAX, INTAKE_Z_MAX,
                () -> intakeSubsystem.getDeployMotorPositionRotations() > IntakeSubsystem.EXTENDED_ROTATIONS
                                && intakeSubsystem.getRollerMotorVelocityRPS() > INTAKE_ROLLER_VELOCITY_THRESHOLD_RPS,
                () -> chassis.getPose2d());

        // --- Mechanism physics sims (non-drivetrain) ---
        Logger.recordOutput("Sim/State", "Loading mechanism sims");

        shooterMotorSim = new DCMotorSim(
            LinearSystemId.createDCMotorSystem(
                DCMotor.getKrakenX60(1), SHOOTER_MOI, SHOOTER_GEAR_RATIO),
            DCMotor.getKrakenX60(1));

        hoodArmSim = new SingleJointedArmSim(
            DCMotor.getKrakenX60(1),
            HOOD_GEAR_RATIO,
            HOOD_MOI_KGM2,
            HOOD_ARM_LENGTH_M,
            Math.toRadians(HOOD_MIN_ANGLE_DEG),   // minAngleRads
            Math.toRadians(HOOD_MAX_ANGLE_DEG),   // maxAngleRads
            true,               // gravity = true: realistic hood droop behavior
            Math.toRadians(HOOD_MIN_ANGLE_DEG));  // startingAngleRads

        feederMotorSim = new DCMotorSim(
            LinearSystemId.createDCMotorSystem(DCMotor.getKrakenX60(1), FEEDER_MOI, FEEDER_GEAR_RATIO),
            DCMotor.getKrakenX60(1));

        spindexerMotorSim = new DCMotorSim(
            LinearSystemId.createDCMotorSystem(DCMotor.getKrakenX60(1), SPINDEXER_MOI, SPINDEXER_GEAR_RATIO),
            DCMotor.getKrakenX60(1));

        intakeDeployMotorSim = new DCMotorSim(
            LinearSystemId.createDCMotorSystem(DCMotor.getKrakenX60(1), INTAKE_DEPLOY_MOI, INTAKE_DEPLOY_GEAR_RATIO),
            DCMotor.getKrakenX60(1));

        intakeRollerMotorSim = new DCMotorSim(
            LinearSystemId.createDCMotorSystem(DCMotor.getKrakenX60(1), INTAKE_ROLLER_MOI, INTAKE_ROLLER_GEAR_RATIO),
            DCMotor.getKrakenX60(1));

        // Cache CTRE sim states
        shooterLeaderSimState = shooterWheels.getLeaderSimState();
        hoodMotorSimState = shooterHood.getHoodMotorSimState();
        feederMotorSimState = feeder.getFeederMotorSimState();
        spindexerMotorSimState = spindexer.getSpindexerMotorSimState();
        intakeDeploySimState = intakeSubsystem.getDeployMotorSimState();
        intakeRollerSimState = intakeSubsystem.getRollerMotorSimState();

        // --- Shooter ---
        Logger.recordOutput("Sim/State", "Loading shooter");
        // ShooterSim watches real subsystem states:
        // - Hood angle: live from SingleJointedArmSim
        // - Launch velocity: flywheel angular velocity (rad/s) × wheel radius (m/s)
        // - Shooting gate: velocity-based (feeder forward-only check handles washing machine reverse phase)
        shooterSim = new ShooterSim(
                gamePieceManager,
                RebuiltGamePieces.FUEL,
                () -> chassis.getPose2d(),
                () -> hoodArmSim.getAngleRads(),
                () -> shooterMotorSim.getAngularVelocityRadPerSec() * SHOOTER_WHEEL_RADIUS_M * SLIP_FACTOR * BALL_TRANSLATIONAL_FRACTION,
                () -> shooterMotorSim.getAngularVelocityRPM() / 60.0 > SHOOTER_VELOCITY_THRESHOLD_RPS
                        && feederMotorSim.getAngularVelocityRPM() / 60.0 > FEEDER_VELOCITY_THRESHOLD_RPS,
                () -> chassis.getBody().getLinearVel().get0(),
                () -> chassis.getBody().getLinearVel().get1(),
                () -> {
                    double vContact = shooterMotorSim.getAngularVelocityRadPerSec() * SHOOTER_WHEEL_RADIUS_M * SLIP_FACTOR;
                    return vContact * (1.0 - BALL_TRANSLATIONAL_FRACTION) / RebuiltGamePieces.FUEL.getRadius();
                },
                LAUNCH_HEIGHT,
                MUZZLE_FORWARD_OFFSET,
                BARREL_LATERAL_OFFSET,
                SHOTS_PER_SECOND);

        gamePieceManager.setMagnusCoefficient(MAGNUS_COEFFICIENT);

        // --- Scoring & Telemetry ---
        Logger.recordOutput("Sim/State", "Loading scoring");
        scoringTracker = new ScoringTracker();
        groundClearance = new GroundClearance(chassis.getBody(), chassisConfig.getBumperHeight());

        // --- Vision sim (writes true pose to NT in Limelight format) ---
        Logger.recordOutput("Sim/State", "Loading vision");
        Transform3d ll4Mount = new Transform3d(
                new Translation3d(0.31, -0.284, 0.193),
                new Rotation3d(0, Math.toRadians(-25), Math.toRadians(22)));
        Transform3d ll3Mount = new Transform3d(
                new Translation3d(0.31, 0.284, 0.193),
                new Rotation3d(0, Math.toRadians(-25), Math.toRadians(-22)));
        LimelightSim ll4Cam = new LimelightSim(
                new CameraConfig("limelight-two", LimelightType.LL4, ll4Mount));
        LimelightSim ll3Cam = new LimelightSim(
                new CameraConfig("limelight-five", LimelightType.LL3, ll3Mount));
        LimelightSim fuelCam = new LimelightSim(
                new CameraConfig(FUEL_LL_NAME, LimelightType.LL3, FUEL_LL_MOUNT),
                physicsWorld,
                chassis.getBody(),
                FUEL_LL_NEAR,
                FUEL_LL_FAR,
                RebuiltGamePieces.FUEL.getRadius(),
                FUEL_LL_FPS);
        visionSimManager = new VisionSimManager(ll4Cam, ll3Cam, fuelCam);

        // --- Cache gyro sim state ---
        Logger.recordOutput("Sim/State", "Syncing gyro");
        pigeonSimState = drivetrain.getPigeonSimState();
    }

    /**
     * Run one simulation tick. Called from {@code Robot.simulationPeriodic()}.
     *
     * <p>Sequence: MapleSim steps drivetrain → read pose/speeds → convert to world frame
     * → set ODE4J chassis velocity → proximity activation → intake check → physics step
     * → gyro sync → piece state update → scoring check → shooter update → telemetry.
     */
    public void periodic() {
        // 1. MapleSim steps the drivetrain (motor physics, tire model, encoder feedback)
        SimulatedArena.getInstance().simulationPeriodic();

        // 2. Read pose and speeds from MapleSim
        Pose2d pose = mapleSimDrive.getSimulatedDriveTrainPose();
        ChassisSpeeds robotSpeeds = mapleSimDrive.getDriveTrainSimulatedChassisSpeedsRobotRelative();
        lastSimPose = pose;
        lastSimSpeeds = robotSpeeds;

        // 3. Convert robot-relative chassis speeds to world-frame velocities for ODE4J.
        // MapleSim reports speeds in the robot's local frame (+X = forward, +Y = left).
        // ODE4J needs world-frame velocities, so we rotate by the robot's heading:
        //   worldVx = vx*cos(θ) - vy*sin(θ)
        //   worldVy = vx*sin(θ) + vy*cos(θ)
        double yaw = pose.getRotation().getRadians();
        double cos = Math.cos(yaw);
        double sin = Math.sin(yaw);
        double worldVx = robotSpeeds.vxMetersPerSecond * cos - robotSpeeds.vyMetersPerSecond * sin;
        double worldVy = robotSpeeds.vxMetersPerSecond * sin + robotSpeeds.vyMetersPerSecond * cos;

        // 4. Set velocity with position correction to prevent ODE4J drift from MapleSim.
        // Pure velocity-following drifts over time because ODE4J and MapleSim integrate
        // independently. Adding a proportional position correction keeps them synced
        // while still allowing the contact solver to deflect the chassis on ramps
        // (the correction is a force, not a position override, so the solver can oppose it).
        double odeX = chassis.getPose2d().getX();
        double odeY = chassis.getPose2d().getY();
        double correctedVx = worldVx + POSITION_CORRECTION_KP * (pose.getX() - odeX);
        double correctedVy = worldVy + POSITION_CORRECTION_KP * (pose.getY() - odeY);
        chassis.setVelocity(correctedVx, correctedVy, robotSpeeds.omegaRadiansPerSecond, DT);

        // 5. Proximity activation — only wake balls near the robot
        gamePieceManager.updateProximity(
                chassis.getPose2d().getTranslation(),
                PROXIMITY_WAKE_RADIUS, PROXIMITY_SLEEP_RADIUS);

        // 6. Check intake BEFORE physics step — if we step first, launched balls
        // that are still inside the robot's intake zone would get re-consumed
        // on the same tick they were shot. Checking before step ensures only
        // balls that were already in the zone from the previous frame are intaked.
        intakeZone.checkIntake(gamePieceManager, gamePieceManager.getPieces());

        // 6b. Enable/disable game piece sensors for this tick's collision pass
        visionSimManager.prepareGamePieces();

        // 7. Step physics world — ODE4J integrates position from velocity,
        // handles ramp/bump contacts (Z changes), game piece collisions

        physicsWorld.step(DT);

        // 8. Sync gyro from MapleSim pose (not ODE4J)
        pigeonSimState.setSupplyVoltage(SimulatedBattery.getBatteryVoltage().in(Volts));
        pigeonSimState.setRawYaw(Math.toDegrees(pose.getRotation().getRadians()));
        pigeonSimState.setAngularVelocityZ(Math.toDegrees(robotSpeeds.omegaRadiansPerSecond));

        // 8b. Write true pose to simulated Limelight NT entries
        visionSimManager.update(pose);

        // 8c. Update game piece detection cameras (reads sensor contacts from step above)
        visionSimManager.updateGamePieces();

        // 9. Update game piece states
        gamePieceManager.update();

        // 10. Check scoring zones
        List<GamePiece> activePieces = gamePieceManager.getActivePieces();
        for (DGeom zone : field.getScoringZones()) {
            Set<DBody> contacts = physicsWorld.getSensorContacts(zone);
            for (DBody contactBody : contacts) {
                for (GamePiece piece : activePieces) {
                    if (piece.getBody() == contactBody) {
                        scoringTracker.markScore("Goal", 1);
                        piece.consume();
                        break;
                    }
                }
            }
        }

        // 11. Step mechanism physics sims and write back to CTRE sim states.
        //
        // ORDERING NOTE: RoboRioSim.setVInVoltage MUST come first.
        // FlywheelSim/DCMotorSim.setInputVoltage() internally clamps to RobotController.getBatteryVoltage(),
        // which reads from RoboRioSim. Setting it first ensures the clamp uses our computed voltage.

        double batteryVoltage = BatterySim.calculateDefaultBatteryLoadedVoltage(
            shooterMotorSim.getCurrentDrawAmps() * 4,  // leader + 3 followers, all share the same flywheel load
            hoodArmSim.getCurrentDrawAmps(),
            feederMotorSim.getCurrentDrawAmps(),
            spindexerMotorSim.getCurrentDrawAmps(),
            intakeDeployMotorSim.getCurrentDrawAmps(),
            intakeRollerMotorSim.getCurrentDrawAmps()
        );
        batteryVoltage = Math.max(7.0, Math.min(12.5, batteryVoltage));
        // Set RoboRioSim voltage first so setInputVoltage's internal clamp uses the correct value.
        RoboRioSim.setVInVoltage(batteryVoltage);

        // ── Shooter flywheel ────────────────────────────────────────────────────
        shooterLeaderSimState.setSupplyVoltage(batteryVoltage);
        shooterMotorSim.setInputVoltage(-shooterLeaderSimState.getMotorVoltage());
        shooterMotorSim.update(DT);
        // DCMotorSim outputs CCW-positive; negate to CW-positive for Clockwise_Positive CTRE motor.
        shooterLeaderSimState.setRawRotorPosition(
            Rotations.of(-SHOOTER_GEAR_RATIO * shooterMotorSim.getAngularPositionRotations()));
        shooterLeaderSimState.setRotorVelocity(
            RotationsPerSecond.of(-SHOOTER_GEAR_RATIO * shooterMotorSim.getAngularVelocityRPM() / 60.0));

        // ── Hood (SingleJointedArmSim) ─────────────────────────────────────────
        // Hood convention: CW motor rotation = increasing angle (min→max), which maps to
        // SingleJointedArmSim's CCW-positive convention (positive voltage = increasing angle).
        // So no voltage negation and no writeback negation for the hood.
        hoodMotorSimState.setSupplyVoltage(batteryVoltage);
        hoodArmSim.setInputVoltage(hoodMotorSimState.getMotorVoltage());
        hoodArmSim.update(DT);
        // Map mechanism angle [HOOD_MIN_ANGLE_DEG, HOOD_MAX_ANGLE_DEG] to motor rotations [0, RobotMap.ShooterConstants.HOOD_FORWARD_SOFT_LIMIT_ROT].
        // This matches ShooterHood's ForwardSoftLimitThreshold and position lookup map (0–29 rot).
        // Note: this is independent of HOOD_GEAR_RATIO used for SingleJointedArmSim physics.
        double hoodAngleRad = hoodArmSim.getAngleRads();
        double hoodVelRadPerSec = hoodArmSim.getVelocityRadPerSec();
        double angleRange = Math.toRadians(HOOD_MAX_ANGLE_DEG) - Math.toRadians(HOOD_MIN_ANGLE_DEG);
        double hoodPositionRot = (hoodAngleRad - Math.toRadians(HOOD_MIN_ANGLE_DEG)) / angleRange * RobotMap.ShooterConstants.HOOD_FORWARD_SOFT_LIMIT_ROT;
        // (rad/s) / (rad) * rot = rot/s
        double hoodVelRotPerSec = hoodVelRadPerSec / angleRange * RobotMap.ShooterConstants.HOOD_FORWARD_SOFT_LIMIT_ROT;
        hoodMotorSimState.setRawRotorPosition(Rotations.of(hoodPositionRot));
        hoodMotorSimState.setRotorVelocity(RotationsPerSecond.of(hoodVelRotPerSec));

        // ── Feeder ────────────────────────────────────────────────────────────────
        feederMotorSimState.setSupplyVoltage(batteryVoltage);
        feederMotorSim.setInputVoltage(-feederMotorSimState.getMotorVoltage());
        feederMotorSim.update(DT);
        // DCMotorSim outputs CCW-positive; negate to CW-positive for Clockwise_Positive CTRE motor.
        feederMotorSimState.setRawRotorPosition(
            Rotations.of(-FEEDER_GEAR_RATIO * feederMotorSim.getAngularPositionRotations()));
        feederMotorSimState.setRotorVelocity(
            RotationsPerSecond.of(-FEEDER_GEAR_RATIO * feederMotorSim.getAngularVelocityRPM() / 60.0));

        // ── Spindexer ─────────────────────────────────────────────────────────────
        spindexerMotorSimState.setSupplyVoltage(batteryVoltage);
        spindexerMotorSim.setInputVoltage(-spindexerMotorSimState.getMotorVoltage());
        spindexerMotorSim.update(DT);
        // DCMotorSim outputs CCW-positive; negate to CW-positive for Clockwise_Positive CTRE motor.
        spindexerMotorSimState.setRawRotorPosition(
            Rotations.of(-SPINDEXER_GEAR_RATIO * spindexerMotorSim.getAngularPositionRotations()));
        spindexerMotorSimState.setRotorVelocity(
            RotationsPerSecond.of(-SPINDEXER_GEAR_RATIO * spindexerMotorSim.getAngularVelocityRPM() / 60.0));

        // ── Intake Deploy (CounterClockwise_Positive — no voltage negation) ──────
        intakeDeploySimState.setSupplyVoltage(batteryVoltage);
        intakeDeployMotorSim.setInputVoltage(intakeDeploySimState.getMotorVoltage());
        intakeDeployMotorSim.update(DT);
        intakeDeploySimState.setRawRotorPosition(
            Rotations.of(INTAKE_DEPLOY_GEAR_RATIO * intakeDeployMotorSim.getAngularPositionRotations()));
        intakeDeploySimState.setRotorVelocity(
            RotationsPerSecond.of(INTAKE_DEPLOY_GEAR_RATIO * intakeDeployMotorSim.getAngularVelocityRPM() / 60.0));

        // ── Intake Roller (CounterClockwise_Positive — no voltage negation) ──────
        intakeRollerSimState.setSupplyVoltage(batteryVoltage);
        intakeRollerMotorSim.setInputVoltage(intakeRollerSimState.getMotorVoltage());
        intakeRollerMotorSim.update(DT);
        intakeRollerSimState.setRawRotorPosition(
            Rotations.of(INTAKE_ROLLER_GEAR_RATIO * intakeRollerMotorSim.getAngularPositionRotations()));
        intakeRollerSimState.setRotorVelocity(
            RotationsPerSecond.of(INTAKE_ROLLER_GEAR_RATIO * intakeRollerMotorSim.getAngularVelocityRPM() / 60.0));

        // 12. Update shooter (unchanged)
        // ── Debug telemetry ──────────────────────────────────────────────────────
        Logger.recordOutput("Sim/Debug/ShooterVelocityRPS", shooterMotorSim.getAngularVelocityRPM() / 60.0);
        Logger.recordOutput("Sim/Debug/ShooterVoltageIn", shooterLeaderSimState.getMotorVoltage());
        Logger.recordOutput("Sim/Debug/FeederVelocityRPS", feederMotorSim.getAngularVelocityRPM() / 60.0);
        Logger.recordOutput("Sim/Debug/FeederVoltageIn", feederMotorSimState.getMotorVoltage());
        Logger.recordOutput("Sim/Debug/SpindexerVelocityRPS", spindexerMotorSim.getAngularVelocityRPM() / 60.0);
        Logger.recordOutput("Sim/Debug/SpindexerVoltageIn", spindexerMotorSimState.getMotorVoltage());
        Logger.recordOutput("Sim/Debug/HoodAngleDeg", Math.toDegrees(hoodArmSim.getAngleRads()));
        Logger.recordOutput("Sim/Debug/HoodVoltageIn", hoodMotorSimState.getMotorVoltage());
        Logger.recordOutput("Sim/Debug/HoodPositionRot",
            (hoodArmSim.getAngleRads() - Math.toRadians(HOOD_MIN_ANGLE_DEG)) / angleRange * RobotMap.ShooterConstants.HOOD_FORWARD_SOFT_LIMIT_ROT);
        Logger.recordOutput("Sim/Debug/IntakeDeployPositionRot", intakeSubsystem.getDeployMotorPositionRotations());
        Logger.recordOutput("Sim/Debug/IntakeDeployExtendedPct", Math.min(100.0, Math.max(0.0, intakeSubsystem.getDeployMotorPositionRotations() / IntakeSubsystem.EXTENDED_ROTATIONS * 100.0)));
        Logger.recordOutput("Sim/Debug/IntakeRollerVelocityRPS", intakeSubsystem.getRollerMotorVelocityRPS());
        Logger.recordOutput("Sim/Debug/IntakeZoneActive",
            intakeSubsystem.getDeployMotorPositionRotations() > IntakeSubsystem.EXTENDED_ROTATIONS
            && intakeSubsystem.getRollerMotorVelocityRPS() > INTAKE_ROLLER_VELOCITY_THRESHOLD_RPS);
        Logger.recordOutput("Sim/Debug/ShootingGateOpen",
            shooterMotorSim.getAngularVelocityRPM() / 60.0 > SHOOTER_VELOCITY_THRESHOLD_RPS
            && feederMotorSim.getAngularVelocityRPM() / 60.0 > FEEDER_VELOCITY_THRESHOLD_RPS);
        Logger.recordOutput("Sim/Debug/BatteryVoltage", batteryVoltage);
        Logger.recordOutput("Sim/Debug/FuelHeld", (double) gamePieceManager.getHeldCount());
        shooterSim.update(DT);

        // 13. Publish telemetry to NetworkTables
        publishTelemetry();
    }

    private void publishTelemetry() {
        Pose3d robotPose = chassis.getPose3d();
        Logger.recordOutput("Sim/RobotPose", robotPose);

        Translation2d virtualGoal = ShootOnTheMove.calculateVirtualGoal(lastSimPose, lastSimSpeeds);
        Logger.recordOutput("Sim/VirtualGoal",
            new Pose3d(virtualGoal.getX(), virtualGoal.getY(), FieldConstants.Hub.innerHeight,
                       new Rotation3d()));

        // Limelight direction lines (sim-only visualization)
        visionSimManager.getDirectionLines(robotPose).forEach((name, line) ->
                Logger.recordOutput("Sim/Limelights/" + name + "/DirectionLine", line));

        Logger.recordOutput("Sim/RobotGroundClearance", groundClearance.getClearance());
        Logger.recordOutput("Sim/RobotIsAirborne", groundClearance.isAirborne());

        Logger.recordOutput("Sim/FuelHeld", gamePieceManager.getHeldCount());

        Logger.recordOutput("Sim/Score", scoringTracker.getTotalScore());

        // Game piece poses for AdvantageScope
        gamePieceManager.publishPoses((key, poses) -> Logger.recordOutput(key, poses));

        // Component poses for articulated AdvantageScope robot model.
        // Array order must match the model_N.glb files in the AdvantageScope config.
        //
        // Moving parts need a position offset because CAD models have their origin at
        // the robot origin, not at their rotation axis. The AdvantageScope config uses
        // zeroPosition/zeroRotation to shift each model so its origin is at the axle,
        // then the code pose here places it back at the correct location with rotation
        // applied. Exception: spindexer star/omni wheel CAD files already have their
        // origin at the axle, so no zeroPosition was needed in the config.
        //
        //  0: Intake - Stationary          (static)
        //  1: Intake - Hopper              (extension translation only)
        //  2: Intake - Rollers             (Y rotation + extension translation)
        //  3: Spindexer - Assembly         (static)
        //  4: Spindexer - Omni Wheel 1     (Z rotation, axle 1)
        //  5: Spindexer - Star Wheel 1     (Z rotation, axle 1)
        //  6: Spindexer - Omni Wheel 2     (Z rotation, axle 2, opposite)
        //  7: Spindexer - Star Wheel 2     (Z rotation, axle 2, opposite)
        //  8: Feeder - Stationary          (static)
        //  9: Feeder - Wheels Lower Front  (Y rotation)
        // 10: Feeder - Wheels Lower Back   (Y rotation, opposite)
        // 11: Feeder - Wheels Top Front    (Y rotation)
        // 12: Feeder - Wheels Top Back     (Y rotation, opposite)
        // 13: Shooter - Stationary Base    (static)
        // 14: Shooter - Hood               (Y rotation, hood angle)
        // 15: Shooter - Wheels             (Y rotation)

        // Intake extension: scale deploy position [0, EXTENDED_ROTATIONS] → [0, 1] fraction
        double deployFraction = Math.min(1.0,
            Math.max(0.0, intakeSubsystem.getDeployMotorPositionRotations() / IntakeSubsystem.EXTENDED_ROTATIONS));
        Translation3d intakeExtension = new Translation3d(
            INTAKE_EXTEND_X * deployFraction, 0, INTAKE_EXTEND_Z * deployFraction);

        double rollerAngle = -(intakeSubsystem.getRollerMotorPositionRotations() * 2 * Math.PI) % (2 * Math.PI);
        double spindexerAngle = (spindexerMotorSim.getAngularPositionRotations() * 2 * Math.PI) % (2 * Math.PI);
        double feederAngle = (feederMotorSim.getAngularPositionRotations() * 2 * Math.PI) % (2 * Math.PI);
        double shooterAngle = (shooterMotorSim.getAngularPositionRotations() * 2 * Math.PI) % (2 * Math.PI);
        // Hood visual angle: physics sim angle minus visual model offset
        double hoodAngle = hoodArmSim.getAngleRads() - HOOD_VISUAL_OFFSET_RAD;

        Logger.recordOutput("Sim/ComponentPoses",
                new Pose3d[]{
                    new Pose3d(),                                                                                //  0: Intake - Stationary
                    new Pose3d(intakeExtension, new Rotation3d()),                                               //  1: Intake - Hopper
                    new Pose3d(intakeExtension.plus(
                        new Translation3d(-0.2812, 0, 0.2627)), 
                        new Rotation3d(0, rollerAngle, 0)),                                                      //  2: Intake - Rollers
                    new Pose3d(),                                                                                //  3: Spindexer - Assembly
                    new Pose3d(new Translation3d(0.002, 0.0635, 0.184), new Rotation3d(0, 0, spindexerAngle)),   //  4: Spindexer - Omni 1
                    new Pose3d(new Translation3d(0.002, 0.0635, 0.318), new Rotation3d(0, 0, spindexerAngle)),   //  5: Spindexer - Star 1
                    new Pose3d(new Translation3d(0.002, -0.0635, 0.184), new Rotation3d(0, 0, -spindexerAngle)), //  6: Spindexer - Omni 2
                    new Pose3d(new Translation3d(0.002, -0.0635, 0.318), new Rotation3d(0, 0, -spindexerAngle)), //  7: Spindexer - Star 2
                    new Pose3d(),                                                                                //  8: Feeder - Stationary
                    new Pose3d(new Translation3d(0.118, 0, 0.280), new Rotation3d(0, -feederAngle, 0)),          //  9: Feeder - Lower Front
                    new Pose3d(new Translation3d(0.316, 0, 0.257), new Rotation3d(0, feederAngle, 0)),           // 10: Feeder - Lower Back
                    new Pose3d(new Translation3d(0.075, 0, 0.380), new Rotation3d(0, -feederAngle, 0)),          // 11: Feeder - Top Front
                    new Pose3d(new Translation3d(0.270, 0, 0.360), new Rotation3d(0, feederAngle, 0)),           // 12: Feeder - Top Back
                    new Pose3d(),                                                                                // 13: Shooter - Stationary Base
                    new Pose3d(
                        new Translation3d(SHOOTER_HOOD_FORWARD_X, 0.0, 0.500), 
                        new Rotation3d(0, -hoodAngle, 0)),                                                       // 14: Shooter - Hood
                    new Pose3d(new Translation3d(0.286, 0, 0.558), new Rotation3d(0, shooterAngle, 0)),          // 15: Shooter - Wheels
                });
    }

    /** Get the chassis simulation. */
    public ChassisSimulation getChassis() { return chassis; }

    /** Get the physics world. */
    public PhysicsWorld getPhysicsWorld() { return physicsWorld; }

    /** Get the game piece manager. */
    public GamePieceManager getGamePieceManager() { return gamePieceManager; }

    /** Get the scoring tracker. */
    public ScoringTracker getScoringTracker() { return scoringTracker; }

    // --- MapleSim motor controller adapters ---
    //
    // MapleSim owns the motor physics (voltage -> torque -> mechanism state) but has
    // no knowledge of CTRE's TalonFX/CANcoder sim APIs. These adapters close the loop:
    //
    //   MapleSim  ---(position, velocity)--->  Adapter  ---(setRawRotorPosition, etc.)--->  TalonFX SimState
    //   MapleSim  <---(commanded voltage)---   Adapter  <---(getMotorVoltageMeasure)----   TalonFX SimState
    //
    // This lets robot code read realistic encoder values while MapleSim computes the physics.

    /**
     * Adapter that bridges MapleSim's motor simulation API to a single CTRE TalonFX.
     *
     * <p>Each tick, MapleSim calls {@link #updateControlSignal} with the mechanism state
     * it computed (position and velocity). This adapter writes those values into the
     * TalonFX's sim state so that robot code sees realistic encoder readings, then
     * returns the motor's commanded voltage back to MapleSim for force computation.
     *
     * <p>Battery voltage is sourced from {@link SimulatedBattery} so brownout effects
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
     * <p>Used for swerve steer modules where the TalonFX uses a fused/remote CANcoder
     * for absolute position feedback. MapleSim provides the mechanism angle (steering
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
