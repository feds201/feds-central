package frc.robot.sim;

import com.lumynlabs.devices.ConnectorXAnimate;
import com.lumynlabs.domain.config.ConfigBuilder;
import com.lumynlabs.domain.config.LumynDeviceConfig;


import edu.wpi.first.wpilibj.RobotBase;

/**
 * Simulator helper for LEDs.
 */
public class LedsSim {
    
  private final ConnectorXAnimate m_leds;

  /**
   * Constructor for LedsSim.
   * Handles simulation-specific configuration if running in a simulation environment.
   * * @param leds The ConnectorXAnimate instance to be configured.
   */
  public LedsSim(ConnectorXAnimate leds) {
    this.m_leds = leds;

    if (RobotBase.isSimulation()) {
      m_leds.ApplyConfiguration(buildConfig());
      System.out.println("LedsSim constructed, applying config");
    }
  }

  public void update(double dt) { 
    // Logic for simulation-specific updates can be added here
  }

 private LumynDeviceConfig buildConfig() {
    return new ConfigBuilder()
        .forTeam("201")
        // Use "GR_300" here so it matches your LedsSubsystem constant
        .addChannel(1, "port1", 300)
            .addStripZone("GR_300", 300, false) 
        .endChannel()
        .build();
}
}