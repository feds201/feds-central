package frc.robot.utils;

import java.util.ArrayList;

import com.ctre.phoenix6.hardware.CANcoder;
import com.ctre.phoenix6.hardware.TalonFX;
import com.ctre.phoenix6.swerve.SwerveRequest;

import edu.wpi.first.networktables.GenericEntry;
import edu.wpi.first.wpilibj.shuffleboard.BuiltInLayouts;
import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardLayout;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardTab;
import edu.wpi.first.wpilibj2.command.Commands;
import frc.robot.subsystems.intake.IntakeSubsystem;
import frc.robot.subsystems.intake.IntakeSubsystem.IntakeState;
import frc.robot.subsystems.feeder.Feeder;
import frc.robot.subsystems.feeder.Feeder.feeder_state;
import frc.robot.subsystems.shooter.ShooterHood;
import frc.robot.subsystems.shooter.ShooterHood.shooterhood_state;
import frc.robot.subsystems.shooter.ShooterWheels;
import frc.robot.subsystems.shooter.ShooterWheels.shooter_state;
import frc.robot.subsystems.spindexer.Spindexer;
import frc.robot.subsystems.spindexer.Spindexer.spindexer_state;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.RobotContainer;
import frc.robot.RobotMap;


public class PitTesting {
    static RobotContainer container = RobotContainer.getInstance();

    static CommandSwerveDrivetrain drivetrain = container.getDrivetrain();
    static IntakeSubsystem intake = container.getIntakeSubsystem();
    static Feeder feeder = container.getFeederSubsystem();
    static Spindexer spindexer = container.getSpindexer();
    static ShooterHood shooterHood = container.getShooterHood();
    static ShooterWheels shooterWheels = container.getShooterWheels();

    static double poweredThreshold = RobotMap.PitConstants.kPoweredThresholdVolts;
    
    private static ShuffleboardTab pitTab = Shuffleboard.getTab("Pit Testing");

    private static ArrayList<GenericEntry> pitEntries = new ArrayList<GenericEntry>();

    private static ShuffleboardLayout testLayout = Shuffleboard.getTab("Pit Commands")
            .getLayout("Test Commands", BuiltInLayouts.kList)
            .withSize(2, 5);
    private static SwerveRequest.FieldCentric driveRequest = new SwerveRequest.FieldCentric();
    
    private static double testTime = 1.5;
    private static double drivetrainTestTime = 0.75;

    private static String[] moduleNames = {"Front Left", "Front Right", "Back Left", "Back Right"};

    public static void createDashboard() {
        registerEntry("feeder");
        registerEntry("intake");
        registerEntry("roller");
        registerEntry("shooter hood");
        registerEntry("Top Right");
        registerEntry("Bottom Left");
        registerEntry("Bottom Right");
        registerEntry("Top Left");
        
        //drivetrain
        for (int i = 0; i < 4; ++i) {
            registerEntry("drive" + (i + 1));
            registerEntry("steer" + (i + 1));
            registerEntry("encoder" + (i + 1));
        }

        registerEntry("pigeon");

        // Add commands
        testLayout.add("Run Feeder", Commands.sequence(
            feeder.setStateCommand(feeder_state.RUN),
            Commands.waitSeconds(testTime),
            feeder.setStateCommand(feeder_state.STOP)));
        
        testLayout.add("Run Intake", Commands.sequence(
            intake.setIntakeStateCommand(IntakeState.INTAKING),
            Commands.waitSeconds(testTime),
            intake.setIntakeStateCommand(IntakeState.DEFAULT)));
        
        testLayout.add("Run Intake and Rollers", Commands.sequence(
            intake.setIntakeStateCommand(IntakeState.EXTENDED),
            Commands.waitSeconds(testTime),
            intake.setIntakeStateCommand(IntakeState.DEFAULT)));

        testLayout.add("Run Spindexer", Commands.sequence(
            spindexer.setStateCommand(spindexer_state.RUN),
            Commands.waitSeconds(testTime),
            spindexer.setStateCommand(spindexer_state.STOP)));

        testLayout.add("Run Shooter Wheels", Commands.sequence(
            shooterWheels.setStateCommand(shooter_state.SHOOTING),
            Commands.waitSeconds(testTime),
            shooterWheels.setStateCommand(shooter_state.IDLE)));
        
        testLayout.add("Move Shooter Hood", Commands.sequence(
            shooterHood.setStateCommand(shooterhood_state.OUT),
            Commands.waitSeconds(testTime),
            shooterHood.setStateCommand(shooterhood_state.IN)));
        
        testLayout.add("test Drivetrain translation", Commands.sequence(
            drivetrain.runOnce(() -> drivetrain.setControl(driveRequest
                .withVelocityX(0.5))),
            Commands.waitSeconds(drivetrainTestTime),
            drivetrain.runOnce(() -> drivetrain.setControl(new SwerveRequest.Idle()))));

        testLayout.add("test Drivetrain rotation", Commands.sequence(
            drivetrain.runOnce(() -> drivetrain.setControl(driveRequest
                .withRotationalRate(1.0))),
            Commands.waitSeconds(drivetrainTestTime),
            drivetrain.runOnce(() -> drivetrain.setControl(new SwerveRequest.Idle()))));
    }

    public static void updateDashboard() {

        updateEntry("feeder");
        updateEntry("intake");
        updateEntry("roller");
        updateEntry("shooterHood");
        updateEntry("shooterWheels");
        updateEntry("spindexer");

        for (int i = 0; i < 4; ++i) {
            updateEntry("drive" + (i + 1));
            updateEntry("steer" + (i + 1));
            updateEntry("encoder" + (i + 1));
        }

        updateEntry("pigeon");
    }

    private static void registerEntry(String name){
        pitEntries.add(pitTab.add(name + " Motor is Connected", false).getEntry());  
        pitEntries.add(pitTab.add(name + " Motor is Powered", false).getEntry());
    }

    private static void updateEntry(String name){
        pitEntries.get(pitEntries.indexOf(pitTab.add(name + " Motor is Connected", false).getEntry())).setBoolean(shooterHood.getShooterHoodMotor().isConnected());
    }
}