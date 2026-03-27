


package frc.robot.sim;

import com.lumynlabs.connection.usb.USBPort;
import com.lumynlabs.devices.ConnectorXAnimate;
import com.lumynlabs.domain.config.ConfigBuilder;
import com.lumynlabs.domain.led.DirectLED;

import edu.wpi.first.wpilibj.AddressableLEDBuffer;
import edu.wpi.first.wpilibj.RobotBase;

/**
 * Simulator helper for LEDs.
 */
public class LedsSim {

  private final ConnectorXAnimate m_leds = new ConnectorXAnimate();
  private DirectLED m_directLed;
  private AddressableLEDBuffer m_directLedBuffer;
  private boolean m_directLedEnabled = false;

  public void robotInit() {
    m_leds.Connect(USBPort.kUSB1);
    if (RobotBase.isSimulation()) {
      m_leds.ApplyConfiguration(buildConfig());
    }
  }

  private com.lumynlabs.domain.config.LumynDeviceConfig buildConfig() {
    return new ConfigBuilder()
        .forTeam("201")
        
        // Channel 2 - port2_Intake
        .addChannel(2, "port2_Intake", 300)
            .addStripZone("ZONE_50_1", 50, false)
            .addStripZone("ZONE_50_2", 50, false)
            .addStripZone("ZONE_50_3", 50, false)
            .addStripZone("ZONE_50_4", 50, false)
            .addStripZone("ZONE_50_5", 50, false)
            .addStripZone("ZONE_50_6", 50, false)
        .endChannel()
        
        // Groups
        .addGroup("GR_300")
            .addZone("ZONE_50_1")
            .addZone("ZONE_50_2")
            .addZone("ZONE_50_3")
            .addZone("ZONE_50_4")
            .addZone("ZONE_50_5")
            .addZone("ZONE_50_6")
        .endGroup()

        .addGroup("GR_100")
            .addZone("ZONE_50_1")
            .addZone("ZONE_50_2")
        .endGroup()

        .addGroup("GR_100_2")
            .addZone("ZONE_50_3")
            .addZone("ZONE_50_4")
        .endGroup()

        .addGroup("GR_100_3")
            .addZone("ZONE_50_5")
            .addZone("ZONE_50_6")
        .endGroup()
        
        .build();
  }
}
