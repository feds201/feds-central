// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.commands.swanNeck;

import edu.wpi.first.wpilibj2.command.ParallelCommandGroup;
import edu.wpi.first.wpilibj2.command.ParallelDeadlineGroup;
import edu.wpi.first.wpilibj2.command.SequentialCommandGroup;
import edu.wpi.first.wpilibj2.command.WaitCommand;
import frc.robot.commands.lift.RotateElevatorDownPID;
import frc.robot.commands.lift.RotateElevatorPID;
import frc.robot.constants.RobotMap.ElevatorMap;
import frc.robot.constants.RobotMap.IntakeMap;
import frc.robot.subsystems.lift.Lift;
import frc.robot.subsystems.swanNeck.SwanNeck;
import frc.robot.subsystems.swanNeck.SwanNeckWheels;

// NOTE:  Consider using this command inline, rather than writing a subclass.  For more
// information, see:
// https://docs.wpilib.org/en/stable/docs/software/commandbased/convenience-features.html
public class IntakeCoralSequence extends SequentialCommandGroup {
  SwanNeck m_SwanNeck;
  Lift m_eleLift;
  SwanNeckWheels m_SwanNeckWheels;
  /** Creates a new loadCoral. */
  public IntakeCoralSequence(SwanNeck swanNeck, SwanNeckWheels swanNeckWheels, Lift elevator) {
    m_SwanNeck = swanNeck;
    m_SwanNeckWheels = swanNeckWheels;
    m_eleLift = elevator;
    // Add your commands in the addCommands() call, e.g.
    // addCommands(new FooCommand(), new BarCommand());
    addCommands(new RaiseSwanNeckPID(()-> IntakeMap.ReefStops.INTAKEANGLE, m_SwanNeck).until(m_SwanNeck :: pidAtSetpoint),

    new ParallelDeadlineGroup( new SequentialCommandGroup( 
    new SpinSwanWheels(m_SwanNeckWheels, ()-> IntakeMap.WHEEL_SPEED_INTAKE).until(m_SwanNeck :: getCoralLoaded),
    new SpinSwanWheels(m_SwanNeckWheels, ()-> IntakeMap.WHEEL_SPEED_INTAKE).until(m_SwanNeck :: getCoralLoadedOpposite),
    new SpinSwanWheels(m_SwanNeckWheels, ()-> -IntakeMap.WHEEL_SPEED_INTAKE/2).until(m_SwanNeck :: getCoralLoaded),
    new SpinSwanWheels(m_SwanNeckWheels, ()-> IntakeMap.WHEEL_SPEED_INTAKE).until(m_SwanNeck :: getCoralLoaded),
    new SpinSwanWheels(m_SwanNeckWheels, ()-> IntakeMap.WHEEL_SPEED_INTAKE).until(m_SwanNeck :: getCoralLoadedOpposite),
    new SpinSwanWheels(m_SwanNeckWheels, ()-> -IntakeMap.WHEEL_SPEED_INTAKE/2).until(m_SwanNeck :: getCoralLoaded),
    new ParallelDeadlineGroup(new WaitCommand(.08),new SpinSwanWheels(m_SwanNeckWheels, ()-> -IntakeMap.WHEEL_SPEED_INTAKE/2)),
    new RaiseSwanNeckPID(()-> IntakeMap.ReefStops.SAFEANGLE, m_SwanNeck).until(m_SwanNeck :: pidAtSetpoint)),
    new RotateElevatorPID(elevator, ()-> 1.3)

      
    ));
  }
}
