// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.commands.swerve;

import static edu.wpi.first.units.Units.DegreesPerSecond;
import static edu.wpi.first.units.Units.MetersPerSecond;
import static edu.wpi.first.units.Units.RadiansPerSecond;
import static edu.wpi.first.units.Units.RotationsPerSecond;

import com.ctre.phoenix6.swerve.SwerveRequest;
import com.pathplanner.lib.util.FlippingUtil;

import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.wpilibj.DriverStation;
import edu.wpi.first.wpilibj.DriverStation.Alliance;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import frc.robot.RobotMap;
import frc.robot.RobotMap.ShooterConstants;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.subsystems.swerve.generated.TunerConstants;

/* You should consider using the more terse Command factories API instead https://docs.wpilib.org/en/stable/docs/software/commandbased/organizing-command-based.html#defining-commands */
public class PassingDrive extends Command {
  public static final double MAX_SPEED = TunerConstants.kSpeedAt12Volts.in(MetersPerSecond);
  public static final double MAX_ANGULAR_RATE = RotationsPerSecond.of(2).in(RadiansPerSecond);

  private CommandSwerveDrivetrain dt;
  private CommandXboxController controller;

  private static final PIDController passRotPID = new PIDController(6.7, 0, .2);
 private SwerveRequest.FieldCentric driveNormal;

  /** Command used to control swerve in teleop. */
  public PassingDrive(CommandSwerveDrivetrain dt, CommandXboxController controller) {
    this.dt = dt;
    this.controller = controller;


    driveNormal = new SwerveRequest.FieldCentric()
    .withDeadband(MAX_SPEED*.07)
    .withRotationalDeadband(MAX_ANGULAR_RATE*.07);
    passRotPID.enableContinuousInput(-180, 180);
    passRotPID.setTolerance(10);
    
    addRequirements(this.dt);
  }

  public static boolean pidAtSetpoint(){
    return passRotPID.atSetpoint();
  }

  // Called when the command is initially scheduled.
  @Override
  public void initialize() {}

  // Called every time the scheduler runs while the command is scheduled.
  @Override
  public void execute() {
    Translation2d robotPose = dt.getState().Pose.getTranslation();
    Translation2d aimLoc = ShooterConstants.centerPointOutpost;
    if (DriverStation.getAlliance().orElse(Alliance.Blue) == Alliance.Red) {
                aimLoc = FlippingUtil.flipFieldPosition(RobotMap.ShooterConstants.centerPointOutpost);
            }
    double angleToTarget = Math.toDegrees(Math.atan2(aimLoc.getY() - robotPose.getY(), aimLoc.getX() - robotPose.getX()));
    double robotHeading = dt.getState().Pose.getRotation().getDegrees();
    double rotRate = passRotPID.calculate(robotHeading,angleToTarget);
    if(rotRate > 0){
            rotRate+= 15;
          } else {
            rotRate -= 15;
          }
    dt.setControl(driveNormal
              .withVelocityX(-controller.getLeftY() * MAX_SPEED)
              .withVelocityY(-controller.getLeftX() * MAX_SPEED)
              .withRotationalRate(DegreesPerSecond.of(rotRate)));
  }

  // Called once the command ends or is interrupted.
  @Override
  public void end(boolean interrupted) {}

  // Returns true when the command should end.
  @Override
  public boolean isFinished() {
    return false;
  }
}