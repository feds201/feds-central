// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.subsystems;

import java.lang.ModuleLayer.Controller;
import com.lumynlabs.connection.usb.USBPort;
import com.lumynlabs.devices.ConnectorXAnimate;
import com.lumynlabs.domain.led.Animation;
import edu.wpi.first.hal.simulation.AnalogInDataJNI;
import edu.wpi.first.units.Units;
import edu.wpi.first.wpilibj.DriverStation;
import edu.wpi.first.wpilibj.RobotController;
import edu.wpi.first.wpilibj.util.Color;
import edu.wpi.first.wpilibj.util.Color8Bit;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.SubsystemBase;


public class LedsSubsystem extends SubsystemBase {
  public ConnectorXAnimate m_leds = new ConnectorXAnimate();
  private static LedsSubsystem instance;

  
  public static LedsSubsystem getInstance() { 
  if (instance == null) {
      instance = new LedsSubsystem();
    }
    return instance;
  }


  public enum LEDState {              
    FALCON_DRIVE,       // Flashing Orange at 200ms
    AIMED,             // When aimed should be fill solid Red
    SHOOTING,            // Shooting should be blue coment kinda fast
    CLIMBING,           // Rainbow         
    ERROR_LL,                //Error limelight should be blink Limelight green at 200ms
    ERROR_CAN,                //Error: CAN blink green and yellow at 400ms and should be altrnate
    ERROR_JAMMING,                //Error: jamming should be blink scarlett at 200ms
    ERROR_OTHER,
    IDLE,
    OFF;


               //Error: other should blink purple at 200ms
                    
  }

  private LEDState m_currentState = LEDState.IDLE;
  private LEDState m_lastState = LEDState.OFF; // Force initial update

  private boolean m_wasDisabled = false;
  private boolean m_wasAuto = false;

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
  private static final Color COLOR_GREEN = new Color(new Color8Bit(0, 255, 0));
  private static final Color COLOR_RED = new Color(new Color8Bit(255, 0, 0));
  private static final Color COLOR_WHITE = new Color(new Color8Bit(255, 255, 255));
  private static final Color COLOR_YELLOW = new Color(new Color8Bit(255, 255, 0));
  private static final Color COLOR_FEDS_BLUE = new Color(new Color8Bit(0, 168, 255)); // Team color

  /** Creates a new LedsSubsystem. */
  public LedsSubsystem() {
    // Connect to the device on USB port 2
    boolean connected = m_leds.Connect(USBPort.kUSB1);
    System.out.println("ConnectorX connected: " + connected);
    
    // Initial State application will happen in periodic loop or manually here
    // But periodic handles state change, so setting lastState to OFF calls applyState(IDLE) in first loop.
  }


  @Override
  public void periodic() {  
    // Handle IDLE state dynamic changes based on Robot Mode (Disabled/Enabled/Auto)
    if (m_currentState == LEDState.IDLE) {
      boolean isDisabled = DriverStation.isDisabled();
      boolean isAuto = DriverStation.isAutonomous();
      
      // If the robot mode changed, we need to re-apply the IDLE state to update the pattern
      if (isDisabled != m_wasDisabled || isAuto != m_wasAuto) {
        applyState(LEDState.IDLE);
        m_wasDisabled = isDisabled;
        m_wasAuto = isAuto;
      }
    }

    // Check if state requested changed explicitly
    if (m_currentState != m_lastState) {
      applyState(m_currentState);
      m_lastState = m_currentState;
    }
  }

 

  /**
   * Directly set the state of the LEDs.
   * @param state The target state
   */
  public void setState(LEDState state) {
    m_currentState = state;
  }

  private void applyState(LEDState state) {
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


      case SHOOTING:
        m_leds.leds.SetAnimation(Animation.Comet)
            .ForGroup(GR_300)
            .WithColor(COLOR_FEDS_BLUE)
            .WithDelay(Units.Milliseconds.of(20))
            .RunOnce(false);
        break;
        
      case CLIMBING:
        m_leds.leds.SetAnimation(Animation.RainbowRoll)
            .ForGroup(GR_300)
            .WithColor(COLOR_WHITE) // Color is ignored for Rainbow, but set it anyway
            .WithDelay(Units.Milliseconds.of(10))
            .Reverse(false)
            .RunOnce(false);
        break;
        
      // case ERROR:
      //     m_leds.leds.SetAnimation(Animation.Blink)
      //       .ForGroup(GR_300)
      //       .WithColor(COLOR_RED)
      //       .WithDelay(Units.Milliseconds.of(100))
      //       .RunOnce(false);
      //   break;
    }
  }

 private void applyIdlePattern() {
  if (DriverStation.isDisabled()) {
    // Disabled – turn LEDs off (or change if you prefer something else)
    m_leds.leds.SetAnimation(Animation.Confetti)
            .ForGroup(GR_300)
            .WithColor(COLOR_YELLOW)
            .WithDelay(Units.Milliseconds.of(10))
            .RunOnce(false);
    
  } else if (DriverStation.isAutonomous()) {
    //  AUTON – Solid Red
    m_leds.leds.SetAnimation(Animation.Fill)//Auton should be Confettie fast
      .ForGroup(GR_300)
      .WithColor(COLOR_RED)
      .WithDelay(Units.Milliseconds.of(1))
      .Reverse(false)
      .RunOnce(false);

  } else {
    //Teleop should be Fill solid blue
    m_leds.leds.SetAnimation(Animation.Blink)
      .ForGroup(GR_300)
      .WithColor(COLOR_YELLOW)
      .WithDelay(Units.Milliseconds.of(200))  // Adjust speed here
      .RunOnce(false);
  }
}
  public Command setStateCommand(LEDState state) {
    return runOnce(() -> setState(state)).ignoringDisable(true);
  }
  
  public Command runStateCommand(LEDState state) {
    return startEnd(
      () -> setState(state),
      () -> setState(LEDState.IDLE)
    ).ignoringDisable(true);
  }
  
  public Command tempStateCommand(LEDState state, double seconds) {
    return runStateCommand(state).withTimeout(seconds);
  }

  public Command shootingSignal() { return runStateCommand(LEDState.SHOOTING); }
  public Command climbingSignal() { return runStateCommand(LEDState.CLIMBING); }
 // public Command errorSignal() { return runStateCommand(LEDState.ERROR); }
  public Command resetLEDS() { return setStateCommand(LEDState.IDLE); }

  @Deprecated
  public Command setLEDState(LEDState state) {
      return setStateCommand(state);
  }


}
