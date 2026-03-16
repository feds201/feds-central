package frc.robot;

import edu.wpi.first.wpilibj2.command.Commands;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import frc.robot.subsystems.intake.IntakeSubsystem.IntakeState;
import frc.robot.subsystems.intake.IntakeSubsystem.RollerState;
import frc.robot.subsystems.feeder.Feeder.feeder_state;
import frc.robot.subsystems.shooter.ShooterHood.shooterhood_state;
import frc.robot.subsystems.shooter.ShooterWheels.shooter_state;
import frc.robot.subsystems.spindexer.Spindexer.spindexer_state;
import frc.robot.commands.swerve.HubDrive;
import frc.robot.commands.swerve.PassingDrive;
import frc.robot.commands.swerve.TeleopSwerve;
import frc.robot.RobotMap.ShooterConstants;

/**
 * Helper that wires controller buttons to subsystem commands. Dependencies
 * (controllers and subsystems) are obtained from RobotContainer getters so both
 * classes share the same subsystem instances.
 */
public class ControllerBindings {

    public void setupTestBindings(CommandXboxController test) {
        var container = RobotContainer.getInstance();
        if (container == null) {
            return; // nothing to bind before RobotContainer constructed
        }

        var drivetrain = container.getDrivetrain();
        var intakeSubsystem = container.getIntakeSubsystem();
        var feederSubsystem = container.getFeederSubsystem();
        var spinDexer = container.getSpindexer();
        var shooterHood = container.getShooterHood();
        var shooterWheels = container.getShooterWheels();

        drivetrain.setDefaultCommand(new TeleopSwerve(drivetrain, test, 0.2));

        // D-pad up/down: manually jog hood angle slowly
        test.povUp().onTrue(shooterHood.resetHoodAngle());

        test.povDown()
                .whileTrue(shooterHood.setMotorPower(-0.05))
                .onFalse(shooterHood.setMotorPower(0.0));

        // Right trigger: shoot (wheels + hood + feeder + spindexer) while held, stop on release
        test.x()
                .whileTrue(Commands.sequence(
                        shooterWheels.setStateCommand(shooter_state.SHOOTING),
                        shooterHood.setStateCommand(shooterhood_state.SHOOTING),
                        feederSubsystem.setStateCommand(feeder_state.RUN),
                        spinDexer.setStateCommand(spindexer_state.RUN),
                        intakeSubsystem.setIntakeStateCommand(IntakeState.AGITATE)
                ))
                .onFalse(Commands.sequence(
                        feederSubsystem.setStateCommand(feeder_state.STOP),
                        spinDexer.setStateCommand(spindexer_state.STOP),
                        shooterWheels.setStateCommand(shooter_state.IDLE),
                        shooterHood.setStateCommand(shooterhood_state.IN)
                ));

        // test.x().onTrue(shooterHood.setStateCommand(shooterhood_state.TEST).andThen(shooterWheels.setStateCommand(shooter_state.TEST)));
        test.y().onTrue(feederSubsystem.commandRun().andThen(spinDexer.setStateCommand(spindexer_state.RUN))).onFalse(feederSubsystem.commandStop().andThen(spinDexer.setStateCommand(spindexer_state.STOP)));
        test.a().onTrue(Commands.parallel(
                shooterWheels.setStateCommand(shooter_state.IDLE),
                feederSubsystem.setStateCommand(feeder_state.STOP)
        ));

        test.b().onTrue(intakeSubsystem.setIntakeStateCommand(IntakeState.EXTENDED)).onFalse(intakeSubsystem.setIntakeStateCommand(IntakeState.DEFAULT));
    }

    public void setupDriveBindings(CommandXboxController driver) {
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

        // Button to reset field centric direction (backup if vision fails)
        driver.start()
                .onTrue(new InstantCommand(drivetrain::seedFieldCentric));

        // -------- INTAKE CONTROLS ---------
        driver.leftTrigger()
                .onTrue(intakeSubsystem.setIntakeStateCommand(IntakeState.INTAKING))
                .onFalse(intakeSubsystem.setRollerStateCommand(RollerState.OFF));

        driver.leftBumper()
                .onTrue(intakeSubsystem.setIntakeStateCommand(IntakeState.DEFAULT));

        // Default drive command: field-centric swerve with left stick + right stick rotation
        drivetrain.setDefaultCommand(new TeleopSwerve(drivetrain, driver, 1));
        driver.b().onTrue(feederSubsystem.setStateCommand(feeder_state.PREVERSE).andThen(spinDexer.setStateCommand(spindexer_state.PREVERSE)))
        .onFalse(feederSubsystem.setStateCommand(feeder_state.STOP).andThen(spinDexer.setStateCommand(spindexer_state.STOP)));
        driver.b().onTrue(feederSubsystem.setStateCommand(feeder_state.PREVERSE).andThen(spinDexer.setStateCommand(spindexer_state.PREVERSE)))
        .onFalse(feederSubsystem.setStateCommand(feeder_state.STOP).andThen(spinDexer.setStateCommand(spindexer_state.STOP)));
        // M key (Right bumper): reverse intake rollers
        driver.rightBumper()
                .whileTrue(intakeSubsystem.setRollerStateCommand(RollerState.REVERSE))
                .onFalse(intakeSubsystem.setRollerStateCommand(RollerState.OFF));

        driver.y()
                .onTrue(Commands.sequence(
                        feederSubsystem.setStateCommand(feeder_state.RUN),
                        spinDexer.setStateCommand(spindexer_state.RUN),
                        shooterHood.setStateCommand(shooterhood_state.HALFCOURT),
                        shooterWheels.setStateCommand(shooter_state.HALFCOURT)))
                .onFalse(Commands.sequence(
                        feederSubsystem.setStateCommand(feeder_state.STOP),
                        spinDexer.setStateCommand(spindexer_state.STOP),
                        shooterWheels.setStateCommand(shooter_state.IDLE),
                        shooterHood.setStateCommand(shooterhood_state.IN)));

        // Button to shoot from against hub — run shooter/feeder/spindexer + agitate in parallel while held
        driver.x()
                .whileTrue(Commands.sequence(
                  intakeSubsystem.setRollerStateCommand(RollerState.ON),
                        feederSubsystem.setStateCommand(feeder_state.RUN),
                        spinDexer.setStateCommand(spindexer_state.RUN),
                        // Pulse intake extend/retract while held (5 roller rotations per pulse, 0.3s retract dwell)
                        shooterWheels.setStateCommand(shooter_state.TEST),
                        shooterHood.setStateCommand(shooterhood_state.TEST)
                ))
                .onFalse(Commands.sequence(
                        feederSubsystem.setStateCommand(feeder_state.STOP),
                        spinDexer.setStateCommand(spindexer_state.STOP),
                        shooterWheels.setStateCommand(shooter_state.IDLE),
                        shooterHood.setStateCommand(shooterhood_state.IN),
                        intakeSubsystem.setRollerStateCommand(RollerState.OFF)
                ));

        

        // If out of neutral zone, face hub and ready shoot
        driver.povRight().and(() -> !ShooterConstants.neutralZone.contains(drivetrain.getState().Pose.getTranslation())).whileTrue(
                Commands.sequence(
                        shooterHood.setStateCommand(shooterhood_state.SHOOTING),
                        shooterWheels.setStateCommand(shooter_state.SHOOTING)
                ).alongWith(new HubDrive(drivetrain, driver)))
                .onFalse(
                        Commands.sequence(
                                shooterHood.setStateCommand(shooterhood_state.IN),
                                shooterWheels.setStateCommand(shooter_state.IDLE)
                        ));

        // If in neutral zone, face outpost and ready shoot (passing shot)
        driver.povRight().and(() -> ShooterConstants.neutralZone.contains(drivetrain.getState().Pose.getTranslation())).whileTrue(
                Commands.sequence(
                        shooterHood.setStateCommand(shooterhood_state.OUT),
                        shooterWheels.setStateCommand(shooter_state.LAYUP)
                ).alongWith(new PassingDrive(drivetrain, driver)))
                .onFalse(
                        Commands.sequence(
                                shooterHood.setStateCommand(shooterhood_state.IN),
                                shooterWheels.setStateCommand(shooter_state.IDLE)
                        ));

        // Button to fire, if swerve is aimed and shooter is at speed.
        driver.rightTrigger().and(HubDrive::pidAtSetpoint).and(shooterWheels::atSetpoint).whileTrue(
                Commands.sequence(
                        feederSubsystem.setStateCommand(feeder_state.RUN),
                        spinDexer.setStateCommand(spindexer_state.RUN)
                        // intakeSubsystem.setIntakeStateCommand(IntakeState.AGITATE)
                )
        ).onFalse(
                Commands.sequence(
                        feederSubsystem.setStateCommand(feeder_state.STOP),
                        spinDexer.setStateCommand(spindexer_state.STOP)
                )
        );

        driver.rightTrigger().and(PassingDrive::pidAtSetpoint).whileTrue(
                Commands.sequence(
                        feederSubsystem.setStateCommand(feeder_state.RUN),
                        spinDexer.setStateCommand(spindexer_state.RUN)
                        // Pulse the intake while firing (run until release). 5 rotations per pulse.
                        // intakeSubsystem.agitateWhileHeldRotations(15.0)
                )
        ).onFalse(
                Commands.sequence(
                        feederSubsystem.setStateCommand(feeder_state.STOP),
                        spinDexer.setStateCommand(spindexer_state.STOP)
                )
        );
    }

    public void setupOperatorBindings(CommandXboxController operator) {
        // Grab shared subsystem instances from the active RobotContainer
        var container = RobotContainer.getInstance();
        if (container == null) {
            return; // nothing to bind before RobotContainer constructed
        }

        var feederSubsystem = container.getFeederSubsystem();
        var intakeSubsystem = container.getIntakeSubsystem();
        var shooterHood = container.getShooterHood();
        var spindexerSubsystem = container.getSpindexer();
        // Manual way to change the angle of the shooter hood
        operator.leftTrigger()
                .onTrue(shooterHood.setMotorPower(0.1))
                .onFalse(shooterHood.setMotorPower(0.0));
        operator.leftBumper()
                .onTrue(shooterHood.setMotorPower(-0.1))
                .onFalse(shooterHood.setMotorPower(0.0));

        operator.rightTrigger().onTrue(intakeSubsystem.setIntakeStateCommand(IntakeState.EXTENDED));
        operator.rightBumper().onTrue(intakeSubsystem.setIntakeStateCommand(IntakeState.DEFAULT));

        operator.x().onTrue(feederSubsystem.setStateCommand(feeder_state.PREVERSE).alongWith(spindexerSubsystem.setStateCommand(spindexer_state.PREVERSE))).
        onFalse(feederSubsystem.setStateCommand(feeder_state.STOP).alongWith(spindexerSubsystem.setStateCommand(spindexer_state.STOP)));
        
        //Add multiplier to hood angle
        operator.a()
                .onTrue(new InstantCommand(() -> shooterHood.updateHoodAngleMultiplier(.01)));
        operator.b()
                .onTrue(new InstantCommand(() -> shooterHood.updateHoodAngleMultiplier(-.01)));
    }

}
