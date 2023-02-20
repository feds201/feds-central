package frc.robot;

import java.util.function.DoubleSupplier;

import com.ctre.phoenix.sensors.Pigeon2;

import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.smartdashboard.SendableChooser;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.ParallelCommandGroup;
import edu.wpi.first.wpilibj2.command.SequentialCommandGroup;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import frc.robot.commands.arm.RotateArmRange;
import frc.robot.commands.arm.RotateArmToEncoderPosition;
import frc.robot.commands.auton.BasicAuton;
import frc.robot.commands.auton.BasicDeadlineAuton;
import frc.robot.commands.claw.CloseClaw;
import frc.robot.commands.claw.HoldBall;
import frc.robot.commands.claw.HoldCone;
import frc.robot.commands.claw.OpenClaw;
import frc.robot.commands.drive.FieldRelativeDriveControlCommand;
import frc.robot.subsystems.ArmSubsystem;
import frc.robot.subsystems.ClawSubsystem;
import frc.robot.subsystems.DriveSubsystem;
import frc.robot.subsystems.IntakeSubsystem;

public class RobotContainer {
        private final Pigeon2 m_pigeon = new Pigeon2(Constants.SensorConstants.kPigeon); // TODO: something about this irks me...

        private final DriveSubsystem m_robotDrive = new DriveSubsystem(m_pigeon);
        private final ClawSubsystem m_claw = new ClawSubsystem();
        private final IntakeSubsystem m_intake = new IntakeSubsystem();
        private final ArmSubsystem m_arm = new ArmSubsystem();

        CommandXboxController m_driveController = new CommandXboxController(Constants.OIConstants.kDriveControllerPort);
        CommandXboxController m_operatorController = new CommandXboxController(
                        Constants.OIConstants.kOperatorControllerPort);

        private final Command m_basicAuton = new BasicAuton(m_robotDrive);
        private final Command m_deadlineAuton = new BasicDeadlineAuton(m_robotDrive);

        SendableChooser<Command> m_autonChooser = new SendableChooser<>();

        public RobotContainer() {
                
                m_robotDrive.setDefaultCommand(
                                new FieldRelativeDriveControlCommand(m_robotDrive, () -> -m_driveController.getLeftY(),
                                                () -> -m_driveController.getLeftX(),
                                                () -> m_driveController.getRightX(),
                                                () -> m_robotDrive.getPoseAngle()));

               

                m_arm.setDefaultCommand(new RotateArmRange(m_arm, () -> -m_operatorController.getLeftY(), () -> m_arm.getDangerMode(), -5000, 5000)); // TODO: make constants

                m_autonChooser.setDefaultOption("basicAuton", m_basicAuton);
                m_autonChooser.addOption("basicDeadlineAuton", m_deadlineAuton);

                Shuffleboard.getTab("Autonomous Command").add(m_autonChooser);

                configureButtonBindings();

        }

        private void configureButtonBindings() {
                // driver

                // right bumper: claw open close

                // l-trigger: left intake open
                m_driveController.leftTrigger()
                                .onTrue(new SequentialCommandGroup(
                                                new InstantCommand(() -> m_intake.rotateIntakeForwards()),
                                                new InstantCommand(() -> m_intake.runIntakeWheelsIn())));

                m_driveController.leftBumper()
                                .onTrue(new SequentialCommandGroup(
                                                new InstantCommand(() -> m_intake.rotateIntakeBackwards()),
                                                new InstantCommand(() -> m_intake.runIntakeWheelsOut())));

                m_driveController.rightBumper()
                                .onTrue(new ParallelCommandGroup(
                                                new InstantCommand(() -> m_intake.stopIntakeRotation()),
                                                new InstantCommand(() -> m_intake.stopIntakeWheels())));
                m_driveController.povUp()
                                .onTrue(new RotateArmToEncoderPosition(m_arm, 15000));
                m_driveController.povLeft()
                                .onTrue(new RotateArmToEncoderPosition(m_arm, 0));

                m_driveController.povRight()
                                .onTrue(new RotateArmToEncoderPosition(m_arm, 0));
                m_driveController.povDown()
                                .onTrue(new RotateArmToEncoderPosition(m_arm, -4000));
                // r-trigger: right intake open TODO: ask if this should be based on field
                // orientation?

                // operator
                // r-bumper: claw open close
                m_operatorController.b().onTrue(new OpenClaw(m_claw));
                m_operatorController.a().onTrue(new CloseClaw(m_claw));
                m_operatorController.x().onTrue(new OpenClaw(m_claw));
                m_operatorController.y().onTrue(new OpenClaw(m_claw));
                
                // r-stick: precise rotation of arm

                // l-stick press: activate DANGER MODE

                m_operatorController.leftStick().onTrue(new InstantCommand(() -> m_arm.toggleDangerMode()));
                // l-stick: nothing normally. DANGER MODE: control telescoping arm


                // d-pad: control presents for the telescoping arm
                // l-bumper: reverse intake

        }

        public Command getAutonomousCommand() {
                return m_autonChooser.getSelected();
        }
}
