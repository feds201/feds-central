package frc.robot.constants;

import java.util.Map;
import java.util.function.BooleanSupplier;

import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardTab;

public class ComandCenter {
    public static ShuffleboardTab tab = Shuffleboard.getTab("Comand Center");

    private static boolean wristFailureAdded = false;
    private static boolean AimToBallAdded = false;

    public static void init(){
        tab = Shuffleboard.getTab("Comand Center");
    }

    public static void addWristFailure(boolean failure){
        if(!wristFailureAdded){
            tab.addBoolean("Wrist Okay?", () -> failure).withProperties(Map.of("colorWhenTrue", "red", "colorWhenFalse", "green"));
            wristFailureAdded = true;
        }
    }


    public static void addAimToBallCommand(BooleanSupplier isEnnabled){
        if(!AimToBallAdded){
            tab.addBoolean("AimToBallCommand", isEnnabled).withProperties(Map.of("colorWhenTrue", "red", "colorWhenFalse", "blue"));
            AimToBallAdded = true;
        }
    }
}
