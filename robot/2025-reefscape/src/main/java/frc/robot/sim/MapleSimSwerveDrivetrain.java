package frc.robot.sim;

// Ported from Iron Maple 5516's CTRE-Swerve-MapleSim template
// https://github.com/shenzhen-robotics-alliance/CTRE-Swerve-MapleSim
// Licensed under MIT license (https://mit-license.org/)

import static edu.wpi.first.units.Units.*;

import com.ctre.phoenix6.configs.CANcoderConfiguration;
import com.ctre.phoenix6.configs.Slot0Configs;
import com.ctre.phoenix6.configs.TalonFXConfiguration;
import com.ctre.phoenix6.hardware.CANcoder;
import com.ctre.phoenix6.hardware.Pigeon2;
import com.ctre.phoenix6.hardware.TalonFX;
import com.ctre.phoenix6.signals.StaticFeedforwardSignValue;
import com.ctre.phoenix6.sim.CANcoderSimState;
import com.ctre.phoenix6.sim.Pigeon2SimState;
import com.ctre.phoenix6.sim.TalonFXSimState;
import com.ctre.phoenix6.swerve.SwerveDrivetrain;
import com.ctre.phoenix6.swerve.SwerveModule;
import com.ctre.phoenix6.swerve.SwerveModuleConstants;
import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.math.system.plant.DCMotor;
import edu.wpi.first.units.measure.*;
import edu.wpi.first.wpilibj.RobotBase;
import org.ironmaple.simulation.SimulatedArena;
import org.ironmaple.simulation.drivesims.COTS;
import org.ironmaple.simulation.drivesims.SwerveDriveSimulation;
import org.ironmaple.simulation.drivesims.SwerveModuleSimulation;
import org.ironmaple.simulation.drivesims.configs.DriveTrainSimulationConfig;
import org.ironmaple.simulation.drivesims.configs.SwerveModuleSimulationConfig;
import org.ironmaple.simulation.motorsims.SimulatedBattery;
import org.ironmaple.simulation.motorsims.SimulatedMotorController;

/**
 * Injects Maple-Sim simulation data into a CTRE swerve drivetrain.
 * Replaces the built-in SimSwerveDrivetrain with physics-aware simulation
 * (wall collisions, game piece interaction, friction).
 */
public class MapleSimSwerveDrivetrain {
    private final Pigeon2SimState pigeonSim;
    private final SimSwerveModule[] simModules;
    public final SwerveDriveSimulation mapleSimDrive;

    /**
     * Constructs a drivetrain simulation using the specified parameters.
     *
     * @param simPeriod the time period of the simulation
     * @param robotMassWithBumpers the total mass of the robot, including bumpers
     * @param bumperLengthX the length of the bumper along the X-axis
     * @param bumperWidthY the width of the bumper along the Y-axis
     * @param driveMotorModel the DCMotor model for the drive motor
     * @param steerMotorModel the DCMotor model for the steer motor
     * @param wheelCOF the coefficient of friction of the drive wheels
     * @param moduleLocations the locations of the swerve modules (FL, FR, BL, BR)
     * @param startingPose the initial pose of the robot on the field
     * @param pigeon the Pigeon2 IMU
     * @param modules the SwerveModules from the drivetrain
     * @param moduleConstants the constants for the swerve modules
     */
    @SafeVarargs
    public MapleSimSwerveDrivetrain(
            Time simPeriod,
            Mass robotMassWithBumpers,
            Distance bumperLengthX,
            Distance bumperWidthY,
            DCMotor driveMotorModel,
            DCMotor steerMotorModel,
            double wheelCOF,
            Translation2d[] moduleLocations,
            Pose2d startingPose,
            Pigeon2 pigeon,
            SwerveModule<TalonFX, TalonFX, CANcoder>[] modules,
            SwerveModuleConstants<TalonFXConfiguration, TalonFXConfiguration, CANcoderConfiguration>...
                    moduleConstants) {
        this.pigeonSim = pigeon.getSimState();
        simModules = new SimSwerveModule[moduleConstants.length];
        DriveTrainSimulationConfig simulationConfig = DriveTrainSimulationConfig.Default()
                .withRobotMass(robotMassWithBumpers)
                .withBumperSize(bumperLengthX, bumperWidthY)
                .withGyro(COTS.ofPigeon2())
                .withCustomModuleTranslations(moduleLocations)
                .withSwerveModule(new SwerveModuleSimulationConfig(
                        driveMotorModel,
                        steerMotorModel,
                        moduleConstants[0].DriveMotorGearRatio,
                        moduleConstants[0].SteerMotorGearRatio,
                        Volts.of(moduleConstants[0].DriveFrictionVoltage),
                        Volts.of(moduleConstants[0].SteerFrictionVoltage),
                        Meters.of(moduleConstants[0].WheelRadius),
                        KilogramSquareMeters.of(moduleConstants[0].SteerInertia),
                        wheelCOF));
        mapleSimDrive = new SwerveDriveSimulation(simulationConfig, startingPose);

        SwerveModuleSimulation[] moduleSimulations = mapleSimDrive.getModules();
        for (int i = 0; i < this.simModules.length; i++)
            simModules[i] = new SimSwerveModule(moduleConstants[0], moduleSimulations[i], modules[i]);

        SimulatedArena.overrideSimulationTimings(simPeriod, 1);
        SimulatedArena.getInstance().addDriveTrainSimulation(mapleSimDrive);
    }

    /**
     * Updates the Maple-Sim simulation and injects results into simulated CTRE devices.
     */
    public void update() {
        SimulatedArena.getInstance().simulationPeriodic();
        pigeonSim.setRawYaw(
                mapleSimDrive.getSimulatedDriveTrainPose().getRotation().getMeasure());
        pigeonSim.setAngularVelocityZ(RadiansPerSecond.of(
                mapleSimDrive.getDriveTrainSimulatedChassisSpeedsRobotRelative().omegaRadiansPerSecond));
    }

    protected static class SimSwerveModule {
        public final SwerveModuleConstants<TalonFXConfiguration, TalonFXConfiguration, CANcoderConfiguration>
                moduleConstant;
        public final SwerveModuleSimulation moduleSimulation;

        public SimSwerveModule(
                SwerveModuleConstants<TalonFXConfiguration, TalonFXConfiguration, CANcoderConfiguration> moduleConstant,
                SwerveModuleSimulation moduleSimulation,
                SwerveModule<TalonFX, TalonFX, CANcoder> module) {
            this.moduleConstant = moduleConstant;
            this.moduleSimulation = moduleSimulation;
            moduleSimulation.useDriveMotorController(new TalonFXMotorControllerSim(module.getDriveMotor()));
            moduleSimulation.useSteerMotorController(
                    new TalonFXMotorControllerWithRemoteCanCoderSim(module.getSteerMotor(), module.getEncoder()));
        }
    }

    public static class TalonFXMotorControllerSim implements SimulatedMotorController {
        public final int id;
        private final TalonFXSimState talonFXSimState;

        public TalonFXMotorControllerSim(TalonFX talonFX) {
            this.id = talonFX.getDeviceID();
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

    public static class TalonFXMotorControllerWithRemoteCanCoderSim extends TalonFXMotorControllerSim {
        private final CANcoderSimState remoteCancoderSimState;

        public TalonFXMotorControllerWithRemoteCanCoderSim(TalonFX talonFX, CANcoder cancoder) {
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

    /**
     * Regulates SwerveModuleConstants for simulation. Disables encoder offsets,
     * motor inversions, and overrides steer PID for simulation compatibility.
     * No-op on a real robot.
     */
    public static SwerveModuleConstants<?, ?, ?>[] regulateModuleConstantsForSimulation(
            SwerveModuleConstants<?, ?, ?>[] moduleConstants) {
        for (SwerveModuleConstants<?, ?, ?> moduleConstant : moduleConstants)
            regulateModuleConstantForSimulation(moduleConstant);
        return moduleConstants;
    }

    private static void regulateModuleConstantForSimulation(SwerveModuleConstants<?, ?, ?> moduleConstants) {
        if (RobotBase.isReal()) return;

        moduleConstants
                .withEncoderOffset(0)
                .withDriveMotorInverted(false)
                .withSteerMotorInverted(false)
                .withEncoderInverted(false)
                .withSteerMotorGains(new Slot0Configs()
                        .withKP(70)
                        .withKI(0)
                        .withKD(4.5)
                        .withKS(0)
                        .withKV(1.91)
                        .withKA(0)
                        .withStaticFeedforwardSign(StaticFeedforwardSignValue.UseClosedLoopSign))
                .withSteerMotorGearRatio(16.0)
                .withDriveFrictionVoltage(Volts.of(0.1))
                .withSteerFrictionVoltage(Volts.of(0.05))
                .withSteerInertia(KilogramSquareMeters.of(0.05));
    }
}
