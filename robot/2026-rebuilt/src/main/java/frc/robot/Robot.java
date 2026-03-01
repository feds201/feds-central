// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot;

import java.util.HashMap;
import java.util.Map;
import java.util.function.BiConsumer;

import org.littletonrobotics.junction.LogFileUtil;
import org.littletonrobotics.junction.LoggedRobot;
import org.littletonrobotics.junction.Logger;
import org.littletonrobotics.junction.networktables.NT4Publisher;
import org.littletonrobotics.junction.wpilog.WPILOGReader;
import org.littletonrobotics.junction.wpilog.WPILOGWriter;

import com.ctre.phoenix6.SignalLogger;

import edu.wpi.first.hal.AllianceStationID;
import edu.wpi.first.wpilibj.DriverStation;
import edu.wpi.first.wpilibj.simulation.DriverStationSim;
import edu.wpi.first.wpilibj.simulation.RoboRioSim;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.CommandScheduler;
import frc.robot.utils.DeviceTempReporter;
import frc.robot.utils.SubsystemStatusManager;
import frc.robot.utils.DeviceTempReporter;
import frc.robot.utils.SubsystemStatusManager;

//comment out the above line if you don't have a LedsSubsystem, and comment out the line in RobotContainer that creates the LedsSubsystem, and comment out the line in RobotContainer that sets the default command for the LedsSubsystem. You can also delete the LedsSubsystem class if you don't have it, but it's easier to just comment out those lines.
public class Robot extends LoggedRobot {
  private Command m_autonomousCommand;

  private final RobotContainer m_robotContainer;
  // public LedsSubsystem m_ledsSubsystem = new LedsSubsystem();


  public Robot() {
    Logger.recordMetadata("ProjectName", "2026-Rebuilt");
    // Logger.recordMetadata("GitSHA", BuildConstants.GIT_SHA);
    // Logger.recordMetadata("GitBranch", BuildConstants.GIT_BRANCH);
    // Logger.recordMetadata("GitDirty", BuildConstants.DIRTY == 1 ? "UNCOMMITTED CHANGES" : "clean");
    // Logger.recordMetadata("BuildDate", BuildConstants.BUILD_DATE);

      switch (RobotMap.getRobotMode()) {
      case REAL:
        Logger.addDataReceiver(new WPILOGWriter()); // Saves logs to RoboRIO
        Logger.addDataReceiver(new NT4Publisher()); // Publishes logs to network tables
        break;

      case SIM:
        // To save .wpilog files during sim (e.g. for SysID characterization), run:
        //   ./gradlew simulateJava -PsimLogging=true
        if (Boolean.getBoolean("simLogging")) {
          Logger.addDataReceiver(new WPILOGWriter("logs"));
        }
        //Logger.addDataReceiver(new WPILOGWriter("log"));
        Logger.addDataReceiver(new NT4Publisher());
        break;

      case REPLAY:
        String inPath = LogFileUtil.findReplayLog();
        Logger.setReplaySource(new WPILOGReader(inPath)); // Sets the log file to replay
        Logger.addDataReceiver(new NT4Publisher()); // Publishes logs to network tables
        break;
    }

    SignalLogger.setPath("/media/sda1/CTRElogs/");
    
    Logger.start();

     // Silence joystick alerts
    DriverStation.silenceJoystickConnectionWarning(true);

    // Log active commands
    Map<String, Integer> commandCounts = new HashMap<>();
    BiConsumer<Command, Boolean> logCommandFunction =
        (Command command, Boolean active) -> {
          String name = command.getName();
          int count = commandCounts.getOrDefault(name, 0) + (active ? 1 : -1);
          commandCounts.put(name, count);
          Logger.recordOutput(
              "CommandsUnique/" + name + "_" + Integer.toHexString(command.hashCode()), active);
          Logger.recordOutput("CommandsAll/" + name, count > 0);
        };
    CommandScheduler.getInstance()
        .onCommandInitialize((Command command) -> logCommandFunction.accept(command, true));
    CommandScheduler.getInstance()
        .onCommandFinish((Command command) -> logCommandFunction.accept(command, false));
    CommandScheduler.getInstance()
        .onCommandInterrupt((Command command) -> logCommandFunction.accept(command, false));

    // Configure Driver Station for sim
    RoboRioSim.setTeamNumber(201);
    if (RobotMap.getRobotMode() == RobotMap.robotState.SIM) {
      DriverStationSim.setAllianceStationId(AllianceStationID.Blue1);
      DriverStationSim.notifyNewData();
    }

    m_robotContainer = new RobotContainer();
  }

  @Override
  public void robotPeriodic() {
    m_robotContainer.updateLocalization();
    CommandScheduler.getInstance().run();
    // DeviceTempReporter.pollAll();
    // SubsystemStatusManager.pollAll();
  }

  @Override
  public void disabledInit() {}

  @Override
  public void disabledPeriodic() {}

  @Override
  public void disabledExit() {}

  @Override
  public void autonomousInit() {
    m_autonomousCommand = m_robotContainer.getAutonomousCommand();

    if (m_autonomousCommand != null) {
      CommandScheduler.getInstance().schedule(m_autonomousCommand);
    }
  }


  @Override
  public void autonomousPeriodic() {}

  @Override
  public void autonomousExit() {}

  @Override
  public void teleopInit() {
    if (m_autonomousCommand != null) {
      m_autonomousCommand.cancel();
    }
  }

  @Override
  public void teleopPeriodic() {}

  @Override
  public void teleopExit() {}

  @Override
  public void testInit() {
    CommandScheduler.getInstance().cancelAll();
    m_robotContainer.runRootTests();
  }

  @Override
  public void testPeriodic() {
    m_robotContainer.updateRootTests();
  }

  @Override
  public void testExit() {}

  @Override
  public void simulationInit() {
    m_robotContainer.initSimulation();
  }

  @Override
  public void simulationPeriodic() {
    m_robotContainer.updateSimulation();
  }
}
