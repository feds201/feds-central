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
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.commands.swerve.TeleopSwerve.driveMode;
import frc.robot.subsystems.shooter.ShooterHood.shooterhood_state;
import frc.robot.subsystems.shooter.ShooterWheels.shooter_state;;

public class LedsSubsystem extends SubsystemBase {
  public static ConnectorXAnimate m_leds = new ConnectorXAnimate();
  private static LedsSubsystem instance;
  public static shooter_state m_shooter_state;
  public static driveMode m_driveMode;
  public static shooterhood_state m_shooterhood_state;
  // private double m_lastHeartbeat = -1;
  // private int m_heartbeatStuckCount = 0;

  public static LedsSubsystem getInstance() {
    if (instance == null) {
      instance = new LedsSubsystem();

    }
    return instance;
  }

  // public static boolean isjammed() {
  // // Placeholder for actual jamming detection logic
  // // This could be based on motor current spikes, encoder feedback, etc.
  // return false; // Replace with real condition
  // }

  // public boolean isLimelightStable() {
  // double currentHeartbeat = NetworkTableInstance.getDefault()
  // .getTable("limelight")
  // .getEntry("hb")
  // .getDouble(-1);

  // if (currentHeartbeat == m_lastHeartbeat) {
  // m_heartbeatStuckCount++;
  // } else {
  // m_heartbeatStuckCount = 0;
  // m_lastHeartbeat = currentHeartbeat;
  // }

  // // If the heartbeat hasn't changed in 10 loops (~200ms), it's unstable
  // return m_heartbeatStuckCount < 10;
  // }

  public static enum LEDState {
    FALCON_DRIVE, // Flashing Orange at 200ms
    HUB_DRIVE, // TBD
    SHOOTING, // Shooting should be blue coment kinda fast
    ERROR_LL, // Error limelight should be blink Limelight green at 200ms
    ERROR_CAN, // Error: CAN blink green and yellow at 400ms and should be altrnate
    ERROR_JAMMING, // Error: jamming should be blink scarlett at 200ms
    ERROR_OTHER, // blink pruple at 200ms
    IDLE, // Default state, should be solid yellow when disabled, solid red in auto, and

    OFF, // All LEDs off
    STARTUP_TEST; // Tests state for startup testing animation;

    // Error: other should blink purple at 200ms

  }

  private LEDState m_currentState = LEDState.OFF;
  private LEDState DesiredState = LEDState.IDLE; // Force initial update
  private boolean m_isConnected = false;
  private boolean m_wasDisabled = true; // Tracks if DriverStation mode changed

  // Configuration
  private static final String ZONE_1 = "ZONE_50_1";
  private static final String ZONE_2 = "ZONE_50_2";
  private static final String ZONE_3 = "ZONE_50_3";
  private static final String ZONE_4 = "ZONE_50_4";
  private static final String ZONE_5 = "ZONE_50_5";
  private static final String ZONE_6 = "ZONE_50_6";
  private static final String GR_300 = "GR_300";
  private static final String GR_100_1 = "GR_100";
  private static final String GR_200_2 = "GR_100_2";
  private static final String GR_200_3 = "GR_100_3";

  // Colors
  private static final Color COLOR_ORANGE = new Color(new Color8Bit(255, 100, 0));
  private static final Color COLOR_LL = new Color(new Color8Bit(102, 191, 13));
  private static final Color COLOR_RED = new Color(new Color8Bit(255, 0, 0));
  private static final Color COLOR_WHITE = new Color(new Color8Bit(255, 255, 255));
  private static final Color COLOR_YELLOW = new Color(new Color8Bit(255, 255, 0));
  private static final Color COLOR_GREEN = new Color(new Color8Bit(0, 255, 0));
  private static final Color COLOR_FEDS_BLUE = new Color(new Color8Bit(0, 255, 255));
  private static final Color COLOR_SCARLET = new Color(new Color8Bit(100, 14, 0));
  private static final Color COLOR_PURPLE = new Color(new Color8Bit(128, 0, 128));

  public LedsSubsystem() {

    if (!RobotBase.isSimulation()) {
      m_isConnected = m_leds.Connect(USBPort.kUSB1);
    } else {
      m_isConnected = true; // Assume connected in simulation for testing purposes

    }

    System.out.println("ConnectorX connected: " + m_isConnected);

    // Initial State application will happen in periodic loop or manually here
    // But periodic handles state change, so setting lastState to OFF calls
    // applyState(IDLE) in first loop.
  }

  public boolean isConnected() {
    return m_isConnected;
  }

  @Override
  public void periodic() {

    m_currentState = Next_DiseredState();

    // 2. Determine if the DriverStation mode flipped (e.g. Disabled -> Teleop)
    boolean isDisabled = DriverStation.isDisabled();
    boolean modeChanged = (isDisabled != m_wasDisabled);

    // 3. Apply changes only if the State changed OR the DS mode changed while in
    // IDLE
    if (m_currentState != DesiredState || (modeChanged)) {
      applyState(DesiredState);
      System.out.println(m_currentState);
    } else {
      System.out.println("Current=Desired" + ", ModeChanged: " + modeChanged);
      // Update our "memory" variables
      DesiredState = m_currentState;
      m_wasDisabled = isDisabled;
    }

  }

  /**
   * Directly set the state of the LEDs.
   * 
   * @param state The target state
   */

  private void setState(LEDState state) {
    System.out.println(m_currentState);
  }

  private void applyState(LEDState state) {
    switch (state) {

      case OFF:
        m_leds.leds.SetColor(GR_300, new Color(0, 0, 0));
        break;

      case IDLE:

        System.out.println("applyState: IDLE");
        applyRobotState();
        break;

      case FALCON_DRIVE:
        m_leds.leds.SetAnimation(Animation.Blink)
            .ForGroup(GR_300)
            .WithColor(COLOR_ORANGE)
            .WithDelay(Units.Milliseconds.of(200))
            .RunOnce(false);
        break;

      case HUB_DRIVE:
        m_leds.leds.SetAnimation(Animation.Confetti)
            .ForGroup(GR_300)
            .WithColor(COLOR_GREEN)
            .WithDelay(Units.Milliseconds.of(10))
            .RunOnce(false);
        break;

      case SHOOTING:
        m_leds.leds.SetAnimation(Animation.Comet)
            .ForGroup(GR_300)
            .WithColor(COLOR_FEDS_BLUE)
            .WithDelay(Units.Milliseconds.of(20))
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
            .ForZone(ZONE_1)
            .WithColor(COLOR_YELLOW)
            .ForZone(ZONE_2)
            .WithColor(COLOR_GREEN)
            .ForZone(ZONE_3)
            .WithColor(COLOR_YELLOW)
            .ForZone(ZONE_4)
            .WithColor(COLOR_GREEN)
            .ForZone(ZONE_5)
            .WithColor(COLOR_YELLOW)
            .ForZone(ZONE_6)
            .WithColor(COLOR_GREEN)
            .WithDelay(Units.Milliseconds.of(100))
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

  private static void applyRobotState() {
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
          .WithDelay(Units.Milliseconds.of(15))
          .RunOnce(false);
    } else if (DriverStation.isTest()) {
      System.out.println("Test");
      // Fallback for any other state, solid white
      m_leds.leds.SetAnimation(Animation.Breathe)
          .ForZone(GR_300)
          .WithColor(COLOR_YELLOW)
          .WithDelay(Units.Milliseconds.of(10))
          .Reverse(false)
          .RunOnce(false);
    }
  }

  public LEDState Next_DiseredState() {

    if (m_shooter_state == shooter_state.SHOOTING || m_shooter_state == shooter_state.HALFCOURT
        || m_shooter_state == shooter_state.LAYUP || m_shooter_state == shooter_state.TEST
        || m_shooter_state == shooter_state.PASSING) {
      return LEDState.SHOOTING;
    } else if (m_driveMode == driveMode.FALCONDRIVE) {
      return LEDState.FALCON_DRIVE;
    } else if (m_driveMode == driveMode.HUBDRIVE) {
      return LEDState.HUB_DRIVE;
    }

    else {
      return LEDState.IDLE;
    }

  }

  public Command setStateCommand(LEDState state) {
    return runOnce(() -> setState(state)).ignoringDisable(true);
  }

  @Deprecated
  public Command setLEDState(LEDState state) {
    return setStateCommand(state);
  }

}
