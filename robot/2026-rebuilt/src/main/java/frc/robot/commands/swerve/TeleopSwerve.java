// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.commands.swerve;

import static edu.wpi.first.units.Units.Degrees;
import static edu.wpi.first.units.Units.MetersPerSecond;
import static edu.wpi.first.units.Units.Radians;
import static edu.wpi.first.units.Units.RadiansPerSecond;
import static edu.wpi.first.units.Units.Rotations;
import static edu.wpi.first.units.Units.RotationsPerSecond;
import static edu.wpi.first.units.Units.Seconds;

import org.littletonrobotics.junction.Logger;

import com.ctre.phoenix6.swerve.SwerveRequest;
import static edu.wpi.first.units.Units.DegreesPerSecond;
import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.networktables.GenericEntry;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.AngularVelocity;
import edu.wpi.first.units.measure.Time;
import edu.wpi.first.wpilibj.Timer;
import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardTab;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.InstantCommand;
import edu.wpi.first.wpilibj2.command.RunCommand;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
// import frc.robot.RobotMap.SafetyMap.SwerveConstants;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.utils.ShootOnTheMove;
import frc.robot.subsystems.swerve.generated.TunerConstants;

public class TeleopSwerve extends Command {
  public enum driveMode{
    FALCONDRIVE,
    NORMALDRIVE,
    HUBDRIVE;
  }

  public static final double MAX_SPEED = TunerConstants.kSpeedAt12Volts.in(MetersPerSecond);
  public static final double MAX_ANGULAR_RATE = RotationsPerSecond.of(2).in(RadiansPerSecond);
private final PIDController hubRotPID = new PIDController(25, 0, 0);
  private CommandSwerveDrivetrain dt;
  private CommandXboxController controller;
  
  private SwerveRequest.FieldCentric driveNormal;

  private SwerveRequest.FieldCentric falconDrive;

  private GenericEntry swerveCommandEntry;
  private String swerveCommandType = "NORMAL";
  private final ShuffleboardTab tab = Shuffleboard.getTab(getName());

   // Stores the joystick's angle from the previous loop cycle to calculate its speed
   private Angle previousJoystickAngle = Rotations.of(0); 
   // A timestamp from the last time the angle was updated, for a more accurate velocity calculation
   private Time lastAngleTimestamp = Seconds.of(0);
   private Rotation2d lastTargetDirection = Rotation2d.fromDegrees(0);
   private Rotation2d currentRotation;
   private Time currentTime;
   private Time deltaTime;
   private Angle currentJoystickAngle = Degrees.of(0);

   private driveMode mode = driveMode.NORMALDRIVE;

  /** Command used to control swerve in teleop. */
  public TeleopSwerve(CommandSwerveDrivetrain dt, CommandXboxController controller) {
    this.dt = dt;
    this.controller = controller;

    currentRotation = dt.getState().Pose.getRotation();

    driveNormal = new SwerveRequest.FieldCentric()
    .withDeadband(MAX_SPEED*.07)
    .withRotationalDeadband(MAX_ANGULAR_RATE*.07);
    hubRotPID.enableContinuousInput(-180, 180);
    falconDrive = new SwerveRequest.FieldCentric()
    .withDeadband(MAX_SPEED*0.07)
    .withRotationalDeadband(0);

    swerveCommandEntry= tab.add("Swerve Command Status", swerveCommandType).getEntry();
    tab.addDouble("Controller Pointing Angle", ()-> -(Math.atan2(controller.getRightX(), -controller.getRightY())/ (2*Math.PI) * 360));
    tab.addDouble("Snapped Controller Pointing angle", ()-> currentJoystickAngle.in(Degrees));
    addRequirements(this.dt);
    controller.povLeft()
            .toggleOnTrue(new InstantCommand(()-> mode = driveMode.FALCONDRIVE)
                          .andThen(new RunCommand(()->{}))
                          .finallyDo(()-> mode = driveMode.NORMALDRIVE));
  }

  // Called when the command is initially scheduled.
  @Override
  public void initialize() {
    
  }

  // Called every time the scheduler runs while the command is scheduled.
  @Override
  public void execute() {
    Logger.recordOutput("CTRERobotPose", dt.getState().Pose);
    switch (mode) {
      case FALCONDRIVE:
      
        double rightX = controller.getRightX();
        double rightY = -controller.getRightY();

        if (Math.hypot(rightX, rightY) > 0.7) { // Deadband check
            
            // 1. Calculate current angle
            currentJoystickAngle = Radians.of(-Math.atan2(rightX, rightY));
            currentJoystickAngle = Degrees.of(snapToCardinal(currentJoystickAngle.in(Degrees)));
            
            // 2. Calculate joystick's angular velocity
            currentTime = Seconds.of(Timer.getFPGATimestamp());
            deltaTime = currentTime.minus(lastAngleTimestamp);
            
            // To avoid division by zero on the first run
            if (deltaTime.isEquivalent(Seconds.of(0))) {
                deltaTime = Seconds.of(0.02); // Assume a 50Hz loop rate initially
            }

            // Find the shortest angle difference to handle the 180 -> -180 degree wrap-around
            Angle angleDifference = currentJoystickAngle.minus(previousJoystickAngle);

            AngularVelocity joystickAngularVelocity = angleDifference.div(deltaTime); // degrees per second

            // 3. Calculate the "lead" angle based on velocity
            // This is the amount predicted ahead. The faster the stick moves, the more we lead.
            Angle leadAngle = joystickAngularVelocity.times(Seconds.of(.05));

            // 4. Apply the prediction
            // The final target is the snapped angle plus the predictive lead
            Angle finalTargetAngle = currentJoystickAngle.plus(leadAngle);

            lastTargetDirection = new Rotation2d(finalTargetAngle);
            // --- PREDICTION LOGIC END ---

            // Update state for the next loop
            previousJoystickAngle = currentJoystickAngle;
            lastAngleTimestamp = currentTime;
        }
        
        currentRotation = dt.getState().Pose.getRotation();
        Angle errorRad = lastTargetDirection.minus(currentRotation).getMeasure();
        AngularVelocity rotationalRateRadPerSec = errorRad.div(Seconds.of(0.1666));

        dt.setControl(falconDrive
        .withVelocityX(-controller.getLeftY() * MAX_SPEED)
        .withVelocityY(-controller.getLeftX() * MAX_SPEED)
        .withRotationalRate(rotationalRateRadPerSec));

        swerveCommandType = "FALCON";
        swerveCommandEntry.setString(swerveCommandType);

        break;
    
      case NORMALDRIVE:

        lastTargetDirection = dt.getState().Pose.getRotation();
        currentRotation = dt.getState().Pose.getRotation();


          dt.setControl(driveNormal
          .withVelocityX(-controller.getLeftY() * MAX_SPEED)
          .withVelocityY(-controller.getLeftX() * MAX_SPEED)
          .withRotationalRate(-controller.getRightX() * MAX_ANGULAR_RATE));
  
          swerveCommandType = "NORMAL";
          swerveCommandEntry.setString(swerveCommandType);
          break;


          case HUBDRIVE:
          // 3. Get current robot heading
          double robotHeading = dt.getState().Pose.getRotation().getDegrees();

          //2 Get theta to virtual goal (will be equivalent to angle to hub when stationary, but leads the target when moving)
          Double angleToGoal = ShootOnTheMove.calculateRobotHeading(dt.getState().Pose, dt.getState().Speeds).getDegrees();
          Logger.recordOutput("angleToGoal", angleToGoal);
          // 4. Calculate PID output (Rotational Speed)
          double rotationOutput = hubRotPID.calculate(robotHeading, angleToGoal);
          SmartDashboard.putNumber("rotationoutput", rotationOutput);
          // 5. Apply to Drivetrain
          // We use FieldCentric so your Left Stick (driving) remains intuitive 
          // regardless of where the robot is facing.
          dt.setControl(driveNormal
              .withVelocityX(-controller.getLeftY() *2)
              .withVelocityY(-controller.getLeftX() *2)
              .withRotationalRate(DegreesPerSecond.of(rotationOutput)));
          
          swerveCommandType = "HUB_AIM";
          swerveCommandEntry.setString(swerveCommandType);
          break;

    }
    

    
    }
  
  @Override
  public void end(boolean interrupted) {
    swerveCommandType = "INACTIVE";
    swerveCommandEntry.setString(swerveCommandType);
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
