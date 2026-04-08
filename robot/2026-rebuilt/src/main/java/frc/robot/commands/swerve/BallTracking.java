package frc.robot.commands.swerve;

import com.ctre.phoenix6.swerve.SwerveRequest;
import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.wpilibj2.command.Command;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.utils.LimelightHelpers;

public class BallTracking extends Command {
  private CommandSwerveDrivetrain dt;
  private final PIDController hubRotPID = new PIDController(0.1, 0, 0);
  private SwerveRequest.RobotCentric driveNormal;
  private ObjectDetectionState objectDetectionState = ObjectDetectionState.OFF;

public enum ObjectDetectionState {
    ON, 
    OFF
}
  public BallTracking(CommandSwerveDrivetrain dt) {
    this.dt = dt;
    addRequirements(this.dt);
    driveNormal = new SwerveRequest.RobotCentric();

    hubRotPID.setTolerance(1.0);
  }

 

  // Called when the command is initially scheduled.
  @Override
  public void initialize() {
    hubRotPID.setSetpoint(0.0);
  }


   @Override
public void execute() {
    boolean hasTarget = LimelightHelpers.getTV("limelight-one");


    switch (objectDetectionState) {
        case ON -> {
            if (hasTarget) {
                double tx = LimelightHelpers.getTX("limelight-one");
                double ty = LimelightHelpers.getTY("limelight-one");

                if (Math.abs(tx) < 1.5) tx = 0.0;

                double rotationOutput = -hubRotPID.calculate(tx);
                rotationOutput = Math.max(-2.0, Math.min(2.0, rotationOutput));

                
                double forwardVelocity = Math.abs((ty - 20) * 0.10);

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
        case OFF -> {
            dt.setControl(driveNormal
                    .withVelocityX(0)
                    .withVelocityY(0)
                    .withRotationalRate(0) 
                );
        }
    }

}

  @Override
  public void end(boolean interrupted) {
  }

 
  @Override
  public boolean isFinished() {
    return false;
  }



  public Command setObjectDetectionStateCommand(ObjectDetectionState on) {
    // TODO Auto-generated method stub
    throw new UnsupportedOperationException("Unimplemented method 'setObjectDetectionStateCommand'");
  }
}

