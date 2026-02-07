package frc.robot;

import edu.wpi.first.math.filter.SlewRateLimiter;
import edu.wpi.first.wpilibj.PowerDistribution;
import edu.wpi.first.wpilibj.PowerDistribution.ModuleType;
import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.smartdashboard.SendableChooser;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import frc.robot.constants.PowerConstants;
import frc.robot.constants.SwerveConstants;
import frc.robot.constants.OIConstants;
import frc.robot.commands.exampleCommands.LockWheels;
import frc.robot.commands.pigeon.ReportingCommand;
import frc.robot.commands.swerve.TeleopSwerve;
import frc.robot.subsystems.SwerveSubsystem;
import frc.robot.subsystems.pigeon.Pigeon2Subsystem;
import frc.robot.subsystems.pigeon.ReportingSubsystem;

public class RobotContainer {
    private final SwerveSubsystem s_swerve;
    public static final Pigeon2Subsystem s_pigeon2 = new Pigeon2Subsystem(SwerveConstants.pigeonID);
    private final ReportingSubsystem s_reportingSubsystem;

    private final SlewRateLimiter slewRateLimiterX = new SlewRateLimiter(15);
    private final SlewRateLimiter slewRateLimiterY = new SlewRateLimiter(15);
    public final static PowerDistribution m_PowerDistribution = new PowerDistribution(PowerConstants.kPCMChannel,
            ModuleType.kRev);

    CommandXboxController m_driveController = new CommandXboxController(OIConstants.kDriveControllerPort);
    CommandXboxController m_operatorController = new CommandXboxController(OIConstants.kOperatorControllerPort);

    SendableChooser<Command> m_autonChooser = new SendableChooser<>();

    public RobotContainer() {
        s_swerve = new SwerveSubsystem();
        s_reportingSubsystem = new ReportingSubsystem();

        Shuffleboard.getTab("Autons").add(m_autonChooser);

        s_swerve.setDefaultCommand(
                new TeleopSwerve(
                        s_swerve,
                        () -> -slewRateLimiterY.calculate(m_driveController.getLeftY()), 
                        () -> -slewRateLimiterX.calculate(m_driveController.getLeftX()),
                        () -> -m_driveController.getRightX(),
                        () -> SwerveConstants.fieldCentric)); // always field for now!

        s_reportingSubsystem.setDefaultCommand(new ReportingCommand(s_reportingSubsystem, s_pigeon2));
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
    }

    private void configureOperatorButtonBindings() {}

    public Command getAutonomousCommand() {
        return m_autonChooser.getSelected();
    }
}
