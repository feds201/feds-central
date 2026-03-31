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
import frc.robot.Robot;
import frc.robot.RobotContainer;
import frc.robot.commands.swerve.TeleopSwerve.driveMode;
import frc.robot.subsystems.shooter.ShooterWheels.shooter_state;

public class LedsSubsystem extends SubsystemBase {
  public static ConnectorXAnimate m_leds = new ConnectorXAnimate();
  public static ConnectorXAnimate m_leds2 = new ConnectorXAnimate();
  private static LedsSubsystem instance;
  public static shooter_state m_shooterstate = shooter_state.IDLE;
  public static driveMode m_driveMode = driveMode.NORMALDRIVE;
  // private double m_lastHeartbeat = -1;
  // private int m_heartbeatStuckCount = 0;

  public static LedsSubsystem getInstance() {
    if (instance == null) {
      instance = new LedsSubsystem();

    }
    return instance;
  }

  public enum RobotLEDState {
    IDLE, // Handles Disabled/Auto/Teleop colors
    SHOOTING,
    STARTUP_TEST,
    ERROR_LL,
    ERROR_CAN,
    ERROR_JAMMING,
    ERROR_OTHER,
    OFF
  }

  public enum DriveLEDState {
    NORMAL_DRIVE,
    HUB_DRIVE,
    FALCON_DRIVE,
    OFF
  }

  private RobotLEDState m_currentState = RobotLEDState.OFF;
  private RobotLEDState m_lastState = RobotLEDState.OFF; // Force initial update
  private DriveLEDState m_currentState2 = DriveLEDState.OFF;
  private DriveLEDState m_lastState2 = DriveLEDState.OFF;
  private boolean m_isConnected = false;
  private boolean m_isConnected_2 = false;
  private int m_lastDSMode = -1; // -1 = Unknown, 0 = Disabled, 1 = Auto, 2 = Teleop, 3 = Test

  // Configuration
  private static final String ZONE_1 = "ZONE_50_1";
  private static final String ZONE_2 = "ZONE_50_2";
  private static final String ZONE_3 = "ZONE_50_3";
  private static final String ZONE_4 = "ZONE_50_4";
  private static final String ZONE_5 = "ZONE_50_5";
  private static final String ZONE_6 = "ZONE_50_6";
  private static final String GR_300 = "GR_300";

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
    m_currentState = RobotLEDState.IDLE; // Start with IDLE to show DS mode on startup
    m_isConnected = m_leds.Connect(USBPort.kUSB1);// PIN2
    m_isConnected_2 = m_leds2.Connect(USBPort.kUSB2);// PIN3
    if (RobotBase.isSimulation()) {
      m_isConnected = true;
      System.out.println("ConnectorX: Running in Simulation Mode");
    } else {
      System.out.println("ConnectorX Connected: " + m_isConnected);
      System.out.println("ConnectorX2 Connected: " + m_isConnected_2);
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

  public boolean m_isConnected_2() {
    return m_isConnected_2;
  }

  @Override
  public void periodic() {
    m_driveMode = RobotContainer.getInstance().getDriveMode();
    m_currentState2 = desiredDriveMode();
    m_currentState = getShootingleds();
    m_shooterstate = RobotContainer.getInstance().getShooterWheelsState();

    // Determine current DS Mode as an integer
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

    if (m_currentState != m_lastState || dsModeChanged) {

      // Apply the NEW state
      applyState(m_currentState);

      System.out.println("Switching LEDs to: " + m_currentState + " (DS Mode: " + currentDSMode + ")");
      // Sync our memory variables
      m_lastState = m_currentState;
      m_lastDSMode = currentDSMode;
    }
    if (m_currentState2 != m_lastState2) {
      applyLeds2State(m_currentState2);
      System.out.println("Switching LEDs 2 to: " + m_currentState2);
      m_lastState2 = m_currentState2;
    }

    m_lastDSMode = currentDSMode;
  }

  private void applyState(RobotLEDState state) {
    switch (state) {

      case OFF:
        m_leds.leds.SetColor(GR_300, new Color(0, 0, 0));
        break;

      case IDLE:

        System.out.println("applyState: IDLE");
        applyIDLE();
        break;
      case SHOOTING:
        System.out.println("applyState: SHOOTING");
        m_leds.leds.SetAnimation(Animation.Blink)
            .ForZone(GR_300)
            .WithColor(COLOR_WHITE)
            .WithDelay(Units.Milliseconds.of(10))
            .Reverse(false)
            .RunOnce(false);
        break;

      case ERROR_LL:
        m_leds.leds.SetAnimation(Animation.Comet)
            .ForGroup(GR_300)
            .WithColor(COLOR_LL)
            .WithDelay(Units.Milliseconds.of(100))
            .RunOnce(false);
        break;

      case ERROR_CAN:
        m_leds.leds.SetAnimation(Animation.Comet)
            .ForGroup(GR_300)
            .WithColor(COLOR_GREEN)
            .WithDelay(Units.Milliseconds.of(400))
            .RunOnce(false);
        break;

      case ERROR_JAMMING:
        m_leds.leds.SetAnimation(Animation.Blink)
            .ForGroup(GR_300)
            .WithColor(COLOR_SCARLET)
            .WithDelay(Units.Milliseconds.of(200))
            .RunOnce(false);
        break;

      case ERROR_OTHER:
        m_leds.leds.SetAnimation(Animation.Blink)
            .ForGroup(GR_300)
            .WithColor(COLOR_PURPLE)
            .WithDelay(Units.Milliseconds.of(200))
            .RunOnce(false);
        break;

      case STARTUP_TEST:
        m_leds.leds.SetAnimation(Animation.Blink)
            .ForGroup(GR_300)
            .WithColor(COLOR_ORANGE)
            .WithDelay(Units.Milliseconds.of(10))
            .RunOnce(true); // Run once for startup animation
        break;
    }
  }

  private void applyLeds2State(DriveLEDState state) {
    switch (state) {
      case OFF:
        m_leds2.leds.SetColor(GR_300, new Color(0, 0, 0));
        break;
      case NORMAL_DRIVE:
        m_leds2.leds.SetAnimation(Animation.Chase)
            .ForZone(ZONE_1)
            .WithColor(COLOR_GREEN)
            .WithDelay(Units.Milliseconds.of(100))
            .Reverse(false)
            .RunOnce(false);
        break;
      case HUB_DRIVE:
        m_leds2.leds.SetAnimation(Animation.Confetti)
            .ForZone(ZONE_1)
            .WithColor(COLOR_GREEN)
            .WithDelay(Units.Milliseconds.of(10))
            .RunOnce(false);
        break;
      case FALCON_DRIVE:
        m_leds2.leds.SetAnimation(Animation.Blink)
            .ForZone(ZONE_1)
            .WithColor(COLOR_ORANGE)
            .WithDelay(Units.Milliseconds.of(200))
            .RunOnce(false);
        break;
    }
  }

  private static void applyIDLE() {
    if (DriverStation.isDisabled()) {
      System.out.println("isDisabled");
      // Disabled: Breathe Red indicating standby/disabled
      m_leds.leds.SetAnimation(Animation.Breathe)
          .ForZone(GR_300)
          .WithColor(COLOR_RED)
          .WithDelay(Units.Milliseconds.of(20))
          .RunOnce(false);
    } else if (DriverStation.isAutonomous()) {
      System.out.println("isAuto");
      // Auto: Rainbow indicating Autonomous mode
      m_leds.leds.SetAnimation(Animation.RainbowRoll)
          .ForZone(GR_300)
          .WithColor(COLOR_WHITE)
          .WithDelay(Units.Milliseconds.of(10))
          .Reverse(false)
          .RunOnce(false);
    } else if (DriverStation.isTeleop()) {
      System.out.println("Teleop");
      m_leds.leds.SetAnimation(Animation.Blink)
          // blinking yellow in teleop
          .ForZone(GR_300)
          .WithColor(COLOR_YELLOW)
          .WithDelay(Units.Milliseconds.of(150))
          .RunOnce(false);
    } else if (DriverStation.isTest()) {
      System.out.println("Test");
      // Fallback for any other state, solid white
      m_leds.leds.SetAnimation(Animation.Chase)
          .ForZone(GR_300)
          .WithColor(COLOR_YELLOW)
          .WithDelay(Units.Milliseconds.of(100))
          .Reverse(false)
          .RunOnce(false);
    }
  }

}