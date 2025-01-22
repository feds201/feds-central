package frc.robot.utils;

import java.io.IOException;

import org.json.simple.parser.ParseException;

import com.pathplanner.lib.auto.AutoBuilder;
import com.pathplanner.lib.path.PathPlannerPath;
import com.pathplanner.lib.util.FileVersionException;

import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.ParallelCommandGroup;
import frc.robot.constants.RobotMap.SafetyMap.AutonConstraints;

public class AutoPathFinder {

    public static Command GotoPath(String pathName) {
      
            try {
                return new ParallelCommandGroup(AutoBuilder.pathfindThenFollowPath(PathPlannerPath.fromPathFile(pathName), AutonConstraints.kPathConstraints));
            } catch (FileVersionException | IOException | ParseException e) {
                ElasticLib.sendNotification(new ElasticLib.Notification(ElasticLib.Notification.NotificationLevel.ERROR, "AutoPathFinder", "Error loading path: " + pathName));
                e.printStackTrace();
            }
        
       return null;
    }
}
