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
import frc.robot.subsystems.feeder.Feeder;
import frc.robot.subsystems.feeder.Feeder.feeder_state;
import frc.robot.subsystems.intake.IntakeSubsystem;
import frc.robot.subsystems.intake.IntakeSubsystem.IntakeState;
import frc.robot.subsystems.intake.RollersSubsystem;
import frc.robot.subsystems.shooter.ShooterHood;
import frc.robot.subsystems.shooter.ShooterHood.shooterhood_state;
import frc.robot.subsystems.shooter.ShooterWheels;
import frc.robot.subsystems.shooter.ShooterWheels.shooter_state;
import frc.robot.subsystems.spindexer.Spindexer;
import frc.robot.subsystems.spindexer.Spindexer.spindexer_state;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.subsystems.swerve.generated.TunerConstants;
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
import frc.sim.telemetry.SimTelemetry;

import java.util.List;
import java.util.Map;
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
    private static final int HOPPER_CAPACITY = 70;

    // ── Intake zone bounds (robot-relative, placeholder) ───────────────────

    /** Intake zone forward start distance from robot center. */
    private static final double INTAKE_X_MIN = 0.35;
    /** Intake zone forward end distance from robot center. */
    private static final double INTAKE_X_MAX = 0.5;
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

    /** Hood adjustment rate when aiming (placeholder, rad/s). */
    private static final double HOOD_ADJUST_RATE = Math.toRadians(30);
    /** Minimum sim hood angle (placeholder). */
    private static final double HOOD_MIN_RAD = Math.toRadians(10);
    /** Maximum sim hood angle (placeholder). */
    private static final double HOOD_MAX_RAD = Math.toRadians(80);
    /** Default sim hood angle (placeholder). */
    private static final double HOOD_DEFAULT_RAD = Math.toRadians(45);
    /** Fixed launch speed when shooting (placeholder, m/s). */
    private static final double LAUNCH_SPEED_MPS = 6.0;

    // ── Component animation speeds (rad/s) ─────────────────────────────────

    private static final double INTAKE_ROLLER_SPEED = 10.0;
    private static final double FEEDER_ROLLER_SPEED = 15.0;
    private static final double SHOOTER_ROLLER_SPEED = 30.0;

    // ── Fuel detection Limelight (limelight-one, rear-facing) ───────────────

    private static final String FUEL_LL_NAME = "limelight-one";
    private static final Transform3d FUEL_LL_MOUNT = new Transform3d(
            new Translation3d(-0.4, 0, 0.305),
            new Rotation3d(0, Math.toRadians(30), Math.toRadians(180)));
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
    private final SimTelemetry telemetry;

    // MapleSim swerve simulation
    private final SwerveDriveSimulation mapleSimDrive;
    private final SwerveModuleSimulation[] moduleSimulations;

    // References to robot subsystems
    private final CommandSwerveDrivetrain drivetrain;
    private final RollersSubsystem intake;
    private final IntakeSubsystem intakeSubsystem;
    private final Feeder feeder;
    private final ShooterWheels shooterWheels;
    private final ShooterHood shooterHood;
    private final Spindexer spindexer;

    // CTRE sim state (for gyro only — MapleSim handles motor/encoder sim state)
    private final Pigeon2SimState pigeonSimState;

    // Animation angle accumulators (radians)
    private double rollerAngleAccum = 0;
    private double feederAngleAccum = 0;
    private double shooterRollerAngleAccum = 0;

    // Sim-managed hood angle (adjusted by watching ShooterHood state)
    private double simHoodAngleRad = HOOD_DEFAULT_RAD;

    /**
     * Create the simulation manager and initialize both physics engines.
     *
     * <p>Sets up MapleSim for drivetrain physics and ODE4J for game piece physics,
     * wires motor controller adapters, spawns starting fuel, and configures
     * intake/shooter/scoring systems.
     *
     * @param drivetrain      the swerve drivetrain subsystem (motor and encoder references)
     * @param intake          the rollers subsystem (roller active state)
     * @param intakeSubsystem the intake deploy subsystem (extended/retracted state)
     * @param feeder          the feeder subsystem (run/stop state)
     * @param shooterWheels   the shooter wheels subsystem (flywheel state)
     * @param shooterHood     the shooter hood subsystem (aiming state)
     * @param spindexer       the spindexer subsystem (run/stop state)
     */
    public RebuiltSimManager(CommandSwerveDrivetrain drivetrain, RollersSubsystem intake,
                             IntakeSubsystem intakeSubsystem, Feeder feeder,
                             ShooterWheels shooterWheels, ShooterHood shooterHood,
                             Spindexer spindexer) {
        this.drivetrain = drivetrain;
        this.intake = intake;
        this.intakeSubsystem = intakeSubsystem;
        this.feeder = feeder;
        this.shooterWheels = shooterWheels;
        this.shooterHood = shooterHood;
        this.spindexer = spindexer;

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
                () -> intake.getState() == RollersSubsystem.RollerState.ON
                        && intakeSubsystem.getState() == IntakeState.EXTENDED,
                () -> chassis.getPose2d());

        // --- Shooter ---
        Logger.recordOutput("Sim/State", "Loading shooter");
        // ShooterSim watches real subsystem states:
        // - Hood angle: managed by sim (adjusted when ShooterHood is AIMING_UP/DOWN)
        // - Launch velocity: fixed placeholder speed
        // - Shooting gate: wheels must be SHOOTING + feeder and spindexer must be RUN
        shooterSim = new ShooterSim(
                gamePieceManager,
                RebuiltGamePieces.FUEL,
                () -> chassis.getPose2d(),
                () -> simHoodAngleRad,
                () -> LAUNCH_SPEED_MPS,
                () -> shooterWheels.getCurrentState() == shooter_state.SHOOTING
                        && feeder.getCurrentState() == feeder_state.RUN
                        && spindexer.getCurrentState() == spindexer_state.RUN,
                () -> chassis.getBody().getLinearVel().get0(),
                () -> chassis.getBody().getLinearVel().get1());

        // --- Scoring & Telemetry ---
        Logger.recordOutput("Sim/State", "Loading scoring");
        scoringTracker = new ScoringTracker();
        groundClearance = new GroundClearance(chassis.getBody(), chassisConfig.getBumperHeight());
        telemetry = new SimTelemetry(chassis);

        // --- Vision sim (writes true pose to NT in Limelight format) ---
        Logger.recordOutput("Sim/State", "Loading vision");
        // Camera mounts: LL4 front-right, LL3 front-left, both 7.7" high, 25° inward yaw, 30° upward pitch
        Transform3d ll4Mount = new Transform3d(
                new Translation3d(0.27, -0.27, 0.1956),
                new Rotation3d(0, Math.toRadians(-30), Math.toRadians(25)));
        Transform3d ll3Mount = new Transform3d(
                new Translation3d(0.27, 0.27, 0.1956),
                new Rotation3d(0, Math.toRadians(-30), Math.toRadians(-25)));
        LimelightSim ll4Cam = new LimelightSim(
                new CameraConfig("limelight-two", LimelightType.LL4, ll4Mount));
        LimelightSim ll3Cam = new LimelightSim(
                new CameraConfig("limelight-five", LimelightType.LL3, ll3Mount));
        LimelightSim fuelCam = new LimelightSim(
                new CameraConfig(FUEL_LL_NAME, LimelightType.LL4, FUEL_LL_MOUNT),
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

        // 11. Update sim hood angle based on ShooterHood state
        shooterhood_state hoodState = shooterHood.getCurrentState();
        if (hoodState == shooterhood_state.AIMING_UP) {
            simHoodAngleRad = Math.min(HOOD_MAX_RAD, simHoodAngleRad + HOOD_ADJUST_RATE * DT);
        } else if (hoodState == shooterhood_state.AIMING_DOWN) {
            simHoodAngleRad = Math.max(HOOD_MIN_RAD, simHoodAngleRad - HOOD_ADJUST_RATE * DT);
        }
        shooterHood.setSimPosition(simHoodAngleRad / (2 * Math.PI));

        // 12. Update shooter
        shooterSim.update(DT);

        // 13. Update animation accumulators
        if (intake.getState() == RollersSubsystem.RollerState.ON) {
            rollerAngleAccum += INTAKE_ROLLER_SPEED * DT;
        }
        if (shooterWheels.getCurrentState() == shooter_state.SHOOTING) {
            feederAngleAccum += FEEDER_ROLLER_SPEED * DT;
            shooterRollerAngleAccum += SHOOTER_ROLLER_SPEED * DT;
        }

        // 14. Publish telemetry to NetworkTables
        publishTelemetry();
    }

    private void publishTelemetry() {
        Pose3d robotPose = chassis.getPose3d();
        Logger.recordOutput("Sim/RobotPose", robotPose);

        // Limelight direction lines (sim-only visualization)
        visionSimManager.getDirectionLines(robotPose).forEach((name, line) ->
                Logger.recordOutput("Sim/Limelights/" + name + "/DirectionLine", line));

        Logger.recordOutput("Sim/RobotGroundClearance", groundClearance.getClearance());
        Logger.recordOutput("Sim/RobotIsAirborne", groundClearance.isAirborne());

        Logger.recordOutput("Sim/FuelHeld", gamePieceManager.getHeldCount());

        Logger.recordOutput("Sim/Score", scoringTracker.getTotalScore());

        // Game piece poses for AdvantageScope
        gamePieceManager.publishPoses((key, poses) -> Logger.recordOutput(key, poses));

        // Component poses for articulated AdvantageScope robot model
        boolean intaking = intake.getState() == RollersSubsystem.RollerState.ON;
        boolean shooting = shooterWheels.getCurrentState() == shooter_state.SHOOTING;

        Pose3d shooterHoodPose = new Pose3d(
                new Translation3d(),
                new Rotation3d(simHoodAngleRad - Math.PI / 4, 0, 0));

        double rollerAngle = intaking ? (rollerAngleAccum % (2 * Math.PI)) : 0;
        Pose3d intakeRollerPose = new Pose3d(
                new Translation3d(),
                new Rotation3d(rollerAngle, 0, 0));

        double feederAngle = shooting ? (feederAngleAccum % (2 * Math.PI)) : 0;
        Pose3d feederRollerPose = new Pose3d(
                new Translation3d(),
                new Rotation3d(feederAngle, 0, 0));

        double shooterRollerAngle = shooting ? (shooterRollerAngleAccum % (2 * Math.PI)) : 0;
        Pose3d shooterRollerPose = new Pose3d(
                new Translation3d(),
                new Rotation3d(shooterRollerAngle, 0, 0));

        Pose3d verticalFeederPose = new Pose3d(
                new Translation3d(),
                new Rotation3d(0, feederAngle, 0));

        Logger.recordOutput("Sim/ComponentPoses",
                new Pose3d[]{
                    shooterHoodPose,
                    intakeRollerPose,
                    feederRollerPose,
                    feederRollerPose,
                    verticalFeederPose,
                    verticalFeederPose,
                    shooterRollerPose,
                    new Pose3d()
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
