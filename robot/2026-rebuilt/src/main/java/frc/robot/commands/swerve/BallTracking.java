package frc.robot.commands.swerve;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

import com.ctre.phoenix6.swerve.SwerveRequest;
import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Rectangle2d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.Commands;
import org.littletonrobotics.junction.Logger;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.utils.LimelightHelpers;

public class BallTracking extends Command {
  // True while any BallTracking command is scheduled. Read by the sim to gate
  // vision work (the fuel-detection frustum test is only useful when tracking).
  private static final AtomicBoolean ACTIVE = new AtomicBoolean(false);
  public static boolean isActive() { return ACTIVE.get(); }

  private CommandSwerveDrivetrain dt;
  private SwerveRequest.RobotCentric driveNormal;
  private double maxVelocity;
  private ArrayList<Double> tyHistory = new ArrayList<Double>(List.of(0.0, 0.0, 0.0, 0.0, 0.0));
  private double averageTy; 
  private boolean hasTarget;
  private BallTrackingState state;
  private final PIDController hubRotPID = new PIDController(0.1, 0, 0);
  private final double velocityCapX = 3.0; // velocity that robot will move when fuel is detected, max velocity when detected 
  private final double rotationalRate = 3.2; // amount of rotation the robot preforms when searching for fuel, in radians per second
  private final double tyOffset = 23.0; // used to scale foward velocity based on ty  
  private final double tyCutOff = -15.0; // limit to ty, if ty is less then num robot will stop and look for ball
  private final double txDeadband = 1.5; // tx for which robot will stop (when robot is too close)

  public enum BallTrackingState { 
    ON, 
    OFF
  }

  public BallTracking(CommandSwerveDrivetrain dt) {
    this.dt = dt;
    addRequirements(this.dt);
    driveNormal = new SwerveRequest.RobotCentric();
    hubRotPID.setTolerance(1.0);
    maxVelocity = 2; 
    state = BallTrackingState.ON; 
  }

  public void setState(BallTrackingState newState) {
    this.state = newState;
  }
        
  public Command setStateCommand(BallTrackingState targState) {
    return Commands.runOnce(() -> setState(targState));
  }

  // TODO: never called. Either wire into execute() for alliance-aware behavior or delete.
  public boolean withinBlueAlliance() {
    Translation2d blueAllianceTranslation2d = new Pose2d(7.7, 7.5, new Rotation2d(0)).getTranslation();
    Rectangle2d blueRectangle2d = new Rectangle2d(blueAllianceTranslation2d, new Translation2d(0.72, 0.56));
    Pose2d robotPose = (dt.getState().Pose); 

    if (blueRectangle2d.contains(robotPose.getTranslation())) {
      return true;
    } else {
      return false;
    }
  }

  // TODO: never called. Also the rectangle width is 9.0, probably meant 0.72 to match blue.
  public boolean withinRedAlliance() {
    Translation2d redAllianceTranslation2d = new Pose2d(16.0, 7.5, new Rotation2d(0)).getTranslation();
    Rectangle2d redRectangle2d = new Rectangle2d(redAllianceTranslation2d, new Translation2d(9.0, 0.56));
    Pose2d robotPose = (dt.getState().Pose); 

    if (redRectangle2d.contains(robotPose.getTranslation())) {
      return true;
    } else {
      return false;
    }
  }

  // TODO: only called inside the unreachable if(false) block. Either wire in or delete.
  public boolean withinTransition() {
    Translation2d TransitionTranslation2d = new Pose2d(8.0, 7.55, new Rotation2d(0)).getTranslation();
    Rectangle2d TransitionRectangle2d = new Rectangle2d(TransitionTranslation2d, new Translation2d(8.0, 0.5));
    Pose2d robotPose = (dt.getState().Pose); 

    if (TransitionRectangle2d.contains(robotPose.getTranslation())) {
      return true;
    } else {
      return false;
    }
  }

  // Called when the command is initially scheduled.
  @Override
  public void initialize() {
    hubRotPID.setSetpoint(0.0);
    state = BallTrackingState.ON;
    ACTIVE.set(true);
    Logger.recordOutput("Robot/Intake/BallFinder/Active", true);
  }

  @Override
  public void execute() {
    hasTarget = LimelightHelpers.getTV("limelight-one");
    Logger.recordOutput("Robot/Intake/BallFinder/HasTarget", hasTarget);
    Logger.recordOutput("Robot/Intake/BallFinder/State", state.toString());

    if (state == BallTrackingState.OFF) {
      dt.setControl(driveNormal
          .withVelocityX(0)
          .withVelocityY(0)
          .withRotationalRate(0)
      );
      Logger.recordOutput("Robot/Intake/BallFinder/CommandedVx", 0.0);
      Logger.recordOutput("Robot/Intake/BallFinder/CommandedRotRate", 0.0);
      return;
    }

    // TODO: pick one approach and delete the other. Currently the if(false) block
    //   below is unreachable, and this if(true) block is a "drive backward until
    //   target" crawl. Probably also want to wire in withinRed/Blue/Transition.
    if (true) {
      // if (withinTransition()) {
      //   dt.setControl(driveNormal
      //       .withVelocityX(velocityCapX)
      //       .withVelocityY(0)
      //       .withRotationalRate(rotationalRate) 
      //   );
      // }

      if (hasTarget) {
        double tx = LimelightHelpers.getTX("limelight-one");
        double ty = LimelightHelpers.getTY("limelight-one");

        Logger.recordOutput("Robot/Intake/BallFinder/InDeadband", Math.abs(tx) < txDeadband);
        if (Math.abs(tx) < txDeadband) {
          tx = 0.0;
        }
        Logger.recordOutput("Robot/Intake/BallFinder/HubRotPIDError", tx);

        double rotationOutput = -hubRotPID.calculate(tx);
        rotationOutput = Math.max(-2.0, Math.min(2.0, rotationOutput));
        Logger.recordOutput("Robot/Intake/BallFinder/HubRotPIDOutput", rotationOutput);

        // TODO: forwardVelocity is hardcoded to a backward crawl. The commented
        //   formula was ty-scaled. Decide which, and drop the dead maxVelocity check below.
        double forwardVelocity = -1.2; //Math.abs((ty - tyOffset) * 0.1);

        if (forwardVelocity >= maxVelocity){
          forwardVelocity = averageTy; 
        }

        if (ty > tyCutOff) {
          dt.setControl(driveNormal
              .withVelocityX(forwardVelocity)
              .withVelocityY(0)
              .withRotationalRate(rotationOutput)
          );
          Logger.recordOutput("Robot/Intake/BallFinder/CommandedVx", forwardVelocity);
          Logger.recordOutput("Robot/Intake/BallFinder/CommandedRotRate", rotationOutput);
        }
        // TODO: if ty <= tyCutOff and we still have a target, we issue no drive
        //   command and the robot coasts on the last one. Add an explicit stop.
      } else {
        dt.setControl(driveNormal
            .withVelocityX(0)
            .withVelocityY(0)
            .withRotationalRate(rotationalRate)
        );
        Logger.recordOutput("Robot/Intake/BallFinder/CommandedVx", 0.0);
        Logger.recordOutput("Robot/Intake/BallFinder/CommandedRotRate", rotationalRate);
      }
    }

    if (false) {
      if (withinTransition()) {
        dt.setControl(driveNormal
            .withVelocityX(velocityCapX)
            .withVelocityY(0)
            .withRotationalRate(rotationalRate) 
        );
      }

      if (hasTarget) {
        double tx = LimelightHelpers.getTX("limelight-one");
        double ty = LimelightHelpers.getTY("limelight-one");

        if (Math.abs(tx) < txDeadband) {
          tx = 0.0;
        }

        double rotationOutput = -hubRotPID.calculate(tx);
        rotationOutput = Math.max(-2.0, Math.min(2.0, rotationOutput));

        double forwardVelocity = Math.abs((ty - tyOffset) * 0.1);

        if (forwardVelocity >= maxVelocity){
          forwardVelocity = averageTy; 
        }

        if (ty > tyCutOff) {
          dt.setControl(driveNormal
              .withVelocityX(forwardVelocity)
              .withVelocityY(0)
              .withRotationalRate(rotationOutput)
          );
        }
      } else {
          dt.setControl(driveNormal
              .withVelocityX(0)
              .withVelocityY(0)
              .withRotationalRate(rotationalRate) 
          );
      }
    }
  }

  // TODO: never called. If you wire it up, two bugs: nothing ever appends to
  //   tyHistory, and averageTy uses += without resetting so it drifts over time.
  public void AverageTy() {
    if (hasTarget) {
      if (tyHistory.size() > 5) {
        tyHistory.remove(0);
      }

      if (tyHistory.size() == 5) {
        for (int i = 0; i < (tyHistory.size()); i++) {
          averageTy += tyHistory.get(i);
        }
        averageTy /= tyHistory.size();
          
      } 
    }
  }

  // Called once the command ends or is interrupted.
  @Override
  public void end(boolean interrupted) {
    state = BallTrackingState.OFF;
    ACTIVE.set(false);
    Logger.recordOutput("Robot/Intake/BallFinder/Active", false);
  }

  // Returns true when the command should end.
  @Override
  public boolean isFinished() {
    return false;
  }

}
