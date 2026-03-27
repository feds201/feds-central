// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.commands.swerve;

import static edu.wpi.first.units.Units.MetersPerSecond;
import static edu.wpi.first.units.Units.RadiansPerSecond;
import static edu.wpi.first.units.Units.RotationsPerSecond;

import org.littletonrobotics.junction.Logger;

import com.ctre.phoenix6.swerve.SwerveRequest;
import static edu.wpi.first.units.Units.DegreesPerSecond;
import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.filter.SlewRateLimiter;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
// import frc.robot.RobotMap.SafetyMap.SwerveConstants;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.utils.ShootOnTheMove;
import frc.robot.subsystems.swerve.generated.TunerConstants;

public class HubDrive extends Command {
 

  public static final double MAX_SPEED = TunerConstants.kSpeedAt12Volts.in(MetersPerSecond);
  public static final double MAX_ANGULAR_RATE = RotationsPerSecond.of(2).in(RadiansPerSecond);
  // PID tuned for smoother response (lower P, small I). Units: degrees.
  private static final PIDController hubRotPID = new PIDController(6.7, 0.00, 0.2);
  private CommandSwerveDrivetrain dt;
  private CommandXboxController controller;
  
  // Slew rate limiters to smooth joystick and rotation commands
  private final SlewRateLimiter xLimiter = new SlewRateLimiter(3.0); // m/s per second
  private final SlewRateLimiter yLimiter = new SlewRateLimiter(3.0); // m/s per second
  private final SlewRateLimiter rotLimiter = new SlewRateLimiter(2000.0); // deg/s per second

  private SwerveRequest.FieldCentric driveNormal;

  /** Command used to control swerve in teleop. */
  public HubDrive(CommandSwerveDrivetrain dt, CommandXboxController controller) {
    this.dt = dt;
    this.controller = controller;


    driveNormal = new SwerveRequest.FieldCentric()
    .withDeadband(MAX_SPEED*.07)
    .withRotationalDeadband(MAX_ANGULAR_RATE*.07);
    hubRotPID.enableContinuousInput(-180, 180);
  hubRotPID.setTolerance(3);
    
    addRequirements(this.dt);
  }

  // Called when the command is initially scheduled.
  @Override
  public void initialize() {
    hubRotPID.reset();
  }

  public static boolean pidAtSetpoint(){
    return hubRotPID.atSetpoint();
  }
  // Called every time the scheduler runs while the command is scheduled.
  @Override
  public void execute() {

    SmartDashboard.putData(hubRotPID);
    Logger.recordOutput("Robot/CTRERobotPose", dt.getState().Pose);
          // 3. Get current robot heading
          double robotHeading = dt.getState().Pose.getRotation().getDegrees();

          //2 Get theta to virtual goal (will be equivalent to angle to hub when stationary, but leads the target when moving)
          Double angleToGoal = ShootOnTheMove.calculateRobotHeading(dt.getState().Pose, dt.getState().Speeds).getDegrees();
         
          // 4. Calculate PID output (Rotational Speed)
          double rawRotationOutput = hubRotPID.calculate(robotHeading, angleToGoal);

          // Clamp rotation to robot's max angular rate (convert rad/s to deg/s)
          double maxAngularDegPerSec = Math.toDegrees(MAX_ANGULAR_RATE);
          double clampedRotation = Math.max(-maxAngularDegPerSec, Math.min(maxAngularDegPerSec, rawRotationOutput));

          // Smooth rotation command (limits how fast the commanded rotational rate can change)
          double smoothRotation = rotLimiter.calculate(clampedRotation);

          // Scale joystick velocities to robot MAX_SPEED and smooth them
          double targetVelX = -controller.getLeftY() * MAX_SPEED;
          double targetVelY = -controller.getLeftX() * MAX_SPEED;
          double smoothVelX = xLimiter.calculate(targetVelX);
          double smoothVelY = yLimiter.calculate(targetVelY);

          if(smoothRotation > 0){
            smoothRotation+= 20;
          } else {
            smoothRotation -= 20;
          }

          dt.setControl(driveNormal
              .withVelocityX(smoothVelX)
              .withVelocityY(smoothVelY)
              .withRotationalRate(DegreesPerSecond.of(smoothRotation)));

         Logger.recordOutput("angular velocity (deg/s)", smoothRotation);
         Logger.recordOutput("targetVelX", smoothVelX);
         Logger.recordOutput("targetVelY", smoothVelY);
         Logger.recordOutput("angular velocity (deg/Error", hubRotPID.getError());
          
    }
  
  @Override
  public void end(boolean interrupted) {
    dt.setControl(new SwerveRequest.Idle());
  }

  @Override
  public boolean isFinished() {
    return false;
  }

  /**
   * Normalize a degree measure from -180 to 180 deg to a cardinal direction
   * @param angleDegrees Angle measurement from -180 to 180 degrees
   * @return The Closest multiple of 90 degrees
   */
  public static double snapToCardinal(double angleDegrees) {
    if(angleDegrees >= -135 && angleDegrees < -45 ){
      return -90;
    } else if(angleDegrees >= -45 && angleDegrees < 45){
      return 0;
    } else if(angleDegrees >= 45 && angleDegrees < 135){
      return 90;
    } else {
      return 180;
    }
  }
}
