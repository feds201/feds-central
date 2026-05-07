package frc.robot.utils;

import java.util.ArrayList;
import java.util.HashMap;

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
import frc.robot.subsystems.intake.IntakeSubsystem.RollerState;
import frc.robot.subsystems.feeder.Feeder;
import frc.robot.subsystems.feeder.Feeder.feeder_state;
import frc.robot.subsystems.shooter.ShooterHood;
import frc.robot.subsystems.shooter.ShooterHood.shooterhood_state;
import frc.robot.subsystems.shooter.ShooterWheels;
import frc.robot.subsystems.shooter.ShooterWheels.shooter_state;
import frc.robot.subsystems.spindexer.Spindexer;
import frc.robot.subsystems.spindexer.Spindexer.spindexer_state;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.subsystems.testing.Testing;
import frc.robot.subsystems.testing.Testing.MotorState;
import frc.robot.RobotContainer;
import frc.robot.RobotMap;

//
//
//TODO: update, limelights, storage, encoders/voltage, website.
//
//
public class PitTesting {
    static double poweredThreshold = RobotMap.PitConstants.kPoweredThresholdVolts;


    static RobotContainer container = RobotContainer.getInstance();
    static Orchestra testOrchestra = new Orchestra();

    static CommandSwerveDrivetrain drivetrain = container.getDrivetrain();
    static IntakeSubsystem intake = container.getIntakeSubsystem();
    static Feeder feeder = container.getFeederSubsystem();
    static Spindexer spindexer = container.getSpindexer();
    static ShooterHood shooterHood = container.getShooterHood();
    static ShooterWheels shooterWheels = container.getShooterWheels();
    static Testing testing = new Testing();

    private static String[] moduleNames = {"Front Left", "Front Right", "Back Left", "Back Right"};

    private static SwerveRequest.FieldCentric driveRequest = new SwerveRequest.FieldCentric();
   
    
    private static ShuffleboardTab pitTab = Shuffleboard.getTab("Pit Testing");
    private static HashMap<String, GenericEntry> entryMap = new HashMap<String, GenericEntry>();
    private static ShuffleboardLayout testLayout = Shuffleboard.getTab("Pit Commands")
            .getLayout("Test Commands", BuiltInLayouts.kList)
            .withSize(2, 5);


    private static double testTime = 1.5;
    private static double drivetrainTestTime = 0.75;
    private static double musicTime = 1.0;


    private static Orchestra orchestra = new Orchestra();

    private static GenericEntry tent = pitTab.add("testState", false).getEntry();


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
        testOrchestra.addInstrument(testing.getMotor());

        for (int i = 0; i < 4; ++i) {
            orchestra.addInstrument(drivetrain.getModule(i).getDriveMotor());
            orchestra.addInstrument(drivetrain.getModule(i).getSteerMotor());
            orchestra.addInstrument(drivetrain.getModule(i).getEncoder());
        }

        //TODO: add music
        var status = orchestra.loadMusic("output.chrp");
        if(!status.isOK()) {
            System.out.println("Failed to load music");
        }

        var testStatus = testOrchestra.loadMusic("output.chrp");
        if(!testStatus.isOK()) {
            System.out.println("Failed to load music");
        }

        registerEntry("feeder");
        registerEntry("intake");
        registerEntry("roller");
        registerEntry("hood");
        registerEntry("topRight");
        registerEntry("bottomLeft");
        registerEntry("bottomRight");
        registerEntry("topLeft");
        registerEntry("spindexer");
        registerEntry("testing");
        
        //drivetrain
        for (int i = 0; i < 4; ++i) {
            registerEntry("drive" + (i + 1));
            registerEntry("steer" + (i + 1));
            registerEntry("encoder" + (i + 1));
        }

        registerEntry("pigeon");
        // Commands.parallel(
        //         new InstantCommand(() -> Elastic.sendNotification(new Elastic.Notification(Elastic.NotificationLevel.ERROR, "Robot Enabling", "Clear the area"))),
        //         Commands.sequence( 
        //             new InstantCommand(() -> testOrchestra.play()),
        //             Commands.waitSeconds(musicTime),
        //             new InstantCommand(() -> testOrchestra.stop())
        //         )
        //     ),

        // Add commands
        testLayout.add("Run Testing", Commands.sequence(
            new InstantCommand(() -> Elastic.sendNotification(new Elastic.Notification(Elastic.NotificationLevel.ERROR, "Robot Enabling", "Clear the area"))),
            new InstantCommand(() -> testOrchestra.play()),
            Commands.waitSeconds(musicTime),
            new InstantCommand(() -> testOrchestra.stop()) ,
            testing.setStateCommand(MotorState.ON),
            Commands.waitSeconds(testTime),
            testing.setStateCommand(MotorState.OFF)));

        testLayout.add("Run Feeder", Commands.sequence(
            new InstantCommand(() -> Elastic.sendNotification(new Elastic.Notification(Elastic.NotificationLevel.ERROR, "Robot Enabling", "Clear the area"))),
            new InstantCommand(() -> orchestra.play()),
            Commands.waitSeconds(musicTime),
            new InstantCommand(() -> orchestra.stop()) ,
            feeder.setStateCommand(feeder_state.RUN),
            Commands.waitSeconds(testTime),
            feeder.setStateCommand(feeder_state.STOP)));
        
        testLayout.add("Run Intake", Commands.sequence(
            new InstantCommand(() -> Elastic.sendNotification(new Elastic.Notification(Elastic.NotificationLevel.ERROR, "Robot Enabling", "Clear the area"))),
            new InstantCommand(() -> orchestra.play()),
            Commands.waitSeconds(musicTime),
            new InstantCommand(() -> orchestra.stop()) ,
            intake.setIntakeStateCommand(IntakeState.INTAKING),
            Commands.waitSeconds(testTime),
            intake.setIntakeStateCommand(IntakeState.DEFAULT)));
        
        testLayout.add("Run Intake and Rollers", Commands.sequence(
            new InstantCommand(() -> Elastic.sendNotification(new Elastic.Notification(Elastic.NotificationLevel.ERROR, "Robot Enabling", "Clear the area"))),
            new InstantCommand(() -> orchestra.play()),
            Commands.waitSeconds(musicTime),
            new InstantCommand(() -> orchestra.stop()) ,
            intake.setIntakeStateCommand(IntakeState.INTAKING),
            Commands.waitSeconds(testTime),
            intake.setRollerStateCommand(RollerState.ON),
            Commands.waitSeconds(testTime),
            intake.setRollerStateCommand(RollerState.OFF),
            Commands.waitSeconds(testTime),
            intake.setIntakeStateCommand(IntakeState.DEFAULT)));

        testLayout.add("Run Spindexer", Commands.sequence(
            new InstantCommand(() -> Elastic.sendNotification(new Elastic.Notification(Elastic.NotificationLevel.ERROR, "Robot Enabling", "Clear the area"))),
            new InstantCommand(() -> orchestra.play()),
            Commands.waitSeconds(musicTime),
            new InstantCommand(() -> orchestra.stop()) ,
            spindexer.setStateCommand(spindexer_state.RUN),
            Commands.waitSeconds(testTime),
            spindexer.setStateCommand(spindexer_state.STOP)));

        testLayout.add("Run Shooter Wheels", Commands.sequence(
            new InstantCommand(() -> Elastic.sendNotification(new Elastic.Notification(Elastic.NotificationLevel.ERROR, "Robot Enabling", "Clear the area"))),
            new InstantCommand(() -> orchestra.play()),
            Commands.waitSeconds(musicTime),
            new InstantCommand(() -> orchestra.stop()) ,
            shooterWheels.setStateCommand(shooter_state.SHOOTING),
            Commands.waitSeconds(testTime),
            shooterWheels.setStateCommand(shooter_state.IDLE)));
        
        testLayout.add("Move Shooter Hood", Commands.sequence(
            new InstantCommand(() -> Elastic.sendNotification(new Elastic.Notification(Elastic.NotificationLevel.ERROR, "Robot Enabling", "Clear the area"))),
            new InstantCommand(() -> orchestra.play()),
            Commands.waitSeconds(musicTime),
            new InstantCommand(() -> orchestra.stop()) ,
            shooterHood.setStateCommand(shooterhood_state.OUT),
            Commands.waitSeconds(testTime),
            shooterHood.setStateCommand(shooterhood_state.IN)));
        
        testLayout.add("test Drivetrain translation", Commands.sequence(           
            new InstantCommand(() -> Elastic.sendNotification(new Elastic.Notification(Elastic.NotificationLevel.ERROR, "Robot Enabling", "Clear the area"))),
            new InstantCommand(() -> orchestra.play()),
            Commands.waitSeconds(musicTime),
            new InstantCommand(() -> orchestra.stop()) ,
            drivetrain.runOnce(() -> drivetrain.setControl(driveRequest
                .withVelocityX(0.5))),
            Commands.waitSeconds(drivetrainTestTime),
            drivetrain.runOnce(() -> drivetrain.setControl(new SwerveRequest.Idle()))));

        testLayout.add("test Drivetrain rotation", Commands.sequence(
            new InstantCommand(() -> Elastic.sendNotification(new Elastic.Notification(Elastic.NotificationLevel.ERROR, "Robot Enabling", "Clear the area"))),
            new InstantCommand(() -> orchestra.play()),
            Commands.waitSeconds(musicTime),
            new InstantCommand(() -> orchestra.stop()) ,
            drivetrain.runOnce(() -> drivetrain.setControl(driveRequest
                .withRotationalRate(1.0))),
            Commands.waitSeconds(drivetrainTestTime),
            drivetrain.runOnce(() -> drivetrain.setControl(new SwerveRequest.Idle()))));
    }

    public static void updateDashboard() {

        updateEntry("feeder", feeder.getFeederMotor());
        updateEntry("intake", intake.getIntakeMotor());
        updateEntry("roller", intake.getRollerMotor());
        updateEntry("hood", shooterHood.getShooterHoodMotor());
        updateEntry("topRight", shooterWheels.getShooterLeader());
        updateEntry("bottomLeft", shooterWheels.getShooterFollower1());
        updateEntry("bottomRight", shooterWheels.getShooterFollower2());
        updateEntry("topLeft", shooterWheels.getShooterFollower3());
        updateEntry("spindexer", spindexer.getSpindexerMotor());
        updateEntry("testing", testing.getMotor());

        tent.setBoolean(testing.getState() == MotorState.ON);

        for (int i = 0; i < 4; ++i) {
            updateEntry("drive" + (i + 1), drivetrain.getModule(i).getDriveMotor());
            updateEntry("steer" + (i + 1), drivetrain.getModule(i).getSteerMotor());
            updateEntry("encoder" + (i + 1), drivetrain.getModule(i).getEncoder());
        }

        updateEntry("pigeon", drivetrain.getPigeon2());
    }

    private static void registerEntry(String name){
        entryMap.put(name + " Connected", pitTab.add(name + " Connected", false).getEntry());
        entryMap.put(name + " Powered", pitTab.add(name + " Powered", false).getEntry());
    }

    private static void updateEntry(String name, TalonFX motor){
        if(entryMap.get(name + " Connected") != null){
            entryMap.get(name + " Connected").setBoolean(motor.isConnected());
            entryMap.get(name + " Powered").setBoolean(motor.getSupplyVoltage().getValueAsDouble() > poweredThreshold);
        }
    }

    private static void updateEntry(String name, CANcoder encoder){
        if(entryMap.get(name + " Connected") != null){
            entryMap.get(name + " Connected").setBoolean(encoder.isConnected());
            entryMap.get(name + " Powered").setBoolean(encoder.getSupplyVoltage().getValueAsDouble() > poweredThreshold);
        }
    }

    private static void updateEntry(String name, Pigeon2 pigeon){
        if(entryMap.get(name + " Connected") != null){
            entryMap.get(name + " Connected").setBoolean(pigeon.isConnected());
            entryMap.get(name + " Powered").setBoolean(pigeon.getSupplyVoltage().getValueAsDouble() > poweredThreshold);
        }
    }
}