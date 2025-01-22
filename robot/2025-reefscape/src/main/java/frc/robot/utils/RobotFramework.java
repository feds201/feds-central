package frc.robot.utils;

import java.util.Map;

import edu.wpi.first.wpilibj.shuffleboard.BuiltInWidgets;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.ParallelCommandGroup;
import edu.wpi.first.wpilibj2.command.button.CommandXboxController;
import frc.robot.constants.RobotMap.SafetyMap;
import frc.robot.subsystems.swerve.SwerveSubsystem;

/**
 * Class for configuring robot drive modes.
 */
public class RobotFramework {

        private double snappedAngle = 0.0;
        private double angle = 0.0;
        private Smooth anglerate = new Smooth(10);

        /**
         * Configures the hologenic drive mode.
         * 
         * @param driverController the driver controller.
         * @param swerveSubsystem  the swerve subsystem.
         * @return the command to configure hologenic drive.
         */
        public Command ConfigureHologenicDrive(CommandXboxController driverController,
                        SwerveSubsystem swerveSubsystem) {
                return new ParallelCommandGroup(
                                DrivetrainConstants.drivetrain.applyRequest(() -> DrivetrainConstants.drive
                                                .withVelocityX(-driverController.getLeftY() * SafetyMap.kMaxSpeed
                                                                * SafetyMap.kMaxSpeedChange)
                                                .withVelocityY(-driverController.getLeftX() * SafetyMap.kMaxSpeed
                                                                * SafetyMap.kMaxSpeedChange)
                                                .withRotationalRate(-driverController.getRightX()
                                                                * SafetyMap.kMaxAngularRate
                                                                * SafetyMap.kAngularRateMultiplier)));
        }

        /**
         * Configures the beyblade drive mode.
         * 
         * @param driverController the driver controller.
         * @param swerveSubsystem  the swerve subsystem.
         * @return the command to configure beyblade drive.
         */
        public Command ConfigureBeyBlade(CommandXboxController driverController, SwerveSubsystem swerveSubsystem) {
                return new ParallelCommandGroup(
                                DrivetrainConstants.drivetrain.applyRequest(() -> DrivetrainConstants.drive
                                                .withVelocityX(driverController.getLeftY() * SafetyMap.kMaxSpeed
                                                                * SafetyMap.kMaxSpeedChange)
                                                .withVelocityY(driverController.getLeftX() * SafetyMap.kMaxSpeed
                                                                * SafetyMap.kMaxSpeedChange)
                                                .withRotationalRate(5 * SafetyMap.kMaxAngularRate
                                                                * SafetyMap.kAngularRateMultiplier)));
        }

        /**
         * Configures the tank drive mode.
         * 
         * @param driverController the driver controller.
         * @param swerveSubsystem  the swerve subsystem.
         * @return the command to configure tank drive.
         */
        public Command ConfigureTankDrive(CommandXboxController driverController, SwerveSubsystem swerveSubsystem) {
                return new ParallelCommandGroup(
                                DrivetrainConstants.drivetrain.applyRequest(() -> {
                                        // Get joystick inputs
                                        double leftInput = -driverController.getLeftY(); // Left joystick controls the
                                                                                         // left side
                                        double rightInput = -driverController.getRightY(); // Right joystick controls
                                                                                           // the right side

                                        // Apply deadbands to inputs
                                        double leftSpeed = swerveSubsystem.applyDeadband(leftInput, 0.05)
                                                        * SafetyMap.kMaxSpeed;
                                        double rightSpeed = swerveSubsystem.applyDeadband(rightInput, 0.05)
                                                        * SafetyMap.kMaxSpeed;

                                        // Translate tank drive logic into swerve drive wheel velocities
                                        double velocityX = (leftSpeed + rightSpeed) / 2.0; // Average of left and right
                                                                                           // for forward/backward
                                                                                           // motion
                                        double rotationRate = (rightSpeed - leftSpeed) / 3; // Difference controls
                                                                                            // rotation
                                        // Disable Field Relative Drive

                                        // Return a new swerve drive state
                                        return DrivetrainConstants.robotDrive
                                                        .withVelocityX(velocityX)
                                                        .withVelocityY(0) // No lateral movement for tank drive
                                                        .withRotationalRate(rotationRate * SafetyMap.kMaxAngularRate);
                                }));
        }

        /**
         * Configures the arcade drive mode.
         * 
         * @param driverController the driver controller.
         * @param swerveSubsystem  the swerve subsystem.
         * @return the command to configure arcade drive.
         */
        public Command ConfigureArcadeDrive(CommandXboxController driverController, SwerveSubsystem swerveSubsystem) {
                return new ParallelCommandGroup(

                                DrivetrainConstants.drivetrain.applyRequest(() -> DrivetrainConstants.robotDrive
                                                .withVelocityX(-driverController.getLeftY() * SafetyMap.kMaxSpeed)
                                                .withRotationalRate(-driverController.getRightX()
                                                                * SafetyMap.kMaxAngularRate)));
        }

        /**
         * Configures the FODC drive mode.
         * 
         * @param controller the driver controller.
         * @param swerve     the swerve subsystem.
         * @return the command to configure FODC drive.
         */
        public Command ConfigureFODC(CommandXboxController controller, SwerveSubsystem swerve) {

                swerve.getTab().addNumber("Angle", () -> snappedAngle)
                                .withWidget(BuiltInWidgets.kGyro)
                                .withPosition(0, 0)
                                .withProperties(Map.of("majorTickSpacing", SafetyMap.FODC.LineCount, "startingAngle",
                                                0));

                swerve.getTab().addNumber("FODC/Angle", () -> angle)
                                .withWidget(BuiltInWidgets.kGyro)
                                .withPosition(0, 1) // Changed position to avoid overlap
                                .withProperties(Map.of("majorTickSpacing", SafetyMap.FODC.LineCount, "startingAngle",
                                                0));
                return new ParallelCommandGroup(

                                DrivetrainConstants.drivetrain.applyRequest(() -> {
                                        // Initial variables
                                        double angleDiff;
                                        double rightStickX = swerve.applyDeadband(controller.getRightX(), 0.09);
                                        double rightStickY = swerve.applyDeadband(controller.getRightY(), 0.09);
                                        double lastAngle = 0;

                                        // If joystick is moved, calculate new angle, otherwise use last angle
                                        if (rightStickX != 0 || rightStickY != 0) {
                                                angle = Math.toDegrees(Math.atan2(-rightStickY, -rightStickX)); // atan2
                                                                                                                // returns
                                                                                                                // angle
                                                                                                                // in
                                                                                                                // radians,
                                                                                                                // convert
                                                                                                                // to
                                                                                                                // degrees
                                                lastAngle = angle; // Update last angle when joystick is moved
                                        } else {
                                                angle = lastAngle; // Use last angle if joystick is not moved
                                        }

                                        if (rightStickX == 0 && rightStickY == 0) {
                                                angle = swerve.getRobotAngle();
                                        }

                                        // Snap the angle to the nearest grid line based on the configuration
                                        double snappedAngle = swerve.snapToNearestLine(angle, SafetyMap.FODC.LineCount);

                                        // Update dashboard with current angle values
                                        SmartDashboard.putNumber("Angle", snappedAngle);
                                        SmartDashboard.putNumber("FODC/Angle", angle);

                                        // Calculate angle difference between the snapped angle and the robot's current
                                        // angle
                                        double robotAngle = swerve.getRobotAngle();
                                        angleDiff = snappedAngle - robotAngle;
                                        SmartDashboard.putNumber("Angle Diff", angleDiff);
                                        if (Math.abs(angleDiff) > 10) {
                                                double angularRate = anglerate
                                                                .calculate(swerve.getPIDRotation(angleDiff));
                                                SmartDashboard.putNumber("Angular Rate", angularRate);

                                                // Return the drivetrain command with translational and rotational
                                                // speeds
                                                return DrivetrainConstants.drive
                                                                .withVelocityX(controller.getLeftY()
                                                                                * SafetyMap.kMaxSpeed)
                                                                .withVelocityY(controller.getLeftX()
                                                                                * SafetyMap.kMaxSpeed)
                                                                .withRotationalRate(angularRate
                                                                                * SafetyMap.kMaxAngularRate
                                                                                * SafetyMap.kAngularRateMultiplier);
                                        } else {
                                                return DrivetrainConstants.drive
                                                                .withVelocityX(controller.getLeftY()
                                                                                * SafetyMap.kMaxSpeed)
                                                                .withVelocityY(controller.getLeftX()
                                                                                * SafetyMap.kMaxSpeed)
                                                                .withRotationalRate(0);
                                        }

                                        // Get the PID-controlled rotational rate for the robot

                                }));

        }

        /**
         * Configures the orbit mode.
         * 
         * @param controller the driver controller.
         * @param swerve     the swerve subsystem.
         * @return the command to configure orbit mode.
         */
        public Command ConfigureOrbitMode(CommandXboxController controller, SwerveSubsystem swerve) {

                return new ParallelCommandGroup(
                                DrivetrainConstants.drivetrain.applyRequest(() -> {
                                        double angle = Math.atan2(controller.getLeftY(), controller.getLeftX());
                                        double radius = Math.hypot(controller.getLeftX(), controller.getLeftY());
                                        // Return a new swerve drive state
                                        return DrivetrainConstants.robotDrive
                                                        .withVelocityX(Math.cos(angle) * radius * SafetyMap.kMaxSpeed)
                                                        .withVelocityY(Math.sin(angle) * radius * SafetyMap.kMaxSpeed)
                                                        .withRotationalRate(angle * SafetyMap.kMaxAngularRate);
                                }));

        }

}