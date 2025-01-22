/*
 * *****************************************************************************
 *  * Copyright (c) 2024 FEDS 201. All rights reserved.
 *  *
 *  * This codebase is the property of FEDS 201 Robotics Team.
 *  * Unauthorized copying, reproduction, or distribution of this code, or any
 *  * portion thereof, is strictly prohibited.
 *  *
 *  * This code is provided "as is" and without any express or implied warranties,
 *  * including, without limitation, the implied warranties of merchantability
 *  * and fitness for a particular purpose.
 *  *
 *  * For inquiries or permissions regarding the use of this code, please contact
 *  * feds201@gmail.com
 *  ****************************************************************************
 *
 */

package frc.robot.utils;

import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardTab;
import edu.wpi.first.wpilibj2.command.Command;

/**
 * Abstract class representing the Vision subsystem.
 */
public abstract class VisionABC extends SubsystemABS {

  protected ShuffleboardTab tab;

  /**
   * Constructor for VisionABC.
   */
  public VisionABC(Subsystems part, String tabName) {
    super(Subsystems.VISION, "Vision");
    tab = getTab();
  }

  /**
   * Checks if a target is detected.
   * 
   * @return true if a target is detected, false otherwise.
   */
  public abstract boolean CheckTarget();

  /**
   * Gets the target position.
   * 
   * @param object the vision object.
   * @return the target position as a Translation2d.
   */
  public abstract Translation2d GetTarget(VisionObject object);

  /**
   * Sets the vision pipeline.
   * 
   * @param pipeline the pipeline number.
   */
  public abstract void setPipeline(int pipeline);

  /**
   * Sets the LED mode.
   * 
   * @param mode the LED mode.
   */
  public abstract void setLEDMode(int mode);

  /**
   * Sets the camera mode.
   * 
   * @param mode the camera mode.
   */
  public abstract void setCamMode(int mode);

  /**
   * Blinks the LED.
   * 
   * @return the command to blink the LED.
   */
  public abstract Command BlinkLED();

  /**
   * Turns off the LED.
   * 
   * @return the command to turn off the LED.
   */
  public abstract Command TurnOffLED();

  @Override
  public abstract void simulationPeriodic();

  /**
   * Indicates if the vision system is enabled.
   */
  public Boolean enabled;
}
