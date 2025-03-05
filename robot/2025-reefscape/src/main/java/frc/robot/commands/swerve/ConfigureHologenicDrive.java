// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.commands.swerve;

import edu.wpi.first.math.filter.SlewRateLimiter;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.ParallelCommandGroup;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import frc.robot.constants.RobotMap;
import frc.robot.constants.RobotMap.SafetyMap;
import frc.robot.subsystems.lift.Lift;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.utils.DrivetrainConstants;

/* You should consider using the more terse Command factories API instead https://docs.wpilib.org/en/stable/docs/software/commandbased/organizing-command-based.html#defining-commands */
public class ConfigureHologenicDrive extends Command {
  private CommandXboxController m_driverController;
  private CommandSwerveDrivetrain m_drivetrain;
  private Command driveCommand;
  
  private SlewRateLimiter slewX = new SlewRateLimiter(1.5);
  private SlewRateLimiter slewY = new SlewRateLimiter(1.5);
  /** Creates a new ConfigureHologenicDrive. */
  public ConfigureHologenicDrive(CommandXboxController driverController, CommandSwerveDrivetrain drivetrain) {
    m_driverController = driverController;
    m_drivetrain = drivetrain;
    addRequirements(m_drivetrain);
    // Use addRequirements() here to declare subsystem dependencies.
  }

  // Called when the command is initially scheduled.
  @Override
  public void initialize() {
    driveCommand = 
              DrivetrainConstants.drivetrain.applyRequest(() -> DrivetrainConstants.drive
                              .withVelocityX(slewX.calculate(-m_driverController.getLeftY() * SafetyMap.kMaxSpeed
                                              * SafetyMap.kMaxSpeedChange))
                              .withVelocityY(slewY.calculate(-m_driverController.getLeftX() * SafetyMap.kMaxSpeed
                                              * SafetyMap.kMaxSpeedChange))
                              .withRotationalRate(-m_driverController.getRightX()
                                              * SafetyMap.kMaxAngularRate
                                              * SafetyMap.kAngularRateMultiplier));

       driveCommand.schedule();
  }

  // Called every time the scheduler runs while the command is scheduled.
  @Override
  public void execute() {
   
        }
  

  // Called once the command ends or is interrupted.
  @Override
  public void end(boolean interrupted) {
   driveCommand.cancel();
  }

  // Returns true when the command should end.
  @Override
  public boolean isFinished() {
    return false;
  }
}
