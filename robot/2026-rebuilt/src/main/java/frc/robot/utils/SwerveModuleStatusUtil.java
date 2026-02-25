package frc.robot.utils;

import com.ctre.phoenix6.hardware.CANcoder;
import com.ctre.phoenix6.hardware.TalonFX;

/**
 * Utility class to integrate status and temperature reporting into swerve modules.
 */
public class SwerveModuleStatusUtil {
    public static enum ModuleLocation {
        FL,
        FR,
        BL,
        BR;
    }
    /**
     * Adds a swerve module's motors and encoder to the SubsystemStatusManager and DeviceTempReporter.
     * @param loc The location of the swerve module (FL, FR, BL, BR)
     * @param driveMotorID  ID of the drive motor TalonFX
     * @param steerMotorID ID of the steer motor TalonFX
     * @param encoderID ID of the CANcoder encoder
     */
    public synchronized static void addSwerveModule(ModuleLocation loc, int driveMotorID, int steerMotorID, int encoderID) {
        TalonFX driveMotor = new TalonFX(driveMotorID);
        TalonFX steerMotor = new TalonFX(steerMotorID);
        CANcoder encoder = new CANcoder(encoderID);

        SubsystemStatusManager.addSubsystem("SwerveModule-" + loc.name(), driveMotor, steerMotor, encoder);
        DeviceTempReporter.addDevices(driveMotor, steerMotor);
    }
}
