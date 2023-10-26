package frc.robot;


import edu.wpi.first.cameraserver.CameraServer;
import edu.wpi.first.math.filter.SlewRateLimiter;
import edu.wpi.first.wpilibj.PowerDistribution;
import edu.wpi.first.wpilibj.PowerDistribution.ModuleType;
import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.smartdashboard.SendableChooser;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.ParallelCommandGroup;
import edu.wpi.first.wpilibj2.command.SequentialCommandGroup;
import edu.wpi.first.wpilibj2.command.WaitCommand;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import frc.robot.constants.IntakeConstants;
import frc.robot.constants.PowerConstants;
import frc.robot.constants.SwerveConstants;
import frc.robot.constants.OIConstants;
import frc.robot.commands.drive.LockWheels;
import frc.robot.commands.drive.TeleopSwerve;
import frc.robot.commands.intake.RunIntakeWheels;
import frc.robot.commands.intake.RunIntakeWheelsInfinite;
import frc.robot.commands.intake.ReverseIntakeWheels;
import frc.robot.commands.intake.RotateIntakeToPosition;
import frc.robot.commands.sensor.ReportingCommand;
import frc.robot.commands.sensor.StrafeAlign;
import frc.robot.commands.sensor.TeleopVision;
import frc.robot.commands.utilityCommands.ToggleRumble;
import frc.robot.commands.auton.CubeBalance;
import frc.robot.commands.auton.CubeBalanceMobility;
import frc.robot.commands.auton.CurvePathWithMarkers;
import frc.robot.subsystems.IntakeSubsystem;
import frc.robot.subsystems.SwerveSubsystem;
import frc.robot.subsystems.WheelSubsystem;
import frc.robot.subsystems.pigeon.Pigeon2Subsystem;
import frc.robot.subsystems.pigeon.ReportingSubsystem;
import frc.robot.subsystems.LimelightSubsystem;

public class RobotContainer {
    private final SwerveSubsystem s_swerve;
    private final LimelightSubsystem s_limelight;
    private final IntakeSubsystem s_intake;
    private final WheelSubsystem s_wheels;

    public static final Pigeon2Subsystem s_pigeon2 = new Pigeon2Subsystem(SwerveConstants.pigeonID);
    private final ReportingSubsystem s_reportingSubsystem;

    private final SlewRateLimiter slewRateLimiterX = new SlewRateLimiter(15);
    private final SlewRateLimiter slewRateLimiterY = new SlewRateLimiter(15);
    public final static PowerDistribution m_PowerDistribution = new PowerDistribution(PowerConstants.kPCMChannel,
            ModuleType.kRev);

    public static double controllerMultiplier = 1;

    CommandXboxController m_driveController = new CommandXboxController(OIConstants.kDriveControllerPort);
    CommandXboxController m_operatorController = new CommandXboxController(OIConstants.kOperatorControllerPort);

    SendableChooser<Command> m_autonChooser = new SendableChooser<>();

    public RobotContainer() {
        CameraServer.startAutomaticCapture();
        s_limelight = new LimelightSubsystem();
        s_swerve = new SwerveSubsystem();
        s_intake = new IntakeSubsystem();
        s_wheels = new WheelSubsystem();
        s_reportingSubsystem = new ReportingSubsystem();

        //m_autonChooser.addOption("Center Field Auton", new CenterFieldAuton(s_swerve, s_limelight, s_arm2, s_claw, s_intake, s_wheels));
        //m_autonChooser.addOption("Left Side Auton", new LeftFieldAuton(s_swerve, s_arm2, s_claw, s_intake, s_wheels, s_limelight));
        //m_autonChooser.addOption("Last Resort", new cubeOnly(s_wheels, s_swerve, s_intake));
        m_autonChooser.addOption("Co-op High + Balance", new CubeBalance(s_wheels, s_swerve, s_intake));
        m_autonChooser.addOption("Co-op High + Mobility", new CubeBalanceMobility(s_wheels, s_swerve, s_intake));
        m_autonChooser.addOption("Left Side Auton + Markers", new CurvePathWithMarkers(s_swerve, s_intake));


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
                        () -> SwerveConstants.fieldCentric)); // always field for now!


        
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
            new InstantCommand(() -> s_swerve.zeroGyro180()));

        m_driveController.start().onTrue(new LockWheels(s_swerve));


        //Slow Mode
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

        // m_driveController.povLeft().onTrue(new ParallelDeadlineGroup(
        //     new WaitCommand(0.5), 
        //     new RunIntakeWheelsInfinite(s_wheels)));

        m_driveController.povUp().whileTrue(new TeleopSwerve(s_swerve, 
                        () -> -slewRateLimiterY.calculate(SwerveConstants.DPadSpeeds.upY * getPercentDriveSpeed()), 
                        () -> 0,
                        () -> -m_driveController.getRightX() * getPercentDriveSpeed(),
                        () -> SwerveConstants.robotCentric)); // always field for now!

        m_driveController.povUpRight().whileTrue(new TeleopSwerve(s_swerve, 
                        () -> -slewRateLimiterY.calculate(SwerveConstants.DPadSpeeds.upRightY  * getPercentDriveSpeed()), 
                        () -> -slewRateLimiterX.calculate(SwerveConstants.DPadSpeeds.upRightX  * getPercentDriveSpeed()),
                        () -> -m_driveController.getRightX() * getPercentDriveSpeed(),
                        () -> SwerveConstants.robotCentric)); // always field for now!

        m_driveController.povRight().whileTrue(new TeleopSwerve(s_swerve, 
                        () -> 0,
                        () -> -slewRateLimiterX.calculate(SwerveConstants.DPadSpeeds.rightX  * getPercentDriveSpeed()),
                        () -> -m_driveController.getRightX() * getPercentDriveSpeed(),
                        () -> SwerveConstants.robotCentric)); // always field for now!
                        
        m_driveController.povDownRight().whileTrue(new TeleopSwerve(s_swerve, 
                        () -> -slewRateLimiterY.calculate(SwerveConstants.DPadSpeeds.downRightY  * getPercentDriveSpeed()), 
                        () -> -slewRateLimiterX.calculate(SwerveConstants.DPadSpeeds.downRightX  * getPercentDriveSpeed()),
                        () -> -m_driveController.getRightX() * getPercentDriveSpeed(),
                        () -> SwerveConstants.robotCentric)); // always field for now!

        m_driveController.povDown().whileTrue(new TeleopSwerve(s_swerve, 
                        () -> -slewRateLimiterY.calculate(SwerveConstants.DPadSpeeds.downY  * getPercentDriveSpeed()), 
                        () -> 0,
                        () -> -m_driveController.getRightX() * getPercentDriveSpeed(),
                        () -> SwerveConstants.robotCentric)); // always field for now!
                        
        m_driveController.povDownLeft().whileTrue(new TeleopSwerve(s_swerve, 
                        () -> -slewRateLimiterY.calculate(SwerveConstants.DPadSpeeds.downLeftY  * getPercentDriveSpeed()), 
                        () -> -slewRateLimiterX.calculate(SwerveConstants.DPadSpeeds.downLeftX  * getPercentDriveSpeed()),
                        () -> -m_driveController.getRightX() * getPercentDriveSpeed(),
                        () -> SwerveConstants.robotCentric)); // always field for now!

        m_driveController.povLeft().whileTrue(new TeleopSwerve(s_swerve, 
                        () -> 0,
                        () -> -slewRateLimiterX.calculate(SwerveConstants.DPadSpeeds.leftX  * getPercentDriveSpeed()),
                        () -> -m_driveController.getRightX() * getPercentDriveSpeed(),
                        () -> SwerveConstants.robotCentric)); // always field for now!

        m_driveController.povUpLeft().whileTrue(new TeleopSwerve(s_swerve, 
                        () -> -slewRateLimiterY.calculate(SwerveConstants.DPadSpeeds.upLeftY  * getPercentDriveSpeed()), 
                        () -> -slewRateLimiterX.calculate(SwerveConstants.DPadSpeeds.upLeftX  * getPercentDriveSpeed()),
                        () -> -m_driveController.getRightX() * getPercentDriveSpeed(),
                        () -> SwerveConstants.robotCentric)); // always field for now!
        
        // DEBUGGING KEY BINDINGS
        // m_driveController.povRight().onTrue(new BalanceWhileOn(s_swerve));

    }

    private void configureOperatorButtonBindings() {
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

    // Its made Nihar! Just attach to an Instant method for a toggle. See togglePercentDriveSpeed for examples.
    // private void toggleRobotCentric() {
    //     if (robotCentric) {
    //         robotCentric = false;
    //     } else {
    //         robotCentric = true;
    //     }
        
    // }

    public double getPercentDriveSpeed() {
        return controllerMultiplier;
    }

}
