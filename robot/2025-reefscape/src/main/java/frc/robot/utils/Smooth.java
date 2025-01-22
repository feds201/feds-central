package frc.robot.utils;

/**
 * Class for smoothing values using a moving average.
 */
public class Smooth {
    private final double[] window;
    private int size, index = 0;
    private double sum = 0.0;

    /**
     * Constructor for Smooth.
     * 
     * @param size the size of the moving average window.
     */
    public Smooth(int size) {
        this.size = size;
        window = new double[size];
    }

    /**
     * Calculates the smoothed value.
     * 
     * @param newValue the new value to add to the window.
     * @return the smoothed value.
     */
    public double calculate(double newValue) {
        sum -= window[index]; // Remove oldest value from sum
        window[index] = newValue; // Add new value to window
        sum += newValue; // Add new value to sum
        index = (index + 1) % size; // Increment index and wrap around
        return sum / size; // Return the average
    }
}