package frc.robot;

import java.util.ArrayList;

import edu.wpi.first.cscore.UsbCamera;
import edu.wpi.first.cscore.VideoSource.ConnectionStrategy;
import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.smartdashboard.SendableChooser;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.ParallelCommandGroup;
import edu.wpi.first.wpilibj2.command.SequentialCommandGroup;
import edu.wpi.first.wpilibj2.command.WaitCommand;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import edu.wpi.first.wpilibj2.command.button.Trigger;
import frc.lib.math.Conversions;
import frc.robot.Constants.ArmConstants;
import frc.robot.Constants.IntakeConstants;
import frc.robot.commands.arm.WaitUntilFullyRotate;
import frc.robot.commands.auton.exampleAuto;
import frc.robot.commands.drive.LockWheels;
import frc.robot.commands.drive.TeleopSwerve;
import frc.robot.commands.intake.DeployIntake;
import frc.robot.commands.intake.DeployIntakeGroup;
import frc.robot.commands.intake.RetractIntake;
import frc.robot.commands.intake.RetractIntakeGroup;
import frc.robot.commands.intake.RunIntakeWheels;
import frc.robot.commands.intake.StopIntakeWheels;
import frc.robot.commands.orientator.RunOrientator;
import frc.robot.commands.sensor.StrafeAlign;
import frc.robot.commands.telescope.ExtendTelescope;
import frc.robot.commands.telescope.RetractTelescope;
import frc.robot.commands.utilityCommands.TimerDeadline;
import frc.robot.commands.auton.examplePPAuto;
import frc.robot.commands.claw.OpenClaw;
import frc.robot.subsystems.ArmSubsystem;
import frc.robot.subsystems.ClawSubsystem;
import frc.robot.subsystems.IntakeSubsystem;
import frc.robot.subsystems.OrientatorSubsystem;
import frc.robot.subsystems.TelescopeSubsystem;
import frc.robot.subsystems.VisionSubsystem;
import frc.robot.utils.GripPipeline;
import frc.robot.utils.VisionUtils;
import frc.robot.subsystems.SwerveSubsystem;

public class RobotContainer {
    private final SwerveSubsystem s_swerve;
    private final VisionSubsystem s_vision;
    private final ArmSubsystem s_arm;
    private final OrientatorSubsystem s_orientator;
    private final TelescopeSubsystem s_telescope;
    // private final IntakeSubsystem s_intakeRed;
    private final IntakeSubsystem s_intakeBlue;
    private final ClawSubsystem s_claw;

    private final Thread gripThread;

    CommandXboxController m_driveController = new CommandXboxController(Constants.OIConstants.kDriveControllerPort);
    CommandXboxController m_operatorController = new CommandXboxController(
            Constants.OIConstants.kOperatorControllerPort);

    SendableChooser<Command> m_autonChooser = new SendableChooser<>();

    public RobotContainer() {
        gripThread = VisionUtils.makeGripThread(1);
        gripThread.setDaemon(true);
        gripThread.start();

        s_vision = new VisionSubsystem();
        // s_intakeRed = new IntakeSubsystem(IntakeConstants.kIntakeRedRightDeployMotor,
        // IntakeConstants.kIntakeRedRightDeployMotor, true);
        s_intakeBlue = new IntakeSubsystem(IntakeConstants.kIntakeBlueLeftDeployMotor,
                IntakeConstants.kIntakeBlueLeftWheelMotor, false);
        s_telescope = new TelescopeSubsystem();
        s_orientator = new OrientatorSubsystem();
        s_swerve = new SwerveSubsystem(s_vision);
        s_arm = new ArmSubsystem();
        s_claw = new ClawSubsystem();

        m_autonChooser.setDefaultOption("Example PP Swerve", new examplePPAuto(s_swerve));
        m_autonChooser.addOption("Example Swerve", new exampleAuto(s_swerve));

        Shuffleboard.getTab("Autons").add(m_autonChooser);

        s_swerve.setDefaultCommand(
                new TeleopSwerve(
                        s_swerve,
                        () -> -m_driveController.getLeftY(),
                        () -> -m_driveController.getLeftX(),
                        () -> -m_driveController.getRightX(),
                        () -> m_driveController.leftTrigger().getAsBoolean()));

        configureButtonBindings();

    }

    private void configureButtonBindings() {
        // driver
        // right bumper: claw open close
        // r-trigger: intake open
        m_driveController.y().onTrue(new InstantCommand(() -> s_swerve.zeroGyro()));

        m_driveController.start().onTrue(new LockWheels(s_swerve));

        m_driveController.leftTrigger().onTrue(new DeployIntakeGroup(s_intakeBlue, s_orientator));
        m_driveController.leftBumper().onTrue(new RetractIntakeGroup(s_intakeBlue, s_orientator));

        // operator
        // r-bumper: claw open close
        // r-stick: precise rotation of arm
        // l-stick press: activate DANGER MODE
        // l-stick: nothing normally. DANGER MODE: control telescoping arm
        // d-pad: control presents for the telescoping arm
        // l-bumper: reverse intake

        // m_operatorController.povLeft().onTrue(new StrafeAlign(s_swerve, true));

        // m_operatorController.povRight().onTrue(new StrafeAlign(s_swerve, false));

        m_operatorController.povUp()
                .onTrue(new ParallelCommandGroup(
                        s_arm.setPosition(ArmConstants.kArmPutHigh),
                        new SequentialCommandGroup(
                                // new WaitUntilFullyRotate(s_arm),
                                new WaitCommand(1),
                                new ExtendTelescope(s_telescope))));

        m_operatorController.povRight()
                .onTrue(new ParallelCommandGroup(
                        s_arm.setPosition(ArmConstants.kArmPutMiddle),
                        new SequentialCommandGroup(
                                new WaitUntilFullyRotate(s_arm),
                                new ExtendTelescope(s_telescope))));

        m_operatorController.povDown()
                .onTrue(new ParallelCommandGroup(s_arm.setPosition(ArmConstants.kArmPutLow),
                        new SequentialCommandGroup(
                                new WaitUntilFullyRotate(s_arm),
                                new ExtendTelescope(s_telescope))));

        m_operatorController.povLeft()
                .onTrue(new SequentialCommandGroup(
                        new RetractTelescope(s_telescope),
                        s_arm.setPosition(ArmConstants.kArmHome)));

        // m_operatorController.rightBumper().onTrue(new ClawCone(s_claw)); //Create new
        // Commands

        // m_operatorController.leftBumper().onTrue(new ClawCube(s_claw)); //Create new
        // Commands

        // m_operatorController.b().onTrue(new OpenClaw(s_claw));

    }

    public Command getAutonomousCommand() {
        return m_autonChooser.getSelected();
    }

}
