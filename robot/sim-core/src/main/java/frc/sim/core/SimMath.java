package frc.sim.core;

import edu.wpi.first.math.geometry.Pose3d;
import edu.wpi.first.math.geometry.Rotation3d;
import edu.wpi.first.math.geometry.Translation3d;
import org.ode4j.math.DMatrix3C;
import org.ode4j.math.DVector3C;
import org.ode4j.ode.DBody;

/**
 * Utility methods for converting between ODE4J and WPILib types.
 */
public final class SimMath {
    private SimMath() {}

    /**
     * Convert an ODE4J body's position and rotation to a WPILib Pose3d.
     * Uses Euler angle extraction from the rotation matrix to avoid
     * needing the EJML SimpleMatrix dependency.
     */
    public static Pose3d odeToPose3d(DBody body) {
        DVector3C pos = body.getPosition();
        DMatrix3C rot = body.getRotation();
        return new Pose3d(
                new Translation3d(pos.get0(), pos.get1(), pos.get2()),
                odeRotationToRotation3d(rot));
    }

    /**
     * Convert ODE4J 3x3 rotation matrix to WPILib Rotation3d.
     * Extracts roll/pitch/yaw using ZYX intrinsic Euler angles from the matrix.
     *
     * <p>The rotation matrix is: R = Rz(yaw) * Ry(pitch) * Rx(roll), giving:
     * <pre>
     *   R = [ cy*cp   cy*sp*sr - sy*cr   cy*sp*cr + sy*sr ]
     *       [ sy*cp   sy*sp*sr + cy*cr   sy*sp*cr - cy*sr ]
     *       [ -sp     cp*sr              cp*cr             ]
     * </pre>
     * where cy=cos(yaw), sy=sin(yaw), cp=cos(pitch), sp=sin(pitch), etc.
     *
     * <p>From this we extract:
     * <ul>
     *   <li>pitch = asin(-R[2,0]) = asin(sp)</li>
     *   <li>roll  = atan2(R[2,1], R[2,2]) = atan2(cp*sr, cp*cr)</li>
     *   <li>yaw   = atan2(R[1,0], R[0,0]) = atan2(sy*cp, cy*cp)</li>
     * </ul>
     */
    public static Rotation3d odeRotationToRotation3d(DMatrix3C rot) {
        double pitch = Math.asin(-clamp(rot.get20(), -1, 1));
        double roll, yaw;

        if (Math.abs(rot.get20()) < 0.9999) {
            // Normal case: cos(pitch) != 0, so atan2 denominators are valid
            roll = Math.atan2(rot.get21(), rot.get22());
            yaw = Math.atan2(rot.get10(), rot.get00());
        } else {
            // Gimbal lock: pitch is ±90°, cos(pitch) ≈ 0.
            // Roll and yaw become ambiguous (only their sum/difference is defined).
            // Convention: set yaw = 0 and absorb the full rotation into roll.
            roll = Math.atan2(-rot.get12(), rot.get11());
            yaw = 0;
        }

        return new Rotation3d(roll, pitch, yaw);
    }

    private static double clamp(double value, double min, double max) {
        return Math.max(min, Math.min(max, value));
    }
}
