package frc.robot.utils;

import java.util.ArrayList;

import com.ctre.phoenix6.Orchestra;
import com.ctre.phoenix6.hardware.CANcoder;
import com.ctre.phoenix6.hardware.Pigeon2;
import com.ctre.phoenix6.hardware.TalonFX;
import com.ctre.phoenix6.swerve.SwerveRequest;

import edu.wpi.first.wpilibj2.command.*;
import edu.wpi.first.networktables.GenericEntry;
import edu.wpi.first.wpilibj.shuffleboard.BuiltInLayouts;
import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardLayout;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardTab;
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
    static double poweredThreshold = RobotMap.PitConstants.kPoweredThresholdVolts;


    static RobotContainer container = RobotContainer.getInstance();

    static CommandSwerveDrivetrain drivetrain = container.getDrivetrain();
    static IntakeSubsystem intake = container.getIntakeSubsystem();
    static Feeder feeder = container.getFeederSubsystem();
    static Spindexer spindexer = container.getSpindexer();
    static ShooterHood shooterHood = container.getShooterHood();
    static ShooterWheels shooterWheels = container.getShooterWheels();

    private static String[] moduleNames = {"Front Left", "Front Right", "Back Left", "Back Right"};

    private static SwerveRequest.FieldCentric driveRequest = new SwerveRequest.FieldCentric();
   
    
    private static ShuffleboardTab pitTab = Shuffleboard.getTab("Pit Testing");
    private static ArrayList<GenericEntry> pitEntries = new ArrayList<GenericEntry>();
    private static ShuffleboardLayout testLayout = Shuffleboard.getTab("Pit Commands")
            .getLayout("Test Commands", BuiltInLayouts.kList)
            .withSize(2, 5);


    private static double testTime = 1.5;
    private static double drivetrainTestTime = 0.75;
    private static double musicTime = 3.0;


    private static Orchestra orchestra = new Orchestra();



    public static void createDashboard() {
        //sound
        orchestra.addInstrument(feeder.getFeederMotor());
        orchestra.addInstrument(intake.getIntakeMotor());
        orchestra.addInstrument(intake.getRollerMotor());
        orchestra.addInstrument(shooterHood.getShooterHoodMotor());
        orchestra.addInstrument(shooterWheels.getShooterLeader());
        orchestra.addInstrument(shooterWheels.getShooterFollower1());
        orchestra.addInstrument(shooterWheels.getShooterFollower2());
        orchestra.addInstrument(shooterWheels.getShooterFollower3());

        for (int i = 0; i < 4; ++i) {
            orchestra.addInstrument(drivetrain.getModule(i).getDriveMotor());
            orchestra.addInstrument(drivetrain.getModule(i).getSteerMotor());
            orchestra.addInstrument(drivetrain.getModule(i).getEncoder());
        }

        //TODO: add music
        var status = orchestra.loadMusic("track.chrp");
        if(!status.isOK()) {
            System.out.println("Failed to load music");
        }

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

        Command music = new SequentialCommandGroup(
            new InstantCommand(() -> Elastic.sendNotification(new Elastic.Notification(Elastic.NotificationLevel.ERROR, "Robot Enabling", "Clear the area"))),
            new InstantCommand(() -> orchestra.play()),
            Commands.waitSeconds(musicTime),
            new InstantCommand(() -> orchestra.stop())); 

        // Add commands
        testLayout.add("Run Feeder", Commands.sequence(
            music,
            feeder.setStateCommand(feeder_state.RUN),
            Commands.waitSeconds(testTime),
            feeder.setStateCommand(feeder_state.STOP)));
        
        testLayout.add("Run Intake", Commands.sequence(
            music,
            intake.setIntakeStateCommand(IntakeState.INTAKING),
            Commands.waitSeconds(testTime),
            intake.setIntakeStateCommand(IntakeState.DEFAULT)));
        
        testLayout.add("Run Intake and Rollers", Commands.sequence(
            music,
            intake.setIntakeStateCommand(IntakeState.EXTENDED),
            Commands.waitSeconds(testTime),
            intake.setIntakeStateCommand(IntakeState.DEFAULT)));

        testLayout.add("Run Spindexer", Commands.sequence(
            music,
            spindexer.setStateCommand(spindexer_state.RUN),
            Commands.waitSeconds(testTime),
            spindexer.setStateCommand(spindexer_state.STOP)));

        testLayout.add("Run Shooter Wheels", Commands.sequence(
            music,
            shooterWheels.setStateCommand(shooter_state.SHOOTING),
            Commands.waitSeconds(testTime),
            shooterWheels.setStateCommand(shooter_state.IDLE)));
        
        testLayout.add("Move Shooter Hood", Commands.sequence(
            music,
            shooterHood.setStateCommand(shooterhood_state.OUT),
            Commands.waitSeconds(testTime),
            shooterHood.setStateCommand(shooterhood_state.IN)));
        
        testLayout.add("test Drivetrain translation", Commands.sequence(
            music,
            drivetrain.runOnce(() -> drivetrain.setControl(driveRequest
                .withVelocityX(0.5))),
            Commands.waitSeconds(drivetrainTestTime),
            drivetrain.runOnce(() -> drivetrain.setControl(new SwerveRequest.Idle()))));

        testLayout.add("test Drivetrain rotation", Commands.sequence(
            music,
            drivetrain.runOnce(() -> drivetrain.setControl(driveRequest
                .withRotationalRate(1.0))),
            Commands.waitSeconds(drivetrainTestTime),
            drivetrain.runOnce(() -> drivetrain.setControl(new SwerveRequest.Idle()))));
    }

    public static void updateDashboard() {

        updateEntry("feeder", feeder.getFeederMotor());
        updateEntry("intake", intake.getIntakeMotor());
        updateEntry("roller", intake.getRollerMotor());
        updateEntry("Hood", shooterHood.getShooterHoodMotor());
        updateEntry("RightTop", shooterWheels.getShooterLeader());
        updateEntry("BottomLeft", shooterWheels.getShooterFollower1());
        updateEntry("BottomRight", shooterWheels.getShooterFollower2());
        updateEntry("TopLeft", shooterWheels.getShooterFollower3());
        updateEntry("spindexer", spindexer.getSpindexerMotor());

        for (int i = 0; i < 4; ++i) {
            updateEntry("drive" + (i + 1), drivetrain.getModule(i).getDriveMotor());
            updateEntry("steer" + (i + 1), drivetrain.getModule(i).getSteerMotor());
            updateEntry("encoder" + (i + 1), drivetrain.getModule(i).getEncoder());
        }

        updateEntry("pigeon", drivetrain.getPigeon2());
    }

    private static void registerEntry(String name){
        pitEntries.add(pitTab.add(name + " Connected", false).getEntry());  
        pitEntries.add(pitTab.add(name + " Powered", false).getEntry());
    }

    private static void updateEntry(String name, TalonFX motor){
        pitEntries.get(pitEntries.indexOf(pitTab.add(name + " Connected", false).getEntry())).setBoolean(motor.isConnected());
        pitEntries.get(pitEntries.indexOf(pitTab.add(name + " Powered", false).getEntry())).setBoolean(motor.getSupplyVoltage().getValueAsDouble() > poweredThreshold);
    }

    private static void updateEntry(String name, CANcoder encoder){
        pitEntries.get(pitEntries.indexOf(pitTab.add(name + " Connected", false).getEntry())).setBoolean(encoder.isConnected());
        pitEntries.get(pitEntries.indexOf(pitTab.add(name + " Powered", false).getEntry())).setBoolean(encoder.getSupplyVoltage().getValueAsDouble() > poweredThreshold);
    }

    private static void updateEntry(String name, Pigeon2 pigeon){
        pitEntries.get(pitEntries.indexOf(pitTab.add(name + " Connected", false).getEntry())).setBoolean(pigeon.isConnected());
        pitEntries.get(pitEntries.indexOf(pitTab.add(name + " Powered", false).getEntry())).setBoolean(pigeon.getSupplyVoltage().getValueAsDouble() > poweredThreshold);
    }
}