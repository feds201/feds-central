// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.commands.swerve;

import static edu.wpi.first.units.Units.DegreesPerSecond;
import static edu.wpi.first.units.Units.MetersPerSecond;
import static edu.wpi.first.units.Units.RadiansPerSecond;
import static edu.wpi.first.units.Units.RotationsPerSecond;

import com.ctre.phoenix6.swerve.SwerveRequest;

import edu.wpi.first.math.MathUtil;
import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.Command;
import frc.robot.RobotMap;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.subsystems.swerve.generated.TunerConstants;

/* You should consider using the more terse Command factories API instead https://docs.wpilib.org/en/stable/docs/software/commandbased/organizing-command-based.html#defining-commands */
public class PathfindToPose extends Command {
  /** Creates a new PathfindToPose. */
  public static final double MAX_SPEED = TunerConstants.kSpeedAt12Volts.in(MetersPerSecond);
  public static final double MAX_ANGULAR_RATE = RotationsPerSecond.of(2).in(RadiansPerSecond);
  
  //tune these values
  private final PIDController xPID = new PIDController(
    RobotMap.PathfindConstants.xP,
    RobotMap.PathfindConstants.xI,
    RobotMap.PathfindConstants.xD);
  private final PIDController yPID = new PIDController(
    RobotMap.PathfindConstants.yP,
    RobotMap.PathfindConstants.yI,
    RobotMap.PathfindConstants.yD);
  private final PIDController rotPID = new PIDController(
    RobotMap.PathfindConstants.rotP,
    RobotMap.PathfindConstants.rotI,
    RobotMap.PathfindConstants.rotD);

  
  private CommandSwerveDrivetrain dt;
  private Pose2d targetPose;

  private SwerveRequest.FieldCentric driveRequest;

  public PathfindToPose(CommandSwerveDrivetrain dt, Pose2d targetPose) {
    this.dt = dt;
    this.targetPose = targetPose;

    driveRequest = new SwerveRequest.FieldCentric()
    .withDeadband(MAX_SPEED*.07)
    .withRotationalDeadband(MAX_ANGULAR_RATE*.07);

    rotPID.enableContinuousInput(-180, 180);
    rotPID.setTolerance(3);
    
    addRequirements(this.dt);
  }
  // Called when the command is initially scheduled.
  @Override
  public void initialize() {
    xPID.reset();
    yPID.reset();
    rotPID.reset();
  }

  // Called every time the scheduler runs while the command is scheduled.
  @Override
  public void execute() {
    Pose2d currentPose = dt.getState().Pose;
    
    double rotationOutput = rotPID.calculate(
      currentPose.getRotation().getDegrees(), //current rotation
      targetPose.getRotation().getDegrees()); //target rotation
    double xTransOutput = xPID.calculate(
      currentPose.getX(),
      targetPose.getX());
    double yTransOutput = yPID.calculate(
      currentPose.getY(),
      targetPose.getY());

    double maxAngularRateDegreesPerSecond = RotationsPerSecond.of(2).in(DegreesPerSecond);
    rotationOutput = MathUtil.clamp(rotationOutput, -maxAngularRateDegreesPerSecond, maxAngularRateDegreesPerSecond);
    xTransOutput = MathUtil.clamp(xTransOutput, -MAX_SPEED, MAX_SPEED);
    yTransOutput = MathUtil.clamp(yTransOutput, -MAX_SPEED, MAX_SPEED);

    SmartDashboard.putNumber("rotationoutput", rotationOutput);
    SmartDashboard.putNumber("xTransOutput", xTransOutput);
    SmartDashboard.putNumber("yTransOutput", yTransOutput);          

    dt.setControl(driveRequest
        .withVelocityX(MetersPerSecond.of(xTransOutput))
        .withVelocityY(MetersPerSecond.of(yTransOutput))
        .withRotationalRate(DegreesPerSecond.of(rotationOutput)));
  }

  // Called once the command ends or is interrupted.
  @Override
  public void end(boolean interrupted) {
    dt.setControl(new SwerveRequest.Idle());
  }

  // Returns true when the command should end.
  @Override
  public boolean isFinished() {
    return false;
  }
}
