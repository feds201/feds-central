// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.subsystems.led;


import com.lumynlabs.connection.usb.USBPort;
import com.lumynlabs.devices.ConnectorXAnimate;
import com.lumynlabs.domain.led.Animation;

import edu.wpi.first.networktables.NetworkTableInstance;
import edu.wpi.first.units.Units;
import edu.wpi.first.wpilibj.DriverStation;
import edu.wpi.first.wpilibj.RobotController;
import edu.wpi.first.wpilibj.Timer;
import edu.wpi.first.wpilibj.util.Color;
import edu.wpi.first.wpilibj.util.Color8Bit;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import frc.robot.commands.swerve.TeleopSwerve.driveMode;
import frc.robot.subsystems.shooter.ShooterHood.shooterhood_state;
import frc.robot.subsystems.shooter.ShooterWheels.shooter_state;;


public class LedsSubsystem extends SubsystemBase {
  public ConnectorXAnimate m_leds = new ConnectorXAnimate();
  private static LedsSubsystem instance;
  public static shooter_state m_shooter_state;
  public static driveMode m_driveMode;
  public static shooterhood_state m_shooterhood_state;
  LEDState desiredState = LEDState.IDLE;
  private double m_lastHeartbeat = -1;
  private int m_heartbeatStuckCount = 0;



   public static LedsSubsystem getInstance() { 
    if (instance == null) {
      instance = new LedsSubsystem();
    }
    return instance;
  }

  public static boolean isjammed() {
    // Placeholder for actual jamming detection logic
    // This could be based on motor current spikes, encoder feedback, etc.
    return false; // Replace with real condition
  }

  public boolean isLimelightStable() {
    double currentHeartbeat = NetworkTableInstance.getDefault()
        .getTable("limelight")
        .getEntry("hb")
        .getDouble(-1);

    if (currentHeartbeat == m_lastHeartbeat) {
        m_heartbeatStuckCount++;
    } else {
        m_heartbeatStuckCount = 0;
        m_lastHeartbeat = currentHeartbeat;
    }

    // If the heartbeat hasn't changed in 10 loops (~200ms), it's unstable
    return m_heartbeatStuckCount < 10;
}


  public static enum LEDState {              
    FALCON_DRIVE,                    // Flashing Orange at 200ms
    HUB_DRIVE,                       // TBD
    AIMED,                          // When aimed should be fill solid Red
    SHOOTING,                      // Shooting should be blue coment kinda fast
    // CLIMBING,                     // Rainbow         
    ERROR_LL,                    //Error limelight should be blink Limelight green at 200ms
    ERROR_CAN,                  //Error: CAN blink green and yellow at 400ms and should be altrnate
    ERROR_JAMMING,             //Error: jamming should be blink scarlett at 200ms
    ERROR_OTHER,              // blink pruple at 200ms
    IDLE,                    // Default state, should be solid yellow when disabled, solid red in auto, and blinking yellow in teleop
    OFF,                    // All LEDs off   
    STARTUP_TEST,         // Tests state for startup testing animation;
    DISABLE,
    TELEOP,
    AUTON;

               //Error: other should blink purple at 200ms
                    
  }



  private LEDState m_currentState = LEDState.IDLE;
  private LEDState m_lastState = LEDState.OFF; // Force initial update
  private boolean m_wasDisabled = false;
  private boolean m_wasAuto = false;
  private boolean m_isConnected = false;
 
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
  private static final Color COLOR_LL = new Color(new Color8Bit(102,191,13));
  private static final Color COLOR_RED = new Color(new Color8Bit(255, 0, 0));
  private static final Color COLOR_WHITE = new Color(new Color8Bit(255, 255, 255));
  private static final Color COLOR_YELLOW = new Color(new Color8Bit(255, 255, 0));
  private static final Color COLOR_GREEN = new Color(new Color8Bit(0, 255, 0));
  private static final Color COLOR_FEDS_BLUE = new Color(new Color8Bit(0, 255, 255));
  private static final Color COLOR_SCARLET = new Color(new Color8Bit(100, 14, 0));
  private static final Color COLOR_PURPLE = new Color(new Color8Bit(128, 0, 128));


  public LedsSubsystem() {
   // m_shooterWheels = null;
    // for (Subsystem subsystem : subsystems) {
    //   if (subsystem instanceof ShooterWheels) { m_shooterWheels = (ShooterWheels) subsystem; }
    //   if (subsystem instanceof ShooterHood) { m_shooterHood = (ShooterHood) subsystem;}
    //   // Climb is currently not used for LED state changes, but we can easily add it in the future if needed
    //   // else if (subsystem instanceof Climb) { m_climb = (Climb) subsystem;  
    // Connect to the device on USB port 2
    m_isConnected = m_leds.Connect(USBPort.kUSB1);
    System.out.println("ConnectorX connected: " + m_isConnected);
   
    // Initial State application will happen in periodic loop or manually here
    // But periodic handles state change, so setting lastState to OFF calls applyState(IDLE) in first loop.
  }

  public boolean isConnected() {
    return m_isConnected;
  }

  @Override
  public void periodic() {  
 //Highest Priority: probs
    if (RobotController.getCANStatus().percentBusUtilization > 0.8) {
        desiredState = LEDState.ERROR_CAN;
    } 
    else if (isLimelightStable() == false) {
        desiredState = LEDState.ERROR_LL;
    }

    else if ( isjammed() = DriverStation.reportError) { 
        desiredState = LEDState.ERROR_JAMMING;
    }

    //2 Highest Priority: Shooter
    if (m_shooter_state == shooter_state.SHOOTING || m_shooter_state == shooter_state.HALFCOURT 
        || m_shooter_state == shooter_state.LAYUP || m_shooter_state == shooter_state.TEST 
        || m_shooter_state == shooter_state.PASSING) {
        desiredState = LEDState.SHOOTING;
    } 
    // Medium Priority: Driving Modes
    else if (m_driveMode != null && "FALCON_DRIVE".equals(m_driveMode.name())) {
        desiredState = LEDState.FALCON_DRIVE;
    }
    else if (m_driveMode != null && "HUB_DRIVE".equals(m_driveMode.name())) {
        desiredState = LEDState.HUB_DRIVE;
    }
    // Lower Priority: Aiming
    else if (m_shooterhood_state != null && 
            ("AIMING_UP".equals(m_shooterhood_state.name()) || "AIMING_DOWN".equals(m_shooterhood_state.name()))) {
        desiredState = LEDState.AIMED;
    }

    // 2. Handle IDLE sub-states (Disabled/Auto/Tele)
    if (desiredState == LEDState.IDLE) {
        if (DriverStation.isDisabled()) desiredState = LEDState.DISABLE;
        else if (DriverStation.isAutonomous()) desiredState = LEDState.AUTON;
        else desiredState = LEDState.TELEOP;
    }

    // 3. Only apply if the state actually changed
    if (desiredState != m_lastState) {
        applyState(desiredState);
        m_lastState = desiredState;
    }
}

 

  /**
   * Directly set the state of the LEDs.
   * @param state The target state
   */

  public void setState(LEDState state) {
    m_currentState = state;
        System.out.println(state);
        Timer.delay(0.1); // Small delay (in seconds) to prevent rapid state changes from causing issues with the LED controller
  }
  private void applyState(LEDState state) {
              System.out.println("ApplyState_"+ state);
              Timer.delay(0.1); // Small delay (in seconds) to prevent rapid state changes from causing issues with the LED controller
      switch (state) {
        
      case OFF:
        m_leds.leds.SetColor(GR_300, new Color(0, 0, 0));
        break;
        
      case IDLE:
        applyIdlePattern();
        break;
        
       case AIMED:
        m_leds.leds.SetAnimation(Animation.Fill)
            .ForGroup(GR_300)
            .WithColor(COLOR_RED)
            .WithDelay(Units.Milliseconds.of(50))
            .RunOnce(false);
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
      
      case DISABLE:
        m_leds.leds.SetAnimation(Animation.Confetti)
          .ForGroup(GR_300)
          .WithColor(COLOR_PURPLE)
          .WithDelay(Units.Milliseconds.of(10))
          .RunOnce(false);
        break;
      
      case AUTON:
         m_leds.leds.SetAnimation(Animation.Fill)//Auton should be Confettie fast
          .ForGroup(GR_300)
          .WithColor(COLOR_RED)
          .WithDelay(Units.Milliseconds.of(1))
          .Reverse(false)
          .RunOnce(false);
        break;
      case TELEOP:
        m_leds.leds.SetAnimation(Animation.Blink)
          .ForGroup(GR_300)
          .WithColor(COLOR_YELLOW)
          .WithDelay(Units.Milliseconds.of(200))  // Adjust speed here
          .RunOnce(false);
        break;
        

    }
  }

 private void applyIdlePattern() {
  if (DriverStation.isDisabled()) {
    // Disabled – turn LEDs off (or change if you prefer something else)
   setState(LEDState.DISABLE);
    
  } else if (DriverStation.isAutonomous()) {
    //  AUTON – Solid Red
   setState(LEDState.AUTON);

  } else if (DriverStation.isTeleop()) {
    //Teleop should be Fill solid blue
    setState(LEDState.TELEOP);
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
