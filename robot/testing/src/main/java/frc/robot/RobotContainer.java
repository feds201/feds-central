
package frc.robot;

import frc.robot.subsystems.MotorTestSubsystem;
import frc.utils.RTU.RootTestingUtility;
import frc.robot.Constants.OperatorConstants;
import frc.robot.commands.ExampleCommand;
import frc.robot.subsystems.ExampleSubsystem;

import com.ctre.phoenix6.hardware.TalonFX;

import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import edu.wpi.first.wpilibj2.command.button.Trigger;

/**
 * This class is where the bulk of the robot should be declared. Since Command-based is a
 * "declarative" paradigm, very little robot logic should actually be handled in the {@link Robot}
 * periodic methods (other than the scheduler calls). Instead, the structure of the robot (including
 * subsystems, commands, and trigger mappings) should be declared here.
 */
public class RobotContainer {
  // The robot's subsystems and commands are defined here...
  private final ExampleSubsystem m_exampleSubsystem = new ExampleSubsystem();
  private TalonFX motor = new TalonFX(23); // Example motor controller, replace with your actual motor and ID
  private final MotorTestSubsystem m_motorTestSubsystem = new MotorTestSubsystem(motor);

  // Replace with CommandPS4Controller or CommandJoystick if needed
  private final CommandXboxController m_driverController =
      new CommandXboxController(OperatorConstants.kDriverControllerPort);

  // Root Testing Utility
  private final RootTestingUtility rootTester = new RootTestingUtility();

  /** The container for the robot. Contains subsystems, OI devices, and commands. */
  public RobotContainer() {
    // Configure the trigger bindings
    configureBindings();
    configureRootTests();
  }

  /**
   * Use this method to define your trigger->command mappings. Triggers can be created via the
   * {@link Trigger#Trigger(java.util.function.BooleanSupplier)} constructor with an arbitrary
   * predicate, or via the named factories in {@link
   * edu.wpi.first.wpilibj2.command.button.CommandGenericHID}'s subclasses for {@link
   * CommandXboxController Xbox}/{@link edu.wpi.first.wpilibj2.command.button.CommandPS4Controller
   * PS4} controllers or {@link edu.wpi.first.wpilibj2.command.button.CommandJoystick Flight
   * joysticks}.
   */
  private void configureBindings() {
    // Schedule `ExampleCommand` when `exampleCondition` changes to `true`
    // ...existing code...
  }

  /**
   * Register subsystems and configure safety check for RTU.
   */
  private void configureRootTests() {
    rootTester.registerSubsystem(
      m_exampleSubsystem,
      m_motorTestSubsystem
      // Add other subsystems here
    );
    rootTester.setSafetyCheck(() -> {
      if (!m_driverController.getHID().isConnected()) {
        return "Joystick is not connected";
      }
      boolean triggersOk = m_driverController.getLeftTriggerAxis() >= 0.5 && m_driverController.getRightTriggerAxis() >= 0.5;
      boolean xyOk = m_driverController.getHID().getXButton() && m_driverController.getHID().getYButton();
      if (!triggersOk && !xyOk) {
        return "Did not receive start command from gamepads, please press both triggers (or X+Y) to continue the tests";
      }
      return null; // Safe to run
    });
  }

  /**
   * Run all root tests (call from Robot.testInit()).
   */
  public void runRootTests() {
    rootTester.runAll();
  }

  /**
   * Update root tests (call from Robot.testPeriodic()).
   */
  public void updateRootTests() {
    rootTester.periodic();
  }

  /**
   * Use this to pass the autonomous command to the main {@link Robot} class.
   *
   * @return the command to run in autonomous
   */
  public Command getAutonomousCommand() {
  // An example command will be run in autonomous
  return null;
  // ...existing code...
  }
}
