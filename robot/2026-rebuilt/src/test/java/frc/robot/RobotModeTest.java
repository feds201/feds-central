    package frc.robot;

    import edu.wpi.first.hal.HAL;
    import edu.wpi.first.wpilibj.simulation.DriverStationSim;
    import edu.wpi.first.wpilibj.simulation.RoboRioSim;
    import org.junit.jupiter.api.AfterEach;
    import org.junit.jupiter.api.BeforeEach;
    import org.junit.jupiter.api.Test;

    public class RobotModeTest {
        private Robot robot;

        @BeforeEach
        void setup() {
            // Initialize the HAL (Hardware Abstraction Layer) for headless simulation
            assert HAL.initialize(500, 0);
            robot = new Robot();
            robot.robotInit();
        }

        @AfterEach
        void teardown() {
            robot.close();
        }

        @Test
        void simulateMatchFlow() {
            // 1. Simulate Autonomous
            DriverStationSim.setAutonomous(true);
            DriverStationSim.setEnabled(true);
            DriverStationSim.notifyNewData();
            
            robot.autonomousInit();
            // Run a few simulated "loops" (20ms standard loop time)
            for (int i = 0; i < 50000; i++) {
                robot.robotPeriodic();
                robot.autonomousPeriodic();
            }

            // 2. Simulate TeleOp
            DriverStationSim.setAutonomous(false);
            DriverStationSim.setEnabled(true);
            DriverStationSim.notifyNewData();

            robot.teleopInit();
            for (int i = 0; i < 50000; i++) {
                robot.robotPeriodic();
                robot.teleopPeriodic();
            }

            // 3. Simulate Test Mode
            DriverStationSim.setTest(true);
            DriverStationSim.setEnabled(true);
            DriverStationSim.notifyNewData();

            robot.testInit();
            for (int i = 0; i < 50000; i++) {
                robot.robotPeriodic();
                robot.testPeriodic();
            }

            // If we reach this point without throwing an exception, the robot didn't crash!
        }
    }