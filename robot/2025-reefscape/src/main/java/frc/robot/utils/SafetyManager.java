package frc.robot.utils;

import edu.wpi.first.wpilibj.DriverStation;
import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardTab;
import edu.wpi.first.wpilibj.shuffleboard.SimpleWidget;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import java.util.HashMap;
import java.util.Map;

/**
 * Class for managing the safety of robot subsystems.
 */
public class SafetyManager extends SubsystemBase {
    private static ShuffleboardTab safetyTab;
    private static Map<SubsystemABS, SimpleWidget> subsystemWidgets = new HashMap<>();
    /**
     * Constructor for SafetyManager.
     * 
     * @param subsystems the subsystems to manage.
     */
    public SafetyManager(SubsystemABS... subsystems) {
        init();
        for (SubsystemABS subsystem : subsystems) {
            subsystemWidgets.put(subsystem, safetyTab.add(subsystem.getName(), subsystem.isHealthy()));
        }
        for (SubsystemABS subsystem : subsystemWidgets.keySet()) {
            if (subsystem.isHealthy()) {
                ElasticLib.Notification notification = new ElasticLib.Notification(ElasticLib.Notification.NotificationLevel.INFO, subsystem.getName(), subsystem.getName() + " is healthy");
                ElasticLib.sendNotification(notification);
            }
        }
    }

    /**
     * Initializes the safety manager.
     */
    public static void init() {
        safetyTab = Shuffleboard.getTab("Safety");
    }

    /**
     * Periodic method for the safety manager.
     */
    @Override
    public void periodic() {
        checkSubsystems();
        reportSubsystemStatus();
    }

    /**
     * Checks the health of the subsystems.
     */
    public static void checkSubsystems() {
        for (SubsystemABS subsystem : subsystemWidgets.keySet()) {
            subsystemWidgets.get(subsystem).getEntry().setBoolean(subsystem.isHealthy());
        }
    }

    /**
     * Reports the status of the subsystems.
     */
    private void reportSubsystemStatus() {
        for (SubsystemABS subsystem : subsystemWidgets.keySet()) {
            if (!subsystem.isHealthy()) {
                System.out.println(subsystem.getName() + " is not healthy" + " at " + System.currentTimeMillis());

                DriverStation.reportError(subsystem.getName() + " is not healthy", false);
                subsystem.Failsafe();
            }
        }
    }
}