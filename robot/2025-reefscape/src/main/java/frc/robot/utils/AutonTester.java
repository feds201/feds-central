package frc.robot.utils;

import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj2.command.Command;
import java.util.HashMap;
import java.util.Map;

/**
 * The AutonTester class is used to test autonomous commands by adding them to the Shuffleboard.
 */
public class AutonTester {
    private Map<String, Command> commandMap;

    /**
     * Constructs an AutonTester with a given array of command groups.
     * Each pair in the array consists of a label (String) and a command (Command).
     *
     * @param Group an array of objects where each pair consists of a label and a command.
     */
    public AutonTester(Object[] Group) {
        commandMap = new HashMap<>();
        for (int i = 0; i < Group.length; i += 2) {
            String label = Group[i].toString();
            Command command = (Command) Group[i + 1];
            commandMap.put(label, command);
            Shuffleboard.getTab("Auton Tester").add(label, command);
        }
    }

}