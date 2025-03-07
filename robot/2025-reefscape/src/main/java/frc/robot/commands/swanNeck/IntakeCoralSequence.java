// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.commands.swanNeck;

import edu.wpi.first.wpilibj2.command.SequentialCommandGroup;
import frc.robot.constants.RobotMap.IntakeMap;
import frc.robot.subsystems.swanNeck.SwanNeck;
import frc.robot.subsystems.swanNeck.SwanNeckWheels;

// NOTE:  Consider using this command inline, rather than writing a subclass.  For more
// information, see:
// https://docs.wpilib.org/en/stable/docs/software/commandbased/convenience-features.html
public class IntakeCoralSequence extends SequentialCommandGroup {
  SwanNeck m_SwanNeck;
  SwanNeckWheels m_SwanNeckWheels;
  /** Creates a new loadCoral. */
  public IntakeCoralSequence(SwanNeck swanNeck, SwanNeckWheels swanNeckWheels) {
    m_SwanNeck = swanNeck;
    m_SwanNeckWheels = swanNeckWheels;
    // Add your commands in the addCommands() call, e.g.
    // addCommands(new FooCommand(), new BarCommand());
    addCommands(new RaiseSwanNeckPID(()-> IntakeMap.ReefStops.SAFEANGLE, m_SwanNeck).until(m_SwanNeck :: pidAtSetpoint),
      new SpinSwanWheels(m_SwanNeckWheels, ()-> IntakeMap.WHEEL_SPEED_INTAKE).until(m_SwanNeck :: getCoralLoaded),
      new SpinSwanWheels(m_SwanNeckWheels, ()-> IntakeMap.WHEEL_SPEED_INTAKE).until(m_SwanNeck :: getCoralLoadedOpposite),
      new SpinSwanWheels(m_SwanNeckWheels, ()-> -IntakeMap.WHEEL_SPEED_INTAKE/2).until(m_SwanNeck :: getCoralLoaded)
    );
  }
}
