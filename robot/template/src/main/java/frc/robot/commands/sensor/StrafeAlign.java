package frc.robot.commands.sensor;

import frc.robot.constants.VisionConstants;
import frc.robot.subsystems.LimelightSubsystem;
import frc.robot.subsystems.SwerveSubsystem;
import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.geometry.Translation2d;
import edu.wpi.first.wpilibj2.command.CommandBase;

public class StrafeAlign extends CommandBase{   


private final SwerveSubsystem s_swerve;
private final LimelightSubsystem s_limelight;
private final PIDController strafeController;

    public StrafeAlign(SwerveSubsystem s_swerve, LimelightSubsystem s_limelight){
        this.s_swerve = s_swerve;
        this.s_limelight = s_limelight;
        strafeController = new PIDController(0, 0, 0);

        addRequirements(this.s_swerve);
        addRequirements(this.s_limelight);
    }

    @Override
    public void initialize(){
        
    }

    @Override
    public void execute(){
        s_limelight.setResult();
        s_limelight.strafeAlignDistance();
        double strafeCommand = strafeController.calculate(s_limelight.strafeAlignDistance(), 0);
        s_swerve.drive(new Translation2d(strafeCommand, new Rotation2d(0)), 0, true, false);
    }

    @Override
    public boolean isFinished(){
        return Math.abs(s_limelight.strafeAlignDistance()) < VisionConstants.kAlignmentThreshold;
    }

    @Override
    public void end(boolean interrupted){
        s_swerve.drive(new Translation2d(0,0), 0, true, false);
    }

}