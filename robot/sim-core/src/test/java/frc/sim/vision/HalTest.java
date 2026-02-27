package frc.sim.vision;

import edu.wpi.first.hal.HAL;
import org.junit.jupiter.api.Test;

class HalTest {
    @Test
    void testHalInit() {
        HAL.initialize(500, 0);
        System.out.println("HAL initialized OK");
    }
}
