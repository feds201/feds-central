package frc.robot.utils;

import static edu.wpi.first.units.Units.Fahrenheit;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.function.Supplier;

import com.ctre.phoenix6.hardware.TalonFX;

import edu.wpi.first.networktables.GenericEntry;
import edu.wpi.first.units.measure.Temperature;
import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardTab;

public class DeviceTempReporter {
    private static final ShuffleboardTab tab = Shuffleboard.getTab("Device Temp Reporter");
    private static final Map<String, Supplier<Temperature>> deviceTempSuppliers = new LinkedHashMap<>();
    private static final Map<String, GenericEntry> deviceTempEntries = new LinkedHashMap<>();


    private DeviceTempReporter(){
    }

    public static synchronized void addDevices(TalonFX... talons){
        if (talons == null) {
            throw new IllegalArgumentException("talons must be non-null");
        }
        String id;
        Supplier<Temperature> supplier;
        for(TalonFX t: talons){
            id = Integer.toString(t.getDeviceID());
            supplier = ()-> t.getDeviceTemp().getValue();
            deviceTempSuppliers.put(id, supplier);
            deviceTempEntries.put(id, tab.add(id, -1).getEntry()); //Initial before polling
        }
    }

    /**
     * Method used to manually add individual devices (Recommended for non-CTRE devices such as limelights)
     * @param id String identifier for the device
     * @param temSupplier supplier to supply the temperature of the device
     */
    public static synchronized void addDevice(String id, Supplier<Temperature> tempSupplier){
        if (id == null || tempSupplier == null) {
            throw new IllegalArgumentException("id and tempSupplier must be non-null");
        }

        deviceTempSuppliers.put(id, tempSupplier);
        deviceTempEntries.put(id, tab.add(id, -1).getEntry()); //Initial before polling
    }

    /**
     * Call this method from robotPeriodic() to update device temperatures
     */
    public static synchronized void pollAll() {
        for (Map.Entry<String, Supplier<Temperature>> e : deviceTempSuppliers.entrySet()) {
            final String name = e.getKey();
            Temperature temp;
            try {
                temp = e.getValue().get();
            } catch (Throwable t) {
                temp = Fahrenheit.of(-1);
                System.err.println("[DeviceTempReporter] Exception while polling '" + name + "': " + t.getMessage());
            }
            GenericEntry entry = deviceTempEntries.get(name);
            if (entry != null) entry.setValue(temp.in(Fahrenheit));
        }
    }
}
