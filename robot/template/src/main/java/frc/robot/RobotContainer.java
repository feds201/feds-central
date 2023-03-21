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
import frc.robot.constants.IntakeConstants;
import frc.robot.constants.PowerConstants;
import frc.robot.constants.SwerveConstants;
import frc.robot.constants.OIConstants;
import frc.robot.commands.drive.LockWheels;
import frc.robot.commands.drive.TeleopSwerve;
import frc.robot.commands.intake.DeployIntake;
import frc.robot.commands.intake.RetractIntake;
import frc.robot.commands.intake.RunIntakeWheels;
import frc.robot.commands.intake.ReverseIntakeWheels;
import frc.robot.commands.sensor.StrafeAlign;
import frc.robot.commands.utilityCommands.TimerDeadline;
import frc.robot.commands.arm.RotateArmManual;
import frc.robot.commands.arm.RotateArmPosition;
import frc.robot.commands.auton.examplePPAuto;

// import frc.robot.subsystems.ArmSubsystem;
import frc.robot.subsystems.ArmSubsystem4;
import frc.robot.subsystems.ClawSubsystem;
import frc.robot.subsystems.IntakeSubsystem;
import frc.robot.utils.GripPipeline;
import frc.robot.utils.VisionUtils;
import frc.robot.subsystems.SwerveSubsystem;
import frc.robot.subsystems.LimelightSubsystem;

public class RobotContainer {
    private final SwerveSubsystem s_swerve;
    private final ArmSubsystem4 s_arm;
    private final LimelightSubsystem s_limelight;
    private final IntakeSubsystem s_intake;

    private final SlewRateLimiter slewRateLimiterX = new SlewRateLimiter(15);
    private final SlewRateLimiter slewRateLimiterY = new SlewRateLimiter(15);
    public final static PowerDistribution m_PowerDistribution = new PowerDistribution(PowerConstants.kPCMChannel,
            ModuleType.kRev);

    private double controllerMultiplier = 1;

    CommandXboxController m_driveController = new CommandXboxController(OIConstants.kDriveControllerPort);
    CommandXboxController m_operatorController = new CommandXboxController(OIConstants.kOperatorControllerPort);

    SendableChooser<Command> m_autonChooser = new SendableChooser<>();

    public RobotContainer() {
        CameraServer.startAutomaticCapture();
        s_limelight = new LimelightSubsystem();
        s_swerve = new SwerveSubsystem();
        s_arm = new ArmSubsystem4();
        s_intake = new IntakeSubsystem();


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

        s_arm.setDefaultCommand(new RotateArmManual(s_arm, () ->
        m_operatorController.getLeftY()));


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
        m_driveController.povRight().whileTrue(new TeleopSwerve(s_swerve, () -> 0, () -> -SwerveConstants.kPreciseSwerveSpeed, () -> 0, () -> true));

        m_driveController.x().onTrue(new InstantCommand(() -> togglePercentDriveSpeed()));


    }
    
    private void configureOperatorButtonBindings() {
        // operator
        // r-bumper: claw open close
        // r-stick: precise rotation of arm
        // l-stick press: activate DANGER MODE
        // l-stick: nothing normally. DANGER MODE: control telescoping arm
        // d-pad: control presents for the telescoping arm
        // l-bumper: reverse intake


        m_operatorController.a().onTrue(new RotateArmPosition(s_arm, Units.degreesToRadians(Conversions.degreesToFalcon(90, ArmConstants.kArmGearRatio))));
    }

    // private void configureTriggerBindings() {
    //     new Trigger(s_swerve::gyroNotZero)
    //             .onTrue(new InstantCommand(() -> SmartDashboard.putBoolean("GyroZero", false)))
    //             .onFalse(new InstantCommand(() -> SmartDashboard.putBoolean("GyroNotZero", true)));
    // }


    public Command getAutonomousCommand() {
        return m_autonChooser.getSelected();
    }

    private void togglePercentDriveSpeed() {
        if(controllerMultiplier == SwerveConstants.kPreciseSwerveSpeed) {
            controllerMultiplier = 1;
        } else {
            controllerMultiplier = SwerveConstants.kPreciseSwerveSpeed;
        }
    }

    public double getPercentDriveSpeed() { return controllerMultiplier; }

}
