// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.commands;

import static edu.wpi.first.units.Units.Degrees;
import static edu.wpi.first.units.Units.MetersPerSecond;
import static edu.wpi.first.units.Units.RadiansPerSecond;
import static edu.wpi.first.units.Units.Rotations;
import static edu.wpi.first.units.Units.RotationsPerSecond;
import static edu.wpi.first.units.Units.Seconds;

import java.util.logging.Logger;

import com.ctre.phoenix6.swerve.SwerveRequest;

import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.utils.LimelightHelpers;
import frc.robot.utils.ShootOnTheMove;
import limelight.Limelight;
import frc.robot.subsystems.swerve.generated.TunerConstants;
import edu.wpi.first.units.measure.Angle;
import edu.wpi.first.units.measure.AngularVelocity;
import edu.wpi.first.units.measure.Time;


/* You should consider using the more terse Command factories API instead https://docs.wpilib.org/en/stable/docs/software/commandbased/organizing-command-based.html#defining-commands */
public class BallTracking extends Command {

  public static final double MAX_SPEED = TunerConstants.kSpeedAt12Volts.in(MetersPerSecond);
  public static final double MAX_ANGULAR_RATE = RotationsPerSecond.of(2).in(RadiansPerSecond);
  private final PIDController hubRotPID = new PIDController(1, 0, 0);
  private final CommandSwerveDrivetrain dt;


 private SwerveRequest.FieldCentric driveNormal;


  
  /** Creates a new ballTracking. */
  public BallTracking(CommandSwerveDrivetrain dt) {
    this.dt = dt;
    
    driveNormal = new SwerveRequest.FieldCentric();

  }

  // Called when the command is initially scheduled.
  @Override
  public void initialize() {
    hubRotPID.setSetpoint(0);    
  }

  // Called every time the scheduler runs while the command is scheduled.
  @Override
  public void execute() {
    double xError = LimelightHelpers.getTX("ll_intake");
    

   dt.setControl(driveNormal
          .withVelocityX(0)
          .withVelocityY(0)
          .withRotationalRate(-hubRotPID.calculate(xError)));
  }

  // Called once the command ends or is interrupted.
  @Override
  public void end(boolean interrupted) {}

  // Returns true when the command should end.
  @Override
  public boolean isFinished() {
    return hubRotPID.atSetpoint();
  }
}
