package frc.robot;

import java.util.ArrayList;

import edu.wpi.first.cameraserver.CameraServer;
import edu.wpi.first.cscore.UsbCamera;
import edu.wpi.first.cscore.VideoSource.ConnectionStrategy;
import edu.wpi.first.math.filter.SlewRateLimiter;
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
import frc.robot.constants.TelescopeConstants;
import frc.robot.constants.OIConstants;
import frc.robot.commands.arm.ArmRotationCommandManual;
import frc.robot.commands.arm.WaitUntilFullyRotate;

import frc.robot.commands.drive.LockWheels;
import frc.robot.commands.drive.TeleopSwerve;
import frc.robot.commands.intake.DeployIntake;
import frc.robot.commands.intake.DeployIntakeGroup;
import frc.robot.commands.intake.RetractIntake;
import frc.robot.commands.intake.RetractIntakeGroup;
import frc.robot.commands.intake.RunIntakeWheels;
import frc.robot.commands.intake.StopIntakeWheels;
import frc.robot.commands.orientator.ReverseOrientator;
import frc.robot.commands.orientator.RunOrientator;
import frc.robot.commands.orientator.StopOrientator;
import frc.robot.commands.sensor.StrafeAlign;
import frc.robot.commands.telescope.ExtendTelescope;
import frc.robot.commands.telescope.RetractTelescope;
import frc.robot.commands.telescope.TelescopeManualArm;
import frc.robot.commands.utilityCommands.TimerDeadline;
import frc.robot.commands.auton.examplePPAuto;
import frc.robot.commands.auton.placeConeAndCharge;
import frc.robot.commands.auton.placeConeAuton;
import frc.robot.commands.claw.CloseClaw;
import frc.robot.commands.claw.OpenClaw;
import frc.robot.commands.claw.kickOutPiece;
// import frc.robot.subsystems.ArmSubsystem;
import frc.robot.subsystems.ArmSubsystem3;
import frc.robot.subsystems.ClawSubsystem;
import frc.robot.subsystems.ClawSubsystemWithPID;
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
    // private final ArmSubsystem s_arm;
    private final ArmSubsystem3 s_arm;
    //private final OrientatorSubsystem s_orientator;
    // private final TelescopeSubsystem s_telescope;
    // private final IntakeSubsystem s_intakeBlue;
    private final ClawSubsystemWithPID s_claw;

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

        s_vision = new VisionSubsystem();
        // s_intakeBlue = new IntakeSubsystem(IntakeConstants.kIntakeBlueLeftDeployMotor,
        //                   IntakeConstants.kIntakeBlueLeftWheelMotor, false);
        // s_telescope = new TelescopeSubsystem();
        //s_orientator = new OrientatorSubsystem();
        s_swerve = new SwerveSubsystem(s_vision);
        // s_arm = new ArmSubsystem();
        s_arm = new ArmSubsystem3();
        s_claw = new ClawSubsystemWithPID();

        // m_autonChooser.setDefaultOption("Example PP Swerve", new placeConeAndCharge(s_swerve, s_claw, s_telescope, s_arm));
        // m_autonChooser.addOption("Example Swerve", new placeConeAuton(s_claw, s_telescope, s_arm));
        // m_autonChooser.addOption("GetOnBridge", new GetOnBridge(s_swerve));

        Shuffleboard.getTab("Autons").add(m_autonChooser);

        s_swerve.setDefaultCommand(
            new TeleopSwerve(
                s_swerve,
                // () -> -m_driveController.getLeftY(),
                // () -> -m_driveController.getLeftX(),
                () -> -slewRateLimiterY.calculate(m_driveController.getLeftY() * getPercentDriveSpeed()), //FIXME: DOES THIS CRAP WORK?
                () -> -slewRateLimiterX.calculate(m_driveController.getLeftX() * getPercentDriveSpeed()),
                () -> -m_driveController.getRightX(),
                () -> m_driveController.rightTrigger().getAsBoolean()));

        s_arm.setDefaultCommand(new ArmRotationCommandManual(s_arm, () -> m_operatorController.getLeftY()));

        // s_telescope.setDefaultCommand(
        //     new TelescopeManualArm(
        //         s_telescope, 
        //         () -> m_operatorController.getRIght()));

        configureDriverButtonBindings();
        configureOperatorButtonBindings();
        configureTriggerBindings();
    }

    private void configureDriverButtonBindings() {
        // driver
        // right bumper: claw open close
        // r-trigger: intake open
        m_driveController.y().onTrue(
            new InstantCommand(() -> s_swerve.zeroGyro()));

        m_driveController.start().onTrue(new LockWheels(s_swerve));

        m_driveController.povUp().whileTrue(new TeleopSwerve(s_swerve, () -> SwerveConstants.kPreciseSwerveSpeed, () -> 0, () -> 0, () -> true));
        m_driveController.povDown().whileTrue(new TeleopSwerve(s_swerve, () -> -SwerveConstants.kPreciseSwerveSpeed, () -> 0, () -> 0, () -> true));
        m_driveController.povLeft().whileTrue(new TeleopSwerve(s_swerve, () -> 0, () -> SwerveConstants.kPreciseSwerveSpeed, () -> 0, () -> true));
        m_driveController.povRight().whileTrue(new TeleopSwerve(s_swerve, () -> 0, () -> -SwerveConstants.kPreciseSwerveSpeed, () -> 0, () -> true));

        m_driveController.x().onTrue(new InstantCommand(() -> togglePercentDriveSpeed()));

        //m_driveController.leftTrigger().onTrue(new DeployIntakeGroup(s_intakeBlue, s_orientator));
        //m_driveController.leftBumper().onTrue(new RetractIntake(s_intakeBlue));
        //m_driveController.leftBumper().onTrue(new RetractIntake(s_intakeBlue));*/
        //m_driveController.rightTrigger().onTrue(new OpenClaw(s_claw));
        //m_driveController.rightBumper().onTrue(new CloseClaw( s_claw));
    }
    
    private void configureOperatorButtonBindings() {
        // operator
        // r-bumper: claw open close
        // r-stick: precise rotation of arm
        // l-stick press: activate DANGER MODE
        // l-stick: nothing normally. DANGER MODE: control telescoping arm
        // d-pad: control presents for the telescoping arm
        // l-bumper: reverse intake

        // m_operatorController.a()
        //     .onTrue(new ParallelCommandGroup(
        //         s_arm.setPosition(ArmConstants.kArmGrabCone),
        //         new SequentialCommandGroup(
        //             // new WaitUntilFullyRotate(s_arm),
        //             new WaitCommand(1),
        //             new ExtendTelescope(s_telescope,
        //                 TelescopeConstants.kTelescopeGrabCone))));
        
        // m_operatorController.povUp()
        //     .onTrue(new ParallelCommandGroup(
        //         s_arm.setPosition(ArmConstants.kArmPutHigh),
        //         new SequentialCommandGroup(
        //             // new WaitUntilFullyRotate(s_arm),
        //             new WaitCommand(1),
        //             new ExtendTelescope(s_telescope,
        //                 TelescopeConstants.kTelescopeExtendedMax))));

        // m_operatorController.povRight() 
        //     .onTrue(new ParallelCommandGroup(
        //                 s_arm.setPosition(ArmConstants.kArmPutMiddle),
        //                 new SequentialCommandGroup(
        //                         new WaitCommand(1),
        //                         new ExtendTelescope(s_telescope,
        //                                 TelescopeConstants.kTelescopeExtendedMiddle))));

        // m_operatorController.povDown()
        //         .onTrue(new ParallelCommandGroup(s_arm.setPosition(ArmConstants.kArmPutLow),
        //                 new SequentialCommandGroup(
        //                         new WaitCommand(1),
        //                         new ExtendTelescope(s_telescope,
        //                                 TelescopeConstants.kTelescopeExtendedMiddle))));

        // m_operatorController.povLeft()
        //         .onTrue(new ParallelCommandGroup(
        //                 new RetractTelescope(s_telescope),
        //                 new SequentialCommandGroup(new WaitCommand(2.0),
        //                         s_arm.setPosition(ArmConstants.kArmHome))));

        m_operatorController.rightTrigger().onTrue(new OpenClaw(s_claw));
        m_operatorController.rightBumper().onTrue(new CloseClaw(s_claw));
        m_operatorController.leftTrigger().onTrue(new kickOutPiece(s_claw));

        /*m_operatorController.leftTrigger().onTrue(
            new RunOrientator(s_orientator)
            .withTimeout(3)
            .andThen(new StopOrientator(s_orientator)));
        
        m_operatorController.leftBumper().onTrue(
            new ReverseOrientator(s_orientator)
            .withTimeout(3)
            .andThen(new StopOrientator(s_orientator)));*/


        //m_operatorController.a().onTrue(s_arm.slowlyGoUp());
        //m_operatorController.b().onTrue(s_arm.slowlyGoDown());

    }

    private void configureTriggerBindings() {
        new Trigger(s_swerve::gyroNotZero)
                .onTrue(new InstantCommand(() -> SmartDashboard.putBoolean("GyroZero", false)))
                .onFalse(new InstantCommand(() -> SmartDashboard.putBoolean("GyroNotZero", true)));
    }


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
