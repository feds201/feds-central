package frc.robot.constants;

import edu.wpi.first.math.controller.ArmFeedforward;
import frc.lib.math.Conversions;

public class ArmConstants {
    // Phoenix ID's
    public static final int kArmMotor1 = 52;

    public static final double kArmGearRatio = 250;
    public static final double kSetRobotToTarget = .56;

    public static final double kRotateArmMultiplier = 0.5;
   
    // Feedforward
    //public static final double kS = 0;
    //public static final double kG = 0.08;
    //public static final double kGPercent = kG/12;
    // public static final double kG = 0.044835;
    //public static final double kV = 0;
    //public static final double kA = 0;
    //public static final ArmFeedforward armFeedforward = new ArmFeedforward(kS, kG, kV, kA);
    
    public static final int    peakVelocityUp        = 13360;
    public static final double percentOfPeakUp       = .15;
    public static final double cruiseVelocityAccelUp = peakVelocityUp * percentOfPeakUp;

    public static final int    peakVelocityDown        = 8090;
    public static final double percentOfPeakDown       = .65;
    public static final double cruiseVelocityAccelDown = peakVelocityDown * percentOfPeakDown;

    // PID (Feedback)
    public static final double kPUp   = 0.1;
    public static final double kIUp   = 0;
    public static final double kDUp   = 0;

    public static final double kPDown = 0.1;
    public static final double kIDown = 0;
    public static final double kDDown = 0;
    
    // setpoints
    public static final double kArmHome = 0;
    public static final double kArmPutHigh = Conversions.degreesToFalcon(84.0, ArmConstants.kArmGearRatio);
    public static final double kArmPutMiddle = Conversions.degreesToFalcon(69.0, ArmConstants.kArmGearRatio); // TODO: tune these
    public static final double kArmPutLow = Conversions.degreesToFalcon(40, kArmGearRatio);
    public static final double kArmGrabCone = Conversions.degreesToFalcon(25, kArmGearRatio);
    public static final double kArmAutonPosition = Conversions.degreesToFalcon(77.0, ArmConstants.kArmGearRatio);



    public static final double kArmGoalThreshold = Conversions.degreesToFalcon(5, ArmConstants.kArmGearRatio);
    //public static final double kArmPickConeLeft = Conversions.degreesToFalcon(20, ArmConstants.kArmGearRatio);
    //public static final double kArmPickConeRight = Conversions.degreesToFalcon(25, ArmConstants.kArmGearRatio);
    //public static final double kArmPickCube = Conversions.degreesToFalcon(22.5, ArmConstants.kArmGearRatio);

    public static final double kForwardSoftLimit = Conversions.degreesToFalcon(100, ArmConstants.kArmGearRatio);
    public static final double kReverseSoftLimit = Conversions.degreesToFalcon(-1, kArmGearRatio);
    
    public enum ConeOrientation {
        LEFT,
        RIGHT
    }
}
