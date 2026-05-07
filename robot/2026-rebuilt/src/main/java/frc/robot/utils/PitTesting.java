package frc.robot.utils;

import com.ctre.phoenix6.swerve.SwerveRequest;

import edu.wpi.first.wpilibj.shuffleboard.BuiltInLayouts;
import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardLayout;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardTab;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.Commands;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import frc.robot.subsystems.intake.IntakeSubsystem.IntakeState;
import frc.robot.subsystems.intake.IntakeSubsystem.RollerState;
import frc.robot.subsystems.feeder.Feeder.feeder_state;
import frc.robot.subsystems.shooter.ShooterHood.shooterhood_state;
import frc.robot.subsystems.shooter.ShooterWheels.shooter_state;
import frc.robot.subsystems.spindexer.Spindexer.spindexer_state;
import frc.robot.RobotContainer;


public class PitTesting {
    private static ShuffleboardLayout testLayout = Shuffleboard.getTab("Pit Commands")
            .getLayout("Test Commands", BuiltInLayouts.kList)
            .withSize(2, 5);
    private static SwerveRequest.FieldCentric driveRequest = new SwerveRequest.FieldCentric();
    
    private static double testTime = 1.5;
    private static double drivetrainTestTime = 0.75;

    public static void addCommands() {

        var container = RobotContainer.getInstance();
        if (container == null) {
            return;
        }

        var drivetrain = container.getDrivetrain();
        var intakeSubsystem = container.getIntakeSubsystem();
        var feederSubsystem = container.getFeederSubsystem();
        var spinDexer = container.getSpindexer();
        var shooterHood = container.getShooterHood();
        var shooterWheels = container.getShooterWheels();

        testLayout.add("Run Feeder", Commands.sequence(
            feederSubsystem.setStateCommand(feeder_state.RUN),
            Commands.waitSeconds(testTime),
            feederSubsystem.setStateCommand(feeder_state.STOP)));
        
        testLayout.add("Run Intake", Commands.sequence(
            intakeSubsystem.setIntakeStateCommand(IntakeState.INTAKING),
            Commands.waitSeconds(testTime),
            intakeSubsystem.setIntakeStateCommand(IntakeState.DEFAULT)));
        
        testLayout.add("Run Intake and Rollers", Commands.sequence(
            intakeSubsystem.setIntakeStateCommand(IntakeState.INTAKING),
            Commands.waitSeconds(testTime),
            intakeSubsystem.setRollerStateCommand(RollerState.ON),
            Commands.waitSeconds(testTime),
            intakeSubsystem.setRollerStateCommand(RollerState.OFF),
            Commands.waitSeconds(testTime),
            intakeSubsystem.setIntakeStateCommand(IntakeState.DEFAULT)));

        testLayout.add("Run Spindexer", Commands.sequence(
            spinDexer.setStateCommand(spindexer_state.RUN),
            Commands.waitSeconds(testTime),
            spinDexer.setStateCommand(spindexer_state.STOP)));

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
}
