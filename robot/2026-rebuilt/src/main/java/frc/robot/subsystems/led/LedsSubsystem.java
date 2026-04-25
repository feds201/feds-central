// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.subsystems.led;

import com.lumynlabs.connection.usb.USBPort;
import com.lumynlabs.devices.ConnectorXAnimate;
import com.lumynlabs.domain.led.Animation;

import edu.wpi.first.units.Units;
import edu.wpi.first.wpilibj.DriverStation;
import edu.wpi.first.wpilibj.RobotBase;
import edu.wpi.first.wpilibj.util.Color;
import edu.wpi.first.wpilibj.util.Color8Bit;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.RobotContainer;
import frc.robot.commands.swerve.TeleopSwerve.driveMode;
import frc.robot.subsystems.shooter.ShooterWheels.shooter_state;

public class LedsSubsystem extends SubsystemBase {
  public static ConnectorXAnimate m_leds = new ConnectorXAnimate();
  private static LedsSubsystem instance;
  public static shooter_state m_shooterstate = shooter_state.IDLE;
  public static driveMode m_driveMode = driveMode.NORMALDRIVE;

  public enum RobotLEDState {
    IDLE, // Handles Disabled/Auto/Teleop colors
    SHOOTING, // Shooting should be blue coment kinda fast
    STARTUP_TEST, //TBD
    ERROR_LL, // Error limelight should be blink Limelight green at 200ms
    ERROR_CAN, // Error: CAN blink green and yellow at 400ms and should be altrnate
    ERROR_JAMMING, // Error: jamming should be blink scarlett at 200ms
    ERROR_OTHER, // Error: other should be blink purple at 200ms
    OFF;
  }

  public enum DriveLEDState {
    NORMAL_DRIVE,  //TBD
    HUB_DRIVE,    //TBD
    FALCON_DRIVE,  //TBD
    OFF;          //NONE
  }

  private RobotLEDState m_currentStateLeft = RobotLEDState.OFF;
  private RobotLEDState m_lastStateLeft = RobotLEDState.OFF; // Force initial update
  private DriveLEDState m_currentStateRight = DriveLEDState.OFF;
  private DriveLEDState m_lastStateRight = DriveLEDState.OFF;
  private boolean m_isConnected = false;
  private int m_lastDSMode = -1; // -1 = Unknown, 0 = Disabled, 1 = Auto, 2 = Teleop, 3 = Test

  // Configuration
  private static final String ZONE_LEFT = "ZONE_LEFT";
  private static final String ZONE_RIGHT = "ZONE_RIGHT";
  private static final String GR_ALL = "GR_ALL";
  // Colors
  private static final Color COLOR_ORANGE = new Color(new Color8Bit(255, 100, 0));
  private static final Color COLOR_LL = new Color(new Color8Bit(102, 191, 13));
  private static final Color COLOR_RED = new Color(new Color8Bit(255, 0, 0));
  private static final Color COLOR_WHITE = new Color(new Color8Bit(255, 255, 255));
  private static final Color COLOR_YELLOW = new Color(new Color8Bit(255, 255, 0));
  private static final Color COLOR_GREEN = new Color(new Color8Bit(0, 255, 0));
  private static final Color COLOR_SCARLET = new Color(new Color8Bit(100, 14, 0));
  private static final Color COLOR_PURPLE = new Color(new Color8Bit(128, 0, 128));

  public LedsSubsystem() {
    m_currentStateLeft = RobotLEDState.IDLE; // Start with IDLE to show DS mode on startup
    m_isConnected = m_leds.Connect(USBPort.kUSB1);// PIN2
    if (RobotBase.isSimulation()) {
      m_isConnected = true;
      System.out.println("ConnectorX: Running in Simulation Mode");
    } else {
      System.out.println("ConnectorX Connected: " + m_isConnected);
    }

  }

  public RobotLEDState getShootingleds() {

    switch (m_shooterstate) {
      case SHOOTING:
      case HALFCOURT:
      case LAYUP:
      case TEST:
      case PASSING:
        return RobotLEDState.SHOOTING;

      default:
        return RobotLEDState.IDLE;
    }
  }

  public DriveLEDState desiredDriveMode() {
    return switch (m_driveMode) {
      case FALCONDRIVE -> DriveLEDState.FALCON_DRIVE;
      case HUBDRIVE -> DriveLEDState.HUB_DRIVE;
      case NORMALDRIVE -> DriveLEDState.NORMAL_DRIVE;
      default -> DriveLEDState.OFF;
    };
  }

  public boolean isConnected() {
    return m_isConnected;
  }

  @Override
  public void periodic() {
    m_driveMode = RobotContainer.getInstance().getDriveMode();
    m_currentStateRight = desiredDriveMode();
    m_currentStateLeft = getShootingleds();
    m_shooterstate = RobotContainer.getInstance().getShooterWheelsState();
    int currentDSMode = -1;
    if (DriverStation.isDisabled())
      currentDSMode = 0;
    else if (DriverStation.isAutonomous())
      currentDSMode = 1;
    else if (DriverStation.isTeleop())
      currentDSMode = 2;
    else if (DriverStation.isTest())
      currentDSMode = 3;

    // Check if the LED state changed OR if the Driver Station mode changed
    boolean dsModeChanged = (currentDSMode != m_lastDSMode);

    if (m_currentStateLeft != m_lastStateLeft || dsModeChanged) {

      // Apply the NEW state
      applyState(m_currentStateLeft);
     

      System.out.println("Switching LEDs to: " + m_currentStateLeft + " (DS Mode: " + currentDSMode + ")");
      // Sync our memory variables
      m_lastStateLeft = m_currentStateLeft;
      m_lastDSMode = currentDSMode;
    }
    // if (m_currentStateRight != m_lastStateRight) {
    //   applyLeds2State(m_currentStateRight);
    //   System.out.println("Switching LEDs 2 to: " + m_currentStateRight);
    //   m_lastStateRight = m_currentStateRight;
    // }

    m_lastDSMode = currentDSMode;
  }

  private void applyState(RobotLEDState state) {
    switch (state) {

      case OFF:
        m_leds.leds.SetColor(ZONE_LEFT, new Color(0, 0, 0));
        m_leds.leds.SetColor(ZONE_RIGHT, new Color(0, 0, 0));
        break;

      case IDLE:
        applyIDLE();
        break;
      case SHOOTING:
        m_leds.leds.SetAnimation(Animation.Blink)
            .ForGroup(GR_ALL)
            .WithColor(COLOR_WHITE)
            .WithDelay(Units.Milliseconds.of(100))
            .Reverse(false)
            .RunOnce(false);
        break;

      case ERROR_LL:
        m_leds.leds.SetAnimation(Animation.Comet)
            .ForZone(ZONE_LEFT)
            .WithColor(COLOR_LL)
            .WithDelay(Units.Milliseconds.of(100))
            .RunOnce(false);
        break;

      case ERROR_CAN:
        m_leds.leds.SetAnimation(Animation.Comet)
            .ForZone(ZONE_LEFT)
            .WithColor(COLOR_GREEN)
            .WithDelay(Units.Milliseconds.of(400))
            .RunOnce(false);
        break;

      case ERROR_JAMMING:
        m_leds.leds.SetAnimation(Animation.Blink)
            .ForZone(ZONE_LEFT)
            .WithColor(COLOR_SCARLET)
            .WithDelay(Units.Milliseconds.of(200))
            .RunOnce(false);
        break;

      case ERROR_OTHER:
        m_leds.leds.SetAnimation(Animation.Blink)
            .ForZone(ZONE_LEFT)
            .WithColor(COLOR_PURPLE)
            .WithDelay(Units.Milliseconds.of(200))
            .RunOnce(false);
        break;

      case STARTUP_TEST:
        m_leds.leds.SetAnimation(Animation.Blink)
            .ForZone(ZONE_LEFT)
            .WithColor(COLOR_ORANGE)
            .WithDelay(Units.Milliseconds.of(10))
            .RunOnce(true); // Run once for startup animation
        break;
    }
  }

  private void applyLeds2State(DriveLEDState state) {
    switch (state) {
      case OFF:
        m_leds.leds.SetColor(ZONE_RIGHT, new Color(0, 0, 0));
        break;
      case NORMAL_DRIVE:
        m_leds.leds.SetAnimation(Animation.Chase)
            .ForZone(ZONE_RIGHT)
            .WithColor(COLOR_GREEN)
            .WithDelay(Units.Milliseconds.of(100))
            .Reverse(false)
            .RunOnce(false);
        break;
      case HUB_DRIVE:
        m_leds.leds.SetAnimation(Animation.Confetti)
            .ForZone(ZONE_RIGHT)
            .WithColor(COLOR_GREEN)
            .WithDelay(Units.Milliseconds.of(10))
            .RunOnce(false);
        break;
      case FALCON_DRIVE:
        m_leds.leds.SetAnimation(Animation.Blink)
            .ForZone(ZONE_RIGHT)
            .WithColor(COLOR_ORANGE)
            .WithDelay(Units.Milliseconds.of(200))
            .RunOnce(false);
        break;
    }
  }

  private static void applyIDLE() {
    if (DriverStation.isDisabled()) {
      // Disabled: Breathe Red indicating standby/disabled
      m_leds.leds.SetAnimation(Animation.Breathe)
          .ForGroup(GR_ALL)
          .WithColor(COLOR_RED)
          .WithDelay(Units.Milliseconds.of(20))
          .RunOnce(false);
    } else if (DriverStation.isAutonomous()) {
      // Auto: Rainbow indicating Autonomous mode
      m_leds.leds.SetAnimation(Animation.RainbowRoll)
          .ForGroup(GR_ALL)
          .WithColor(COLOR_WHITE)
          .WithDelay(Units.Milliseconds.of(10))
          .Reverse(false)
          .RunOnce(false);
    } else if (DriverStation.isTeleop()) {
      m_leds.leds.SetAnimation(Animation.Blink)
          // blinking yellow in teleop
          .ForGroup(GR_ALL)
          .WithColor(COLOR_YELLOW)
          .WithDelay(Units.Milliseconds.of(150))
          .RunOnce(false);
    } else if (DriverStation.isTest()) {
      // Fallback for any other state, solid white
      m_leds.leds.SetAnimation(Animation.Chase)
          .ForGroup(GR_ALL)
          .WithColor(COLOR_YELLOW)
          .WithDelay(Units.Milliseconds.of(100))
          .Reverse(false)
          .RunOnce(false);
    }
  }
}