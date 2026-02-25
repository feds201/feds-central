package frc.robot.utils;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.BooleanSupplier;

import com.ctre.phoenix6.hardware.CANcoder;
import com.ctre.phoenix6.hardware.CANdi;
import com.ctre.phoenix6.hardware.CANrange;
import com.ctre.phoenix6.hardware.ParentDevice;
import com.ctre.phoenix6.hardware.Pigeon2;
import com.ctre.phoenix6.hardware.TalonFX;

import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardTab;
import edu.wpi.first.networktables.GenericEntry;

/**
 * - Register boolean suppliers with addSubsystemSafety(name, supplier)
 * - Call pollAll() from robotPeriodic() to update Shuffleboard and cached status
 */
public final class SubsystemStatusManager {
    private static final ShuffleboardTab tab = Shuffleboard.getTab("Status Manager");

    private static final Map<String, BooleanSupplier> suppliers = new LinkedHashMap<>();
    private static final Map<String, Boolean> lastStatus = new LinkedHashMap<>();
    private static final Map<String, GenericEntry> entries = new LinkedHashMap<>();

    private static List<CANrange> canRanges = new ArrayList<>();
    private static List<TalonFX> talons = new ArrayList<>();
    private static List<CANcoder> canCoders = new ArrayList<>();
    private static List<Pigeon2> pigeons = new ArrayList<>(); 
    private static List<CANdi> candis = new ArrayList<>(); 

    private SubsystemStatusManager() {}
    
    /**
     * Register a boolean supplier for a subsystem / device group.
     */
    public static synchronized void addSubsystem(String name, BooleanSupplier statusSupplier) {
        if (name == null || statusSupplier == null) {
            throw new IllegalArgumentException("name and statusSupplier must be non-null");
        }
        if (suppliers.containsKey(name)) {
            System.err.println("[SubsystemStatusManager] Warning: subsystem '" + name + "' already registered; ignoring duplicate.");
            return;
        }
        suppliers.put(name, statusSupplier);
        lastStatus.put(name, false); // default before first poll
        entries.put(name, tab.add(name, false).getEntry());
    }

     
     public static synchronized void addSubsystem(String name, ParentDevice... devices) {
        if (name == null || devices == null) {
            throw new IllegalArgumentException("name and devices must be non-null");
        }

        for(ParentDevice d : devices){
            if(d instanceof TalonFX) talons.add((TalonFX) d);
            else if(d instanceof CANrange) canRanges.add((CANrange) d);
            else if(d instanceof CANcoder) canCoders.add((CANcoder) d);
            else if(d instanceof Pigeon2) pigeons.add((Pigeon2) d);
            else if(d instanceof CANdi) candis.add((CANdi) d);
        }

        BooleanSupplier connectionSupplier = () -> {
            for (ParentDevice d : devices) {
                if (d != null){ 
                    if (!d.isConnected()) {
                        tab.addNumber(name + " Disconnect ID", ()-> d.getDeviceID());
                        return false;
                    }
                }
            }
            return true;
        };

        // Implementation Needed
        // BooleanSupplier tempSupplier = ()-> {
        //     for (TalonFX t : talons) {
        //         if(t != null){
        //             if(t.getDeviceTemp().getValueAsDouble() > 100){
        //                 return false;
        //             }
        //         }
        //     }
        //     return true;
        // };

        // delegate to the boolean-supplier registration
        addSubsystem(name, connectionSupplier);
    }

    /**
     * Poll all registered suppliers, update Shuffleboard and cached values.
     * Call this from Robot.robotPeriodic().
     */
    public static synchronized void pollAll() {
        for (Map.Entry<String, BooleanSupplier> e : suppliers.entrySet()) {
            final String name = e.getKey();
            boolean ok;
            try {
                ok = e.getValue().getAsBoolean();
            } catch (Throwable t) {
                ok = false;
                System.err.println("[SubsystemStatusManager] Exception while polling '" + name + "': " + t.getMessage());
            }
            lastStatus.put(name, ok);
            GenericEntry entry = entries.get(name);
            if (entry != null) entry.setBoolean(ok);
        }
    }


    /** Returns true if every registered subsystem's last known status is true. */
    public static synchronized boolean isAllOk() {
        for (Boolean val : lastStatus.values()) {
            if (!Boolean.TRUE.equals(val)) return false;
        }
        return true;
    }

    /** Clears all registrations */
    public static synchronized void clearAll() {
        suppliers.clear();
        lastStatus.clear();
        entries.clear();
    }
}
