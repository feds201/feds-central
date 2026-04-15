// Copyright (c) FIRST and other WPILib contributors.
// Open Source Software; you can modify and/or share it under the terms of
// the WPILib BSD license file in the root directory of this project.

package frc.robot.utils;

import org.littletonrobotics.junction.Logger;

import com.pathplanner.lib.util.FlippingUtil;

import edu.wpi.first.math.geometry.*;
import edu.wpi.first.math.kinematics.ChassisSpeeds;
import edu.wpi.first.wpilibj.DriverStation;
import edu.wpi.first.wpilibj.DriverStation.Alliance;
import frc.robot.RobotMap;
import frc.robot.RobotMap.ShooterConstants;

public class ShootOnTheMove {
    /**
     * Get the field-relative position of the virtual goal
     * 
     * @param robotPose     Field-relative robot pose
     * @param chassisSpeeds Robot-relative of the robot
     * @return The distance to the target goal
     */
    public static Translation2d calculateVirtualGoal(Pose2d robotPose, ChassisSpeeds chassisSpeeds) {
        Translation2d hubCenter = RobotMap.ShooterConstants.hubCenter;
        if (DriverStation.getAlliance().orElse(Alliance.Blue) == Alliance.Red) {
            hubCenter = FlippingUtil.flipFieldPosition(RobotMap.ShooterConstants.hubCenter);
        }

        // Get shooter field position
        Translation2d shooterFieldPosition = getShooterFieldPosition(robotPose);

        // Compute shooter field velocity
        Translation2d shooterVelocity = getShooterFieldVelocity(robotPose, chassisSpeeds);

        // Compute approximate flight time
        double previousDistToGoal = 0;

        // Adjust goal position for motion
        Translation2d virtualGoal = hubCenter;
        for(int i = 0; i <= 10; i++) { 
            double distToGoal = shooterFieldPosition.getDistance(virtualGoal);
            double hoodAngle = ShooterConstants.kShootingPositionMap.get(distToGoal);
            double wheelVelocity = ShooterConstants.kShootingVelocityMap.get(distToGoal);

            // Used WolframAlpha to fit a formula to empirical measures of time of flight.
            // Raw ToF  data: https://docs.google.com/spreadsheets/d/1soxpyImFWBpTkXsz01xsferNdRXlu_cC-2IQG3SakfE
            // Wolfram Code:
            //   Fit[
            //     {{0,0,0}, {1,0,1}, {0,1,1}, {1,1,4}, {2,0,4}, {0,2,4}, {2,2,12}},
            //     {1, x, y, x^2, y^2, x*y},
            //     {x, y}
            //   ]
            double flightTime = -0.000772833 * Math.pow(wheelVelocity, 2)
                              + 0.00465107 * wheelVelocity * hoodAngle
                              + 0.0621835 * wheelVelocity
                              - 0.00218423 * Math.pow(hoodAngle, 2)
                              - 0.136261 * hoodAngle
                              - 0.149612;

            virtualGoal = hubCenter.minus(shooterVelocity.times(flightTime));

            if(Math.abs(previousDistToGoal - distToGoal) <= 0.1) {
                return virtualGoal;
            }

            previousDistToGoal = distToGoal;
        }

        Logger.recordOutput("ShootOnTheMove", new Pose2d(hubCenter, new Rotation2d()));

        return virtualGoal;
    }

    /**
     * Calculates the robot heading required to hit the goal while moving.
     *
     * @param robotPose     Field-relative robot pose
     * @param chassisSpeeds Robot-relative speeds (vx, vy, omega)
     * @return Desired robot heading (field-relative)
     */
    public static Rotation2d calculateRobotHeading(
            Pose2d robotPose,
            ChassisSpeeds chassisSpeeds) {
        // Get shooter field position
        Translation2d shooterFieldPosition = getShooterFieldPosition(robotPose);
        // Compute field-relative angle shooter must point
        Translation2d virtualGoal = calculateVirtualGoal(robotPose, chassisSpeeds);
        Translation2d shooterToGoal = virtualGoal.minus(shooterFieldPosition);
        Logger.recordOutput("VirtualGoal", new Pose2d(virtualGoal.getX(), virtualGoal.getY(), virtualGoal.getAngle()));
  

        Rotation2d shooterFieldAngle = new Rotation2d(
                shooterToGoal.getX(),
                shooterToGoal.getY());

        // Convert to required robot heading
        // θ_robot = θ_shooter_field - θ_RS
        return shooterFieldAngle.minus(RobotMap.ShooterConstants.robotToShooterRotation);
    }

    /**
     * Get the position of the shooter in field-relative coordinates
     * 
     * @param robotPose The current position of the robot
     * @return Field-relative shooter position
     */
    private static Translation2d getShooterFieldPosition(Pose2d robotPose) {

        Transform2d robotToShooter = new Transform2d(ShooterConstants.robotShooterOffset,
                RobotMap.ShooterConstants.robotToShooterRotation);
                //robotPose.getRotation());
        
        Pose2d shooterPose = robotPose.plus(robotToShooter);
        return shooterPose.getTranslation();
    }

    /**
     * gets the rotational + translational velocity experienced by the shooter
     * 
     * @param robotPose Position of the robot
     * @param speeds    Robot-relative x & y speeds of the robot
     * @return total velocity of rotational and translational of shooter relative to
     *         the field
     */
    private static Translation2d getShooterFieldVelocity(
            Pose2d robotPose,
            ChassisSpeeds speeds) {

        // Convert robot-relative speeds to field-relative
        ChassisSpeeds fieldRelative = ChassisSpeeds.fromRobotRelativeSpeeds(
                speeds,
                robotPose.getRotation());

        Translation2d robotFieldVelocity = new Translation2d(
                fieldRelative.vxMetersPerSecond,
                fieldRelative.vyMetersPerSecond);

        // Compute rotational velocity contribution
        Translation2d rotationalVelocity = getRotationalVelocityContribution(
                robotPose.getRotation(),
                speeds.omegaRadiansPerSecond);
        return robotFieldVelocity.plus(rotationalVelocity);
    }

    /**
     * Find Velocity vector due to robot rotation
     * 
     * @param robotHeading Heading of robot in field relative position
     * @param omega        rotational velocity in radians per second
     * @return the rotational velocity contribution represented as translation2d
     */
    private static Translation2d getRotationalVelocityContribution(
            Rotation2d robotHeading,
            double omega) {

        double x = ShooterConstants.robotShooterOffset.getX();
        double y = ShooterConstants.robotShooterOffset.getY();

        // ω × r = (-ω*y, ω*x) (robot frame)
        Translation2d robotFrameRotVel = new Translation2d(
                -omega * y,
                omega * x);

        // Rotate into field frame
        return robotFrameRotVel.rotateBy(robotHeading);
    }
}
