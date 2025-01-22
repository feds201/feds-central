// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of the
// WPILib BSD license file in the root directory of this project.

package frc.robot.commands.swerve;



import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.ParallelCommandGroup;
import frc.robot.utils.AutoPathFinder;
import frc.robot.utils.PathPair;

public class GameNavigator extends AutoPathFinder {
  private static final PathPair[] PATHS = {
      new PathPair(0, 1, "1pathleft", "1pathright"),
      new PathPair(2, 3, "3pathleft", "3pathright"),
      new PathPair(4, 5, "5pathleft", "5pathright"),
      new PathPair(6, 7, "7pathleft", "7pathright"),
      new PathPair(8, 9, "9pathleft", "9pathright"),
      new PathPair(10, 11, "11pathleft", "11pathright"),
  };

  public static Command GoLeft(int TagID) {
    if (TagID == -1) {
      return new ParallelCommandGroup();
      //return null;
      /* returning null causes an error, */
    }

    for (PathPair path : PATHS) {
      if (path.tagToPath(TagID)) {

        return new ParallelCommandGroup(GotoPath(path.getLeftPath()));
      }

    }
    return new ParallelCommandGroup();
    //return null;
    /* returning null causes an error, */
  }

  public static Command GoRight(int TagID) {
    if (TagID == -1) {
      return new ParallelCommandGroup();
    }

    for (PathPair path : PATHS) {
      if (path.tagToPath(TagID)) {

        return new ParallelCommandGroup(GotoPath(path.getRightPath()));
      }

    }
    return new ParallelCommandGroup();
    //return null;
    /* returning null causes an error, */
  }
}
