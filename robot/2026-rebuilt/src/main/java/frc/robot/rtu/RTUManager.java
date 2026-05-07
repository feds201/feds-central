package frc.robot.rtu;

import frc.robot.utils.RTU.RootTestingUtility;
import edu.wpi.first.wpilibj2.command.SubsystemBase;

/**
 * Thin wrapper around RootTestingUtility to separate RTU responsibilities
 * from RobotContainer and from simulation code.
 */
public class RTUManager {
    private final RootTestingUtility rootTester = new RootTestingUtility();

    public RTUManager() {}

    public void registerSubsystem(SubsystemBase... subsystems) {
        rootTester.registerSubsystem(subsystems);
    }

    public void setSafetyCheck(RootTestingUtility.SafetyCheck check) {
        rootTester.setSafetyCheck(check);
    }

    public void discoverActions() { rootTester.discoverActions(); }

    public void runAll() { rootTester.runAll(); }

    public void periodic() { rootTester.periodic(); }

    public java.util.List<?> getResults() { return rootTester.getResults(); }
}
