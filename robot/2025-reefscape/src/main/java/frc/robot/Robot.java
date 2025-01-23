// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot;

import edu.wpi.first.wpilibj.TimedRobot;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.CommandScheduler;

import com.ctre.phoenix6.SignalLogger;
import com.ctre.phoenix6.hardware.CANrange;
import com.pathplanner.lib.commands.PathfindingCommand;
import com.pathplanner.lib.pathfinding.Pathfinding;

import edu.wpi.first.math.estimator.SwerveDrivePoseEstimator;
import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.kinematics.SwerveDriveKinematics;
import edu.wpi.first.math.kinematics.SwerveModulePosition;
import edu.wpi.first.math.kinematics.SwerveModuleState;
import edu.wpi.first.math.util.Units;
import edu.wpi.first.net.WebServer;
import edu.wpi.first.wpilibj.DataLogManager;
import edu.wpi.first.wpilibj.DriverStation;
import edu.wpi.first.wpilibj.Filesystem;
import frc.robot.constants.ComandCenter;
import frc.robot.subsystems.vision.camera.Camera;
import frc.robot.utils.AutonTester;
import frc.robot.utils.DrivetrainConstants;
import frc.robot.utils.LocalADStarAK;
import frc.robot.utils.ObjectType;
import frc.robot.utils.PoseAllocate;
import frc.robot.utils.RobotTester;
import frc.robot.utils.SafetyManager;
import frc.robot.utils.Subsystems;
import frc.robot.utils.SystemCheckUp;

/**
 * The VM is configured to automatically run this class, and to call the methods corresponding to
 * each mode, as described in the TimedRobot documentation. If you change the name of this class or
 * the package after creating this project, you must also update the build.gradle file in the
 * project.
 */
public class Robot extends TimedRobot
{
    private Command autonomousCommand;
    private RobotContainer robotContainer;
    private Camera frontCamera;
    /**
     * This method is run when the robot is first started up and should be used for any
     * initialization code.
     */
    @Override
    public void robotInit()
    {

        Pathfinding.setPathfinder(new LocalADStarAK());


        SignalLogger.setPath("/media/sda1/CTRElogs/");

        WebServer.start(5800, Filesystem.getDeployDirectory().getPath());
        robotContainer = new RobotContainer();
        new SafetyManager(robotContainer.SafeGuardSystems());
        ComandCenter.init();


        // Start logging data log
        SignalLogger.start();
        DataLogManager.start();


        DriverStation.startDataLog(DataLogManager.getLog());
        PathfindingCommand.warmupCommand().schedule();
    }


    /**
     * This method is called every 20 ms, no matter the mode. Use this for items like diagnostics
     * that you want ran during disabled, autonomous, teleoperated and test.
     *
     * <p>This runs after the mode specific periodic methods, but before LiveWindow and
     * SmartDashboard integrated updating.
     */


    @Override
    public void robotPeriodic()
    {
        CommandScheduler.getInstance().run();
    }

    /** This method is called once each time the robot enters Disabled mode. */
    @Override
    public void disabledInit() {


    }

    @Override
    public void disabledPeriodic() {}


    /** This autonomous runs the autonomous command selected by your {@link RobotContainer} class. */
    @Override
    public void autonomousInit()
    {
        autonomousCommand = robotContainer.getAutonomousCommand();

        // schedule the autonomous command (example)
        if (autonomousCommand != null)
        {
            autonomousCommand.schedule();
        }
    }


    /** This method is called periodically during autonomous. */
    @Override
    public void autonomousPeriodic() {}


    @Override
    public void teleopInit()
    {

        if (autonomousCommand != null)
        {
            autonomousCommand.cancel();
        }
    }


    /** This method is called periodically during operator control. */
    @Override
    public void teleopPeriodic() {
    }


    @Override
    public void testInit() {
        // Cancels all running commands at the start of test mode.
        CommandScheduler.getInstance().cancelAll();
        new RobotTester(robotContainer.TestCommands());
        new AutonTester(robotContainer.TestAutonCommands());
        new SystemCheckUp(robotContainer.TestSystems());
    }

    /** This method is called periodically during test mode. */
    @Override
    public void testPeriodic() {

    }


    /** This method is called once when the robot is first started up. */
    @Override
    public void simulationInit() {}


    /** This method is called periodically whilst in simulation. */
    @Override
    public void simulationPeriodic() {}
}
