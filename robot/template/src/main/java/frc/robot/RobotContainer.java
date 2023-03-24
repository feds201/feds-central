package frc.robot;

import java.util.ArrayList;

import edu.wpi.first.cameraserver.CameraServer;
import edu.wpi.first.cscore.UsbCamera;
import edu.wpi.first.cscore.VideoSource.ConnectionStrategy;
import edu.wpi.first.math.filter.SlewRateLimiter;
import edu.wpi.first.math.util.Units;
import edu.wpi.first.wpilibj.PowerDistribution;
import edu.wpi.first.wpilibj.PowerDistribution.ModuleType;
import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.smartdashboard.SendableChooser;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.ParallelCommandGroup;
import edu.wpi.first.wpilibj2.command.SequentialCommandGroup;
import edu.wpi.first.wpilibj2.command.WaitCommand;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import edu.wpi.first.wpilibj2.command.button.Trigger;
import frc.lib.math.Conversions;
import frc.robot.constants.ArmConstants;
import frc.robot.constants.ClawConstants;
import frc.robot.constants.IntakeConstants;
import frc.robot.constants.PowerConstants;
import frc.robot.constants.SwerveConstants;
import frc.robot.constants.OIConstants;
import frc.robot.commands.drive.LockWheels;
import frc.robot.commands.drive.TeleopSwerve;
import frc.robot.commands.intake.DeployIntake;
import frc.robot.commands.intake.RetractIntake;
import frc.robot.commands.intake.RunIntakeWheels;
import frc.robot.commands.intake.RunIntakeWheelsInfinite;
import frc.robot.commands.intake.ReverseIntakeWheels;
import frc.robot.commands.intake.RotateIntakeToPosition;
import frc.robot.commands.sensor.StrafeAlign;
import frc.robot.commands.utilityCommands.TimerDeadline;
import frc.robot.commands.arm.RotateArmManual;
import frc.robot.commands.arm.RotateArmPosition;
import frc.robot.commands.arm2.RotateArm2Manual;
import frc.robot.commands.arm2.RotateArm2Position;
import frc.robot.commands.auton.examplePPAuto;
import frc.robot.commands.claw.IntakeCone;
import frc.robot.commands.claw.OuttakeCone;
import frc.robot.commands.claw.StopClaw;
// import frc.robot.subsystems.ArmSubsystem;
import frc.robot.subsystems.ArmSubsystem4;
import frc.robot.subsystems.ArmSubsystem5;
import frc.robot.subsystems.ClawSubsystem;
import frc.robot.subsystems.IntakeSubsystem;
import frc.robot.utils.GripPipeline;
import frc.robot.utils.VisionUtils;
import frc.robot.subsystems.SwerveSubsystem;
import frc.robot.subsystems.WheelSubsystem;
import frc.robot.subsystems.LimelightSubsystem;

public class RobotContainer {
    private final SwerveSubsystem s_swerve;
    private final ArmSubsystem4 s_arm;
    private final ArmSubsystem5 s_arm2;
    private final LimelightSubsystem s_limelight;
    private final IntakeSubsystem s_intake;
    private final ClawSubsystem s_claw;
    private final WheelSubsystem s_wheels;

    private final SlewRateLimiter slewRateLimiterX = new SlewRateLimiter(15);
    private final SlewRateLimiter slewRateLimiterY = new SlewRateLimiter(15);
    public final static PowerDistribution m_PowerDistribution = new PowerDistribution(PowerConstants.kPCMChannel,
            ModuleType.kRev);

    private double controllerMultiplier = 1;

    CommandXboxController m_driveController = new CommandXboxController(OIConstants.kDriveControllerPort);
    CommandXboxController m_operatorController = new CommandXboxController(OIConstants.kOperatorControllerPort);

    SendableChooser<Command> m_autonChooser = new SendableChooser<>();

    private boolean use_wpi_pid_arm = true;

    public RobotContainer() {
        CameraServer.startAutomaticCapture();
        s_limelight = new LimelightSubsystem();
        s_swerve = new SwerveSubsystem();
        s_intake = new IntakeSubsystem();
        s_claw = new ClawSubsystem();
        s_wheels = new WheelSubsystem();

        Shuffleboard.getTab("Autons").add(m_autonChooser);

        s_swerve.setDefaultCommand(
                new TeleopSwerve(
                        s_swerve,
                        () -> -slewRateLimiterY.calculate(m_driveController.getLeftY() * getPercentDriveSpeed()), // FIXME:
                                                                                                                  // DOES
                                                                                                                  // THIS
                                                                                                                  // CRAP
                                                                                                                  // WORK?
                        () -> -slewRateLimiterX.calculate(m_driveController.getLeftX() * getPercentDriveSpeed()),
                        () -> -m_driveController.getRightX(),
                        () -> m_driveController.rightTrigger().getAsBoolean()));

        if (use_wpi_pid_arm) {
            s_arm = new ArmSubsystem4();
            s_arm.setDefaultCommand(new RotateArmManual(s_arm, () -> -m_operatorController.getLeftY())); // damn inverted
                                                                                                         // controls
            
                                                                                                         s_arm2 = null;
        } else {
            s_arm2 = new ArmSubsystem5();
            s_arm2.setDefaultCommand(new RotateArm2Manual(s_arm2, () -> -m_operatorController.getLeftY())); // damn inverted
            
            s_arm = null;
        }                          
        configureDriverButtonBindings();
        configureOperatorButtonBindings();
        // configureTriggerBindings();
    }

    private void configureDriverButtonBindings() {
        // driver
        // right bumper: claw open close
        // r-trigger: intake open
        m_driveController.y().onTrue(
                new InstantCommand(() -> s_swerve.zeroGyro()));

        m_driveController.start().onTrue(new LockWheels(s_swerve));

        m_driveController.povUp().whileTrue(
                new TeleopSwerve(s_swerve, () -> SwerveConstants.kPreciseSwerveSpeed, () -> 0, () -> 0, () -> true));
        m_driveController.povDown().whileTrue(
                new TeleopSwerve(s_swerve, () -> -SwerveConstants.kPreciseSwerveSpeed, () -> 0, () -> 0, () -> true));
        m_driveController.povLeft().whileTrue(
                new TeleopSwerve(s_swerve, () -> 0, () -> SwerveConstants.kPreciseSwerveSpeed, () -> 0, () -> true));
        m_driveController.povRight().whileTrue(
                new TeleopSwerve(s_swerve, () -> 0, () -> -SwerveConstants.kPreciseSwerveSpeed, () -> 0, () -> true));

        m_driveController.x().onTrue(new InstantCommand(() -> togglePercentDriveSpeed()));

        m_driveController.a().onTrue(new StrafeAlign(s_swerve));

    }

    private void configureOperatorButtonBindings() {
        // operator
        // r-bumper: claw open close
        // r-stick: precise rotation of arm
        // l-stick press: activate DANGER MODE
        // l-stick: nothing normally. DANGER MODE: control telescoping arm
        // d-pad: control presents for the telescoping arm
        // l-bumper: reverse intake

        // arm

        if (use_wpi_pid_arm) {
            m_operatorController.povUp().onTrue(new RotateArmPosition(s_arm, ArmConstants.kArmPutHigh)
                    .until(() -> m_operatorController.getLeftY() > OIConstants.kArmDeadzone));
            m_operatorController.povRight().onTrue(new RotateArmPosition(s_arm, ArmConstants.kArmPutHumanPlayer)
                    .until(() -> m_operatorController.getLeftY() > OIConstants.kArmDeadzone));
            m_operatorController.povLeft().onTrue(new RotateArmPosition(s_arm, ArmConstants.kArmHome)
                    .until(() -> m_operatorController.getLeftY() > OIConstants.kArmDeadzone));
            m_operatorController.povDown().onTrue(new RotateArmPosition(s_arm, ArmConstants.kArmPutMiddle)
                    .until(() -> m_operatorController.getLeftY() > OIConstants.kArmDeadzone));
        } else {
            m_operatorController.povUp().onTrue(new RotateArm2Position(s_arm2, ArmConstants.kArmPutHigh)
                    .until(() -> m_operatorController.getLeftY() > OIConstants.kArmDeadzone));
            m_operatorController.povRight().onTrue(new RotateArm2Position(s_arm2, ArmConstants.kArmPutHumanPlayer)
                    .until(() -> m_operatorController.getLeftY() > OIConstants.kArmDeadzone));
            m_operatorController.povLeft().onTrue(new RotateArm2Position(s_arm2, ArmConstants.kArmHome)
                    .until(() -> m_operatorController.getLeftY() > OIConstants.kArmDeadzone));
            m_operatorController.povDown().onTrue(new RotateArm2Position(s_arm2, ArmConstants.kArmPutMiddle)
                    .until(() -> m_operatorController.getLeftY() > OIConstants.kArmDeadzone));
        }

        // claw
        m_operatorController.a().whileTrue(new IntakeCone(s_claw));
        m_operatorController.b().whileTrue(new OuttakeCone(s_claw));

        // intake
        m_driveController.rightTrigger()
                .onTrue(new ParallelCommandGroup(
                        new RotateIntakeToPosition(s_intake, IntakeConstants.kIntakeForwardSetpoint),
                        new SequentialCommandGroup(new TimerDeadline(0.5)), new RunIntakeWheelsInfinite(s_wheels)));
        m_driveController.rightBumper()
                .onTrue(new RotateIntakeToPosition(s_intake, IntakeConstants.kIntakeRetractSetpoint));
        m_driveController.leftTrigger()
                .onTrue(new ReverseIntakeWheels(s_wheels, IntakeConstants.kIntakeWheelEjectTime));
        m_driveController.leftBumper()
                .onTrue(new ParallelCommandGroup(
                        new RotateIntakeToPosition(s_intake, IntakeConstants.kIntakeMiddleScorePosition),
                        new SequentialCommandGroup(new TimerDeadline(.5), new RunIntakeWheels(s_wheels, 0.1),
                                new ReverseIntakeWheels(s_wheels, 0.3))));
    }

    // private void configureTriggerBindings() {
    // new Trigger(s_swerve::gyroNotZero)
    // .onTrue(new InstantCommand(() -> SmartDashboard.putBoolean("GyroZero",
    // false)))
    // .onFalse(new InstantCommand(() -> SmartDashboard.putBoolean("GyroNotZero",
    // true)));
    // }

    public Command getAutonomousCommand() {
        return m_autonChooser.getSelected();
    }

    private void togglePercentDriveSpeed() {
        if (controllerMultiplier == SwerveConstants.kPreciseSwerveSpeed) {
            controllerMultiplier = 1;
        } else {
            controllerMultiplier = SwerveConstants.kPreciseSwerveSpeed;
        }
    }

    public double getPercentDriveSpeed() {
        return controllerMultiplier;
    }

}
