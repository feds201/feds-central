package   frc.robot.commands.swerve;

import java.lang.reflect.Array;
import java.util.ArrayList;
import java.util.List;

import com.ctre.phoenix6.swerve.SwerveRequest;
import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Rectangle2d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.math.kinematics.ChassisSpeeds;
import edu.wpi.first.wpilibj2.command.Command;
import frc.robot.RobotMap.ShooterConstants;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.utils.LimelightHelpers;

public class BallTracking extends Command {
  private CommandSwerveDrivetrain dt;
  private final PIDController hubRotPID = new PIDController(0.1, 0, 0);
  private SwerveRequest.RobotCentric driveNormal;
  private double maxVelocity;
  private ArrayList<Double> tyHistory = new ArrayList<Double>(List.of(0.0, 0.0, 0.0, 0.0, 0.0));
  private double averageTy; 
  private boolean hasTarget;



  public BallTracking(CommandSwerveDrivetrain dt) {
    this.dt = dt;
    addRequirements(this.dt);
    driveNormal = new SwerveRequest.RobotCentric();
    hubRotPID.setTolerance(1.0);
    maxVelocity = 2; 
    }

      public boolean withinBlueAlliance()
    {
        Translation2d blueAllianceTranslation2d = new Pose2d(7.7, 7.5, new Rotation2d(0)).getTranslation();
        Rectangle2d blueRectangle2d = new Rectangle2d(blueAllianceTranslation2d, new Translation2d(0.72, 0.56));
        Pose2d robotPose = (dt.getState().Pose); 

          if (blueRectangle2d.contains(robotPose.getTranslation())) {
              return true;
    }

    else {
      return false;
    }
  }

   public boolean withinRedAlliance()
    {
        Translation2d redAllianceTranslation2d = new Pose2d(16.0, 7.5, new Rotation2d(0)).getTranslation();
        Rectangle2d redRectangle2d = new Rectangle2d(redAllianceTranslation2d, new Translation2d(9.0, 0.56));
        Pose2d robotPose = (dt.getState().Pose); 

          if (redRectangle2d.contains(robotPose.getTranslation())) {
              return true;
    }

    else {
      return false;
    }
  }

  public boolean withinTransition()
    {
        Translation2d TransitionTranslation2d = new Pose2d(8.0, 7.55, new Rotation2d(0)).getTranslation();
        Rectangle2d TransitionRectangle2d = new Rectangle2d(TransitionTranslation2d, new Translation2d(8.0, 0.5));
        Pose2d robotPose = (dt.getState().Pose); 

          if (TransitionRectangle2d.contains(robotPose.getTranslation())) {
              return true;
    }

    else {
      return false;
    }
  }


  // Called when the command is initially scheduled.
  @Override
  public void initialize() {
    hubRotPID.setSetpoint(0.0);
  }


   @Override
public void execute() {

  
      hasTarget = LimelightHelpers.getTV("limelight-one");

    if (withinBlueAlliance()){ 

      if (withinTransition()) {
        dt.setControl(driveNormal
            .withVelocityX(2.0)
            .withVelocityY(0)
            .withRotationalRate(3.2) //in radians per second
        );
      }

      if (hasTarget) {
      
        double tx = LimelightHelpers.getTX("limelight-one");
        double ty = LimelightHelpers.getTY("limelight-one");

        if (Math.abs(tx) < 1.5) {
          tx = 0.0;
        
        }

        double rotationOutput = -hubRotPID.calculate(tx);
        rotationOutput = Math.max(-2.0, Math.min(2.0, rotationOutput));

        
        double forwardVelocity = Math.abs((ty - 23) * 0.1);

        if (forwardVelocity >= maxVelocity){
          forwardVelocity = averageTy; 
        }

        if (ty > -5) {
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
            .withRotationalRate(3.2) //in radians per second
        );
    }
    }

    if (withinRedAlliance()) {
       if (withinTransition()) {
        dt.setControl(driveNormal
            .withVelocityX(3.0)
            .withVelocityY(0)
            .withRotationalRate(3.2) //in radians per second
        );
      }

      if (hasTarget) {
      
        double tx = LimelightHelpers.getTX("limelight-one");
        double ty = LimelightHelpers.getTY("limelight-one");

        if (Math.abs(tx) < 1.5) {
          tx = 0.0;
        
        }

        double rotationOutput = -hubRotPID.calculate(tx);
        rotationOutput = Math.max(-2.0, Math.min(2.0, rotationOutput));

        
        double forwardVelocity = Math.abs((ty - 23) * 0.1);

        if (forwardVelocity >= maxVelocity){
          forwardVelocity = averageTy; 
        }

        if (ty > -5) {
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
            .withRotationalRate(3.2) //in radians per second
        );
    }

    }

    
  }

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
  }

  // Returns true when the command should end.
  @Override
  public boolean isFinished() {
    return false;
  }

}





