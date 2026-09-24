// Copyright (c) 2021-2026 Littleton Robotics
// http://github.com/Mechanical-Advantage
//
// Use of this source code is governed by a BSD
// license that can be found in the LICENSE file
// at the root directory of this project.

package frc.robot.utils;

import com.ctre.phoenix6.StatusCode;
import com.ctre.phoenix6.sim.TalonFXSimState;
import edu.wpi.first.wpilibj.RobotController;
import edu.wpi.first.wpilibj.simulation.DCMotorSim;
import static edu.wpi.first.units.Units.Volts;
import java.util.function.Supplier;

public class PhoenixUtil {
  /** Attempts to run the command until no error is produced. */
  public static void tryUntilOk(int maxAttempts, Supplier<StatusCode> command) {
    for (int i = 0; i < maxAttempts; i++) {
      var error = command.get();
      if (error.isOK())
        break;
    }
  }

  public static void updateTalonSimState(DCMotorSim motorSim, TalonFXSimState simState,
      double gearRatio) {
    simState.setSupplyVoltage(RobotController.getBatteryVoltage());

    // Update simulation of motor's produced torque
    double volts = simState.getMotorVoltageMeasure().in(Volts);
    motorSim.setInputVoltage(volts);
    motorSim.update(0.02);

    // Update the Talon's physical state based on the intertial simulaiton
    simState.setRawRotorPosition(motorSim.getAngularPosition().times(gearRatio));
    simState.setRotorVelocity(motorSim.getAngularVelocity().times(gearRatio));
  }
}
