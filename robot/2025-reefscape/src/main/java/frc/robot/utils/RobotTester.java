package frc.robot.utils;

import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardTab;
import edu.wpi.first.wpilibj2.command.Command;

/**
 * Class for testing robot commands.
 */
public class RobotTester {
    /**
     * Constructor for RobotTester.
     * 
     * @param Group the group of commands to test.
     */
    public RobotTester(Object[] Group) {
        Shuffleboard.update();
        ShuffleboardTab tab = Shuffleboard.getTab(Subsystems.TESTER.getNetworkTable());
        for (int i = 0; i < Group.length; i += 2) {
            String label = Group[i].toString();
            Command command = (Command) Group[i + 1];
            tab.add(label, command);
        }
    }

}
