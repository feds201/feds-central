package frc.robot.utils;

public class ControllerFunctions {

    // Stack overflow `mapping a numberic range onto another`
    public static double map(double value, double input_start, double input_end, double output_start, double output_end) {
        double slope = (output_end - output_start) / (input_end - input_start);
        return output_start + slope * (value - input_start);
    }
}
