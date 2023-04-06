package frc.robot.commands.sensor;

import frc.robot.constants.VisionConstants;
import frc.robot.subsystems.LimelightSubsystem;
import frc.robot.subsystems.SwerveSubsystem;
import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.wpilibj.Timer;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.CommandBase;

public class StrafeAlign extends CommandBase{   
    private final SwerveSubsystem s_swerve;
    private final LimelightSubsystem s_limelight;
    private final PIDController strafeController;
    private final double finalPos;

    public StrafeAlign(SwerveSubsystem s_swerve, LimelightSubsystem s_limelight, double finalPos){
        this.s_swerve = s_swerve;
        this.s_limelight = s_limelight;
        strafeController = new PIDController(1, 0.4, 0);
        this.finalPos = finalPos;

        addRequirements(this.s_swerve);
        addRequirements(this.s_limelight);
    }

    @Override
    public void initialize(){
    }

    @Override
    public void execute(){
        double strafeCommand = strafeController.calculate(s_limelight.getStrafeAlignDistance(), finalPos);

        SmartDashboard.putNumber("STRAFE COMMAND", strafeCommand);
        Translation2d strafe = new Translation2d(strafeCommand, new Rotation2d(Math.PI/2)).times(-2.5);
        SmartDashboard.putNumber("Translation Y", strafe.getY());
        s_swerve.drive((strafe), 0, true, true);
    }

    @Override
    public boolean isFinished(){
        return Math.abs(s_limelight.getStrafeAlignDistance()) < VisionConstants.kAlignmentThreshold;
    }

    @Override
    public void end(boolean interrupted){
        s_swerve.drive(new Translation2d(0,0), 0, true, false);
    }

}