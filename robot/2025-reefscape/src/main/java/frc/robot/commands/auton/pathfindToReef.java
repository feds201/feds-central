// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.commands.auton;

import com.pathplanner.lib.auto.AutoBuilder;
import com.pathplanner.lib.path.PathPlannerPath;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.Command;
import frc.robot.constants.RobotMap.SafetyMap.AutonConstraints;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.subsystems.vision.camera.Camera;
import frc.robot.utils.AutoPathFinder;
import frc.robot.utils.PathPair;

/* You should consider using the more terse Command factories API instead https://docs.wpilib.org/en/stable/docs/software/commandbased/organizing-command-based.html#defining-commands */
public class pathfindToReef extends Command {
  public enum reefPole {
    LEFT, RIGHT
  }
 
  private reefPole pole;
  private Camera limelight;
  private int tagId;
  private boolean commandFinished;
  private String pathName;
  private PathPlannerPath pathToReefPole;
  private Command reefPathCommand;
  private final PathPair[] paths = {
      // //Coral Stations
      // new PathPair(1, 13, "thispathwasntmadeyetdontrunthis",
      // "thispathwasntmadeyetdontrunthis"),
      // new PathPair(2, 12, "thispathwasntmadeyetdontrunthis",
      // "thispathwasntmadeyetdontrunthis"),
      // //Processor
      // new PathPair(3, 16, "thispathwasntmadeyetdontrunthis",
      // "thispathwasntmadeyetdontrunthis"),
      // //Net tags
      // new PathPair(4, 15, "thispathwasntmadeyetdontrunthis",
      // "thispathwasntmadeyetdontrunthis"),
      // new PathPair(5, 14, "thispathwasntmadeyetdontrunthis",
      // "thispathwasntmadeyetdontrunthis"),
      // Reef Paths
      new PathPair(6, 19, "66alignLeft", "66alignRight"),
      new PathPair(7, 18, "56alignLeft", "56alignRight"),
      new PathPair(8, 17, "46alignLeft", "46alignRight"),
      new PathPair(9, 22, "36alignLeft", "36alignRight"),
      new PathPair(10, 21, "26alignLeft", "26alignRight"),
      new PathPair(11, 20, "16alignLeft", "16alignRight")
  };


  public pathfindToReef(reefPole pole, CommandSwerveDrivetrain swerve, Camera camera) {
    this.pole = pole;
    limelight = camera;

    addRequirements(swerve);
    
  }

  // Called when the command is initially scheduled.
  @Override
  public void initialize() {
    tagId = limelight.GetAprilTag();
    tagId = 18;
    if (tagId == -1) {
      commandFinished = true;
    } else {

    switch (pole) {
      case LEFT:
        for (PathPair path : paths) {
          if (path.tagToPath(tagId)) {
            pathName = path.getLeftPath();
          }
        }
        break;
      case RIGHT:
        for (PathPair path : paths) {
          if (path.tagToPath(tagId)) {
            pathName = path.getRightPath();
          }
        }
        break;

    }

  
      pathToReefPole = AutoPathFinder.loadPath(pathName);
    reefPathCommand = AutoBuilder.pathfindThenFollowPath(pathToReefPole, AutonConstraints.kPathConstraints);
    reefPathCommand.schedule();
   
  }
  }

 

  // Called once the command ends or is interrupted.
  @Override
  public void end(boolean interrupted) {
  }

  // Returns true when the command should end.
  @Override
  public boolean isFinished() {
    return commandFinished || reefPathCommand.isFinished();
  }
}
