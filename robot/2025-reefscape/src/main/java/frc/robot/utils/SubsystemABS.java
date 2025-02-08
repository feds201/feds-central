package frc.robot.utils;

import edu.wpi.first.networktables.NetworkTable;
import edu.wpi.first.networktables.NetworkTableInstance;
import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardTab;
import edu.wpi.first.wpilibj2.command.SubsystemBase;

/**
 * Abstract class representing a robot subsystem.
 */
public abstract class SubsystemABS extends SubsystemBase {
    protected Subsystems part;
    protected ShuffleboardTab tab;
    protected NetworkTable ntTable;
    protected String tabName;
    protected Object instance;

    /**
     * Constructor for SubsystemABS.
     * 
     * @param part the subsystem part.
     * @param tabName the name of the shuffleboard tab.
     */
    public SubsystemABS(Subsystems part, String tabName) {
        this.tabName = tabName;
        this.part = part;
        try {
            this.tab = Shuffleboard.getTab(tabName);
        } catch (IllegalArgumentException e) {
            this.tab = Shuffleboard.getTab(tabName + " - New");
        };
        setupNetworkTables(part.toString());
        instance = this;
    }

    /**
     * Default constructor for SubsystemABS.
     */
    public SubsystemABS() {
    }

    /**
     * Gets the subsystem part.
     * 
     * @return the subsystem part.
     */
    public Subsystems getPart() {
        return part;
    }

    /**
     * Sets the subsystem part.
     * 
     * @param part the subsystem part.
     */
    public void setPart(Subsystems part) {
        this.part = part;
    }

    /**
     * Gets the shuffleboard tab.
     * 
     * @return the shuffleboard tab.
     */
    public ShuffleboardTab getTab() {
        return tab;
    }

    /**
     * Gets the instance of the subsystem.
     * 
     * @return the subsystem instance.
     */
    public Object getInstance() {
        return instance;
    }

    /**
     * Sets up the network tables for the subsystem.
     * 
     * @param part the subsystem part.
     */
    public void setupNetworkTables(String part) {
        ntTable = NetworkTableInstance.getDefault().getTable(part);
    }

    /**
     * Periodic method for the subsystem.
     */
    @Override
    public abstract void periodic();

    /**
     * Simulation periodic method for the subsystem.
     */
    @Override
    public abstract void simulationPeriodic();

    /**
     * Sets the default command for the subsystem.
     */
    public abstract void setDefaultCmd();

    /**
     * Checks if the subsystem is healthy.
     * 
     * @return true if the subsystem is healthy, false otherwise.
     */
    public abstract boolean isHealthy();

    /**
     * Executes the failsafe procedure for the subsystem.
     */
    public abstract void Failsafe();
}