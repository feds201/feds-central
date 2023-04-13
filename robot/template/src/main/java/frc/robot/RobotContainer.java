package frc.robot;

import java.util.ArrayList;

import edu.wpi.first.cameraserver.CameraServer;
import edu.wpi.first.cscore.UsbCamera;
import edu.wpi.first.cscore.VideoSource.ConnectionStrategy;
import edu.wpi.first.math.filter.SlewRateLimiter;
import edu.wpi.first.math.util.Units;
import edu.wpi.first.wpilibj.PowerDistribution;
import edu.wpi.first.wpilibj.XboxController;
import edu.wpi.first.wpilibj.GenericHID.RumbleType;
import edu.wpi.first.wpilibj.PowerDistribution.ModuleType;
import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.smartdashboard.SendableChooser;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.ParallelCommandGroup;
import edu.wpi.first.wpilibj2.command.ParallelDeadlineGroup;
import edu.wpi.first.wpilibj2.command.ParallelRaceGroup;
import edu.wpi.first.wpilibj2.command.RunCommand;
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
import frc.robot.constants.VisionConstants;
import frc.robot.constants.OIConstants;
import frc.robot.commands.drive.BalanceWhileOn;
import frc.robot.commands.drive.LockWheels;
import frc.robot.commands.drive.TeleopSwerve;
import frc.robot.commands.intake.RunIntakeWheels;
import frc.robot.commands.intake.RunIntakeWheelsInfinite;
import frc.robot.commands.intake.ReverseIntakeWheels;
import frc.robot.commands.intake.RotateIntakeToPosition;
import frc.robot.commands.sensor.DepthAlign;
import frc.robot.commands.sensor.ReportingCommand;
import frc.robot.commands.sensor.StrafeAlign;
import frc.robot.commands.sensor.TeleopVision;
import frc.robot.commands.utilityCommands.ToggleRumble;
import frc.robot.commands.arm2.RotateArm2Manual;
import frc.robot.commands.arm2.RotateArm2Position; 
import frc.robot.commands.auton.LeftFieldAuton;
import frc.robot.commands.auton.PlaceHighCone;
import frc.robot.commands.auton.cubeOnly;
import frc.robot.commands.auton.CenterFieldAuton;
import frc.robot.commands.auton.CubeBalance;
import frc.robot.commands.auton.CubeBalanceMobility;
import frc.robot.commands.claw.IntakeCone;
import frc.robot.commands.claw.OuttakeCone;
import frc.robot.commands.claw.StopClaw;
// import frc.robot.subsystems.ArmSubsystem;
import frc.robot.subsystems.ArmSubsystem5;
import frc.robot.subsystems.ClawSubsystem;
import frc.robot.subsystems.IntakeSubsystem;
import frc.robot.utils.GripPipeline;
import frc.robot.utils.VisionUtils;
import frc.robot.subsystems.SwerveSubsystem;
import frc.robot.subsystems.WheelSubsystem;
import frc.robot.subsystems.pigeon.Pigeon2Subsystem;
import frc.robot.subsystems.pigeon.ReportingSubsystem;
import frc.robot.subsystems.LimelightSubsystem;

public class RobotContainer {
    private final SwerveSubsystem s_swerve;
    private final ArmSubsystem5 s_arm2;
    private final LimelightSubsystem s_limelight;
    private final IntakeSubsystem s_intake;
    private final ClawSubsystem s_claw;
    private final WheelSubsystem s_wheels;

    public static final Pigeon2Subsystem s_pigeon2 = new Pigeon2Subsystem(SwerveConstants.pigeonID);
    private final ReportingSubsystem s_reportingSubsystem;

    private final SlewRateLimiter slewRateLimiterX = new SlewRateLimiter(15);
    private final SlewRateLimiter slewRateLimiterY = new SlewRateLimiter(15);
    public final static PowerDistribution m_PowerDistribution = new PowerDistribution(PowerConstants.kPCMChannel,
            ModuleType.kRev);

    public static double controllerMultiplier = 1;

    public static boolean robotCentric = false;

    CommandXboxController m_driveController = new CommandXboxController(OIConstants.kDriveControllerPort);
    CommandXboxController m_operatorController = new CommandXboxController(OIConstants.kOperatorControllerPort);

    SendableChooser<Command> m_autonChooser = new SendableChooser<>();

    public RobotContainer() {
        CameraServer.startAutomaticCapture();
        s_limelight = new LimelightSubsystem();
        s_swerve = new SwerveSubsystem();
        s_intake = new IntakeSubsystem();
        s_claw = new ClawSubsystem();
        s_wheels = new WheelSubsystem();
        s_arm2 = new ArmSubsystem5();
        s_reportingSubsystem = new ReportingSubsystem();

        //m_autonChooser.addOption("Center Field Auton", new CenterFieldAuton(s_swerve, s_limelight, s_arm2, s_claw, s_intake, s_wheels));
        //m_autonChooser.addOption("Left Side Auton", new LeftFieldAuton(s_swerve, s_arm2, s_claw, s_intake, s_wheels, s_limelight));
        //m_autonChooser.addOption("Last Resort", new cubeOnly(s_wheels, s_swerve, s_intake));
        m_autonChooser.addOption("Co-op High + Balance", new CubeBalance(s_wheels, s_swerve, s_intake));
        m_autonChooser.addOption("Co-op High + Mobility", new CubeBalanceMobility(s_wheels, s_swerve, s_intake));



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
                        () -> -m_driveController.getRightX() * getPercentDriveSpeed(),
                        () -> false)); // always field for now!

        
        s_arm2.setDefaultCommand(new RotateArm2Manual(s_arm2, () -> -m_operatorController.getLeftY())); // damn inverted
        //s_wheels.setDefaultCommand(new RunIntakeWheelsInfinite(s_wheels, -0.12));
        s_intake.setDefaultCommand(new RotateIntakeToPosition(s_intake, 0));
        s_reportingSubsystem.setDefaultCommand(new ReportingCommand(s_reportingSubsystem, s_pigeon2));
        s_limelight.setDefaultCommand(new TeleopVision(s_limelight));

        configureDriverButtonBindings();
        configureOperatorButtonBindings();

        SwerveSubsystem.refreshRollOffset();

    }

    private void configureDriverButtonBindings() {
        
        //Reset Gyro / LockWheels
        m_driveController.y().onTrue(
                new InstantCommand(() -> s_swerve.zeroGyro()));

        m_driveController.b().onTrue(
            new InstantCommand(() -> s_swerve.zeroGyroOther()));

        m_driveController.start().onTrue(new LockWheels(s_swerve));


        //Slow  Mode
        m_driveController.x().onTrue(new SequentialCommandGroup(
                    new InstantCommand(() -> togglePercentDriveSpeed()),
                    new ToggleRumble(m_driveController, 0.5),
                    new ToggleRumble(m_operatorController, 0.5)
                ));


        //StrafeAlign
        m_driveController.a().onTrue(new StrafeAlign(s_swerve, s_limelight, 0));        


        // intake
        m_driveController.rightTrigger()
        .onTrue(new ParallelCommandGroup(
                new RotateIntakeToPosition(s_intake, IntakeConstants.kIntakeForwardSetpoint),
                new SequentialCommandGroup(new WaitCommand(0.5)), new RunIntakeWheelsInfinite(s_wheels)));
        
        m_driveController.rightBumper()
        .onTrue(new ParallelCommandGroup(
            new RotateIntakeToPosition(s_intake, IntakeConstants.kIntakeRetractSetpoint),
            new RunIntakeWheels(s_wheels, 2.5))
            );

        m_driveController.leftTrigger().onTrue(
            new ReverseIntakeWheels(s_wheels, IntakeConstants.kIntakeWheelEjectTime, -IntakeConstants.kIntakeWheelLowSpeed));

        m_driveController.leftBumper().onTrue(
            new SequentialCommandGroup(
                new RunIntakeWheels(s_wheels, 0.15),
                new ReverseIntakeWheels(s_wheels, IntakeConstants.kIntakeWheelEjectTime, IntakeConstants.kIntakeWheelMiddleSpeed)));

        m_driveController.a().onTrue(
            new SequentialCommandGroup(
                new RunIntakeWheels(s_wheels, 0.15),
                new ReverseIntakeWheels(s_wheels, IntakeConstants.kIntakeWheelEjectTime, IntakeConstants.kIntakeWheelHighSpeed)));

        m_driveController.povLeft().onTrue(new ParallelDeadlineGroup(
            new WaitCommand(0.5), 
            new RunIntakeWheelsInfinite(s_wheels)));



        // DEBUGGING KEY BINDINGS

        m_driveController.povRight().onTrue(new BalanceWhileOn(s_swerve));

    }

    private void configureOperatorButtonBindings() {

        // arm

        m_operatorController.povUp().onTrue(new RotateArm2Position(s_arm2, ArmConstants.kArmPutHigh)
                .until(() -> Math.abs(m_operatorController.getLeftY()) > OIConstants.kArmDeadzone));
        m_operatorController.povRight().onTrue(new RotateArm2Position(s_arm2, ArmConstants.kArmPutHumanPlayer) // RIGHT  = HUMAN PLAYER PLACE
                .until(() -> Math.abs(m_operatorController.getLeftY()) > OIConstants.kArmDeadzone));
        m_operatorController.povLeft().onTrue(new RotateArm2Position(s_arm2, ArmConstants.kArmHome)            // LEFT   = HOME
                .until(() -> Math.abs(m_operatorController.getLeftY()) > OIConstants.kArmDeadzone));
        m_operatorController.povDown().onTrue(new RotateArm2Position(s_arm2, ArmConstants.kArmPutMiddle)       // DOWN   = MIDDLE PLACE
                .until(() -> Math.abs(m_operatorController.getLeftY()) > OIConstants.kArmDeadzone));
        


        // claw
        m_operatorController.a().whileTrue(new IntakeCone(s_claw));
        m_operatorController.b().whileTrue(new OuttakeCone(s_claw));      
    }




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
