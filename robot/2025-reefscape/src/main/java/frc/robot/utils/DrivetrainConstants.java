package frc.robot.utils;

import com.ctre.phoenix6.swerve.SwerveModule;
import com.ctre.phoenix6.swerve.SwerveRequest;

import frc.robot.constants.RobotMap.SafetyMap;
import frc.robot.subsystems.swerve.CommandSwerveDrivetrain;
import frc.robot.subsystems.swerve.generated.TunerConstants;

/**
 * The DrivetrainConstants class holds various constants and configurations for the drivetrain.
 */
public final class DrivetrainConstants {
    /**
     * The CommandSwerveDrivetrain instance used for controlling the drivetrain.
     */
    public static CommandSwerveDrivetrain drivetrain = TunerConstants.createDrivetrain();

    /**
     * The FieldCentric drive request configuration with deadbands and open-loop voltage control.
     */
    public static final SwerveRequest.FieldCentric drive = new SwerveRequest.FieldCentric()
            .withDeadband(SafetyMap.kMaxSpeed * 0.04)
            .withRotationalDeadband(SafetyMap.kMaxAngularRate * 0.05)
            .withDriveRequestType(SwerveModule.DriveRequestType.OpenLoopVoltage);

    /**
     * The FieldCentricFacingAngle auto-aim request configuration with open-loop voltage control.
     */
    public static final SwerveRequest.FieldCentricFacingAngle autoAim = new SwerveRequest.FieldCentricFacingAngle()
            .withDriveRequestType(SwerveModule.DriveRequestType.OpenLoopVoltage);

    /**
     * The RobotCentric drive request configuration with deadbands and open-loop voltage control.
     */
    public static final SwerveRequest.RobotCentric robotDrive = new SwerveRequest.RobotCentric()
            .withDeadband(SafetyMap.kMaxSpeed * 0.1)
            .withRotationalDeadband(SafetyMap.kMaxAngularRate * 0.1)
            .withDriveRequestType(SwerveModule.DriveRequestType.OpenLoopVoltage);

    /**
     * The SwerveDriveBrake request configuration for braking.
     */
    public static final SwerveRequest.SwerveDriveBrake brake = new SwerveRequest.SwerveDriveBrake();

    /**
     * The PointWheelsAt request configuration for pointing wheels at a specific angle.
     */
    public static final SwerveRequest.PointWheelsAt point = new SwerveRequest.PointWheelsAt();
}
