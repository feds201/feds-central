// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.commands.auton;

import java.util.List;

import com.pathplanner.lib.auto.AutoBuilder;
import com.pathplanner.lib.path.PathPlannerPath;
import com.pathplanner.lib.util.FlippingUtil;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.wpilibj.DriverStation;
import edu.wpi.first.wpilibj.DriverStation.Alliance;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.Command;
import frc.robot.constants.RobotMap.AutonPosesMap;
import frc.robot.constants.RobotMap.BlueReefTagLocations;
import frc.robot.constants.RobotMap.RedReefTagLocations;
import frc.robot.constants.RobotMap.ReefCentersPoses;
import frc.robot.constants.RobotMap.SafetyMap.AutonConstraints;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.subsystems.vision.camera.Camera;
import frc.robot.utils.AprilTagPosePair;
import frc.robot.utils.AutoPathFinder;
import frc.robot.utils.DrivetrainConstants;
import frc.robot.utils.PathPair;
import frc.robot.utils.PosePair;

/* You should consider using the more terse Command factories API instead https://docs.wpilib.org/en/stable/docs/software/commandbased/organizing-command-based.html#defining-commands */
public class posePathfindToReef extends Command {
  public enum reefPole {
    LEFT, RIGHT, CENTER
  }
  private List<Pose2d> reefSideTagPoses;
  private reefPole pole;
  private Camera rightLimelight;
  private Camera leftLimelight;
  private int tagIdRight;
  private int tagIdLeft;
  private int tagIdFinal;
  private Pose2d tagPosefinal;
  private boolean commandFinished;
  private Pose2d poseName; //put in intitialize instead?
  private PathPlannerPath pathToReefPole;
  private Command reefPathCommand;
  private final PosePair[] poses = {
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
      new PosePair(6, 19, AutonPosesMap.left66, AutonPosesMap.right66),
      new PosePair(7, 18, AutonPosesMap.left56, AutonPosesMap.right56),
      new PosePair(8, 17, AutonPosesMap.left46, AutonPosesMap.right46),
      new PosePair(9, 22, AutonPosesMap.left36, AutonPosesMap.right36),
      new PosePair(10, 21, AutonPosesMap.left26, AutonPosesMap.right26),
      new PosePair(11, 20, AutonPosesMap.left16, AutonPosesMap.right16)
  };

  private final AprilTagPosePair[] aprilTagPoses = {
    new AprilTagPosePair(RedReefTagLocations.id1026, BlueReefTagLocations.id2126, AutonPosesMap.left26, AutonPosesMap.right26, ReefCentersPoses.center26),
    new AprilTagPosePair(RedReefTagLocations.id1116, BlueReefTagLocations.id2016, AutonPosesMap.left16, AutonPosesMap.right16, ReefCentersPoses.center16),
    new AprilTagPosePair(RedReefTagLocations.id936, BlueReefTagLocations.id2236, AutonPosesMap.left36, AutonPosesMap.right36, ReefCentersPoses.center36),
    new AprilTagPosePair(RedReefTagLocations.id846, BlueReefTagLocations.id1746, AutonPosesMap.left46, AutonPosesMap.right46, ReefCentersPoses.center46),
    new AprilTagPosePair(RedReefTagLocations.id756, BlueReefTagLocations.id1856, AutonPosesMap.left56, AutonPosesMap.right56, ReefCentersPoses.center56),
    new AprilTagPosePair(RedReefTagLocations.id666, BlueReefTagLocations.id1966, AutonPosesMap.left66, AutonPosesMap.right66, ReefCentersPoses.center66)
  };


  public posePathfindToReef(reefPole pole, CommandSwerveDrivetrain swerve, Camera rightCamera, Camera leftCamera) {
    this.pole = pole;
    rightLimelight = rightCamera;
    leftLimelight = leftCamera;
    addRequirements(swerve);

    

  }

  // Called when the command is initially scheduled.
  @Override
  public void initialize() {
    if(DriverStation.getAlliance().orElse(Alliance.Blue) == Alliance.Red){
      reefSideTagPoses = RedReefTagLocations.REDREEFTAGS;
    } else {
      reefSideTagPoses = BlueReefTagLocations.BLUEREEFTAGS;
    }
    // tagIdRight = rightLimelight.GetAprilTag();
    // tagIdLeft = leftLimelight.GetAprilTag();

    // if (tagIdLeft == tagIdRight) {
    //   tagIdFinal = tagIdLeft;

    // } else if (tagIdRight != -1) {
    //   tagIdFinal = tagIdRight;

    // } else if (tagIdLeft != -1){
    //   tagIdFinal = tagIdLeft;

    // } else {
    //   tagIdFinal = -1;
    // }
    // tagIdFinal = 18;
   
    

    tagPosefinal = DrivetrainConstants.drivetrain.getState().Pose.nearest(reefSideTagPoses);

    if (tagPosefinal == null) {
      commandFinished = true;
    } else {

    switch (pole) {
      case LEFT:
        for (AprilTagPosePair pose : aprilTagPoses) {
          if (pose.poseToPath(tagPosefinal)) {
            poseName = pose.getLeftPath();
          }
        }
        break;
      case RIGHT:
        for (AprilTagPosePair pose : aprilTagPoses) {
          if (pose.poseToPath(tagPosefinal)) {
            poseName = pose.getRightPath();
          }
        }
        break;
      case CENTER:
        for (AprilTagPosePair pose : aprilTagPoses) {
          if (pose.poseToPath(tagPosefinal)) {
            poseName = pose.getCenterPath();
          }
        }
    }
      
    if(poseName != null){
     if(DriverStation.getAlliance().orElse(Alliance.Blue) == Alliance.Red){
      poseName = FlippingUtil.flipFieldPose(poseName);
     }
    reefPathCommand = AutoBuilder.pathfindToPose(poseName, AutonConstraints.kPathConstraints, 0);
    
    }
  }
  }
 @Override
 public void execute(){
  if (reefPathCommand != null){
    reefPathCommand.schedule();
  }

  commandFinished = true;
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
