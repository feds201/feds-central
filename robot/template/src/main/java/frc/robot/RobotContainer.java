package frc.robot;

import edu.wpi.first.wpilibj.smartdashboard.SendableChooser;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import frc.robot.Constants.ArmConstants;
import frc.robot.commands.drive.TeleopSwerve;
import frc.robot.commands.arm.JointsSetPosition;
import frc.robot.commands.claw.CloseClaw;
import frc.robot.commands.claw.OpenClaw;
import frc.robot.subsystems.ArmSubsystem;
import frc.robot.subsystems.ClawSubsystem;
import frc.robot.subsystems.IntakeSubsystem;
import frc.robot.subsystems.Swerve;

public class RobotContainer {
        private final Swerve s_Swerve = new Swerve();
        private final ClawSubsystem m_claw = new ClawSubsystem();
        private final IntakeSubsystem m_intake = new IntakeSubsystem();
        private final ArmSubsystem m_arm = new ArmSubsystem();

        CommandXboxController m_driveController = new CommandXboxController(Constants.OIConstants.kDriveControllerPort);
        CommandXboxController m_operatorController = new CommandXboxController(
                        Constants.OIConstants.kOperatorControllerPort);

        SendableChooser<Command> m_autonChooser = new SendableChooser<>();

        public RobotContainer() {

                m_robotDrive.setDefaultCommand(
                                new FieldRelativeDriveControlCommand(m_robotDrive, () -> -m_driveController.getLeftY(),
                                                () -> -m_driveController.getLeftX(),
                                                () -> m_driveController.getRightX(),
                                                () -> m_robotDrive.getPoseAngle()));

                //m_arm.setDefaultCommand(new RotateArmRange(m_arm, () -> -m_operatorController.getLeftY(),
                //                () -> m_arm.getDangerMode(), ArmConstants.kArmRotateMin, ArmConstants.kArmRotateMax)); // TODO:
                                                                                                                       // make
                                                                                                                       // constants

                configureButtonBindings();

        }

        private void configureButtonBindings() {
                // driver

                // right bumper: claw open close

                // l-trigger: left intake open
                // m_driveController.leftTrigger()
                //                 .onTrue(new SequentialCommandGroup(
                //                                 new InstantCommand(() -> m_intake.rotateIntakeForwards()),
                //                                 new InstantCommand(() -> m_intake.runIntakeWheelsIn())));

                // m_driveController.leftBumper()
                //                 .onTrue(new SequentialCommandGroup(
                //                                 new InstantCommand(() -> m_intake.rotateIntakeBackwards()),
                //                                 new InstantCommand(() -> m_intake.runIntakeWheelsOut())));

                // m_driveController.rightBumper()
                //                 .onTrue(new ParallelCommandGroup(
                //                                 new InstantCommand(() -> m_intake.stopIntakeRotation()),
                //                                 new InstantCommand(() -> m_intake.stopIntakeWheels())));
                // m_driveController.povUp()
                //                 .onTrue(new RotateArmToEncoderPosition(m_arm, 15000));
                // m_driveController.povLeft()
                //                 .onTrue(new RotateArmToEncoderPosition(m_arm, 0));

                // m_driveController.povRight()
                //                 .onTrue(new RotateArmToEncoderPosition(m_arm, 0));
                // m_driveController.povDown()
                //                 .onTrue(new RotateArmToEncoderPosition(m_arm, -4000));

                m_driveController.y().onTrue(new InstantCommand(() -> s_Swerve.zeroGyro()));
                // r-trigger: right intake open TODO: ask if this should be based on field
                // orientation?

                // operator
                // r-bumper: claw open close
                

                // r-stick: precise rotation of arm

                // l-stick press: activate DANGER MODE

                //m_operatorController.leftStick().onTrue(new InstantCommand(() -> m_arm.toggleDangerMode()));
                // l-stick: nothing normally. DANGER MODE: control telescoping arm

                // d-pad: control presents for the telescoping arm
                // l-bumper: reverse intake

                
                // m_driveController.b().onTrue(m_arm.setPosition(ArmConstants.kArmHome));
                
                m_operatorController.a().onTrue(m_arm.setPosition(ArmConstants.kArmAcquireFromFloor));

                m_operatorController.b().onTrue(m_arm.setPosition(ArmConstants.kArmAcquireFromSIS));

                m_operatorController.x().onTrue(m_arm.setPosition(ArmConstants.kArmHome));

                m_operatorController.y().onTrue(m_arm.resetSensor());


                m_operatorController.povDown().whileTrue(m_arm.slowlyGoDown());



        }

        public Command getAutonomousCommand() {
                return m_autonChooser.getSelected();
        }


}
