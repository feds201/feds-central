// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot;

import edu.wpi.first.wpilibj.TimedRobot;
import edu.wpi.first.wpilibj.smartdashboard.Mechanism2d;
import edu.wpi.first.wpilibj.smartdashboard.MechanismLigament2d;
import edu.wpi.first.wpilibj.smartdashboard.MechanismRoot2d;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.CommandScheduler;

import com.ctre.phoenix6.SignalLogger;
import com.pathplanner.lib.commands.PathfindingCommand;
import com.pathplanner.lib.pathfinding.Pathfinding;

import edu.wpi.first.math.util.Units;
import edu.wpi.first.net.WebServer;
import edu.wpi.first.wpilibj.DataLogManager;
import edu.wpi.first.wpilibj.DriverStation;
import edu.wpi.first.wpilibj.Filesystem;
import frc.robot.constants.ComandCenter;
import frc.robot.utils.AutonTester;
import frc.robot.utils.LocalADStarAK;
import frc.robot.utils.RobotTester;
import frc.robot.utils.SafetyManager;
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

    // Create a Mechanism2d dashboard for the elevator
    private Mechanism2d elevator = new Mechanism2d(48, 96);
    // ADD: Field for the elevator ligament
    private MechanismLigament2d elevatorLigament;

    // In robotInit or in a constructor, add the mechanism to SmartDashboard
    // For this example, we'll add it in an instance initializer block.
    {
        SmartDashboard.putData("Elevator Mechanism", elevator);
        // Get the root node to start drawing
        MechanismRoot2d elevatorDisplay = elevator.getRoot("Elevator",20,20);

        // Example: Draw a line representing the elevator’s range of motion.
        // Parameters: start x, start y, end x, end y.
        elevatorLigament = elevatorDisplay.append(new MechanismLigament2d("Elevator", 0, 90));
    }
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
        SmartDashboard.putData("command scheduler", CommandScheduler.getInstance());
        CommandScheduler.getInstance().run();
        robotContainer.setupVisionImplants();
      
       
        // ADD: Update elevator mechanism based on current elevator height (meters converted to inches)
        if(robotContainer != null) {
            double heightMeters = robotContainer.getElevator().getElevatorHeight();
            double heightInches = Units.metersToInches(heightMeters);
            elevatorLigament.setLength(heightInches);
        }
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
