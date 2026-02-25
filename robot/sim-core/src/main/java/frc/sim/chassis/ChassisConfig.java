package frc.sim.chassis;

import edu.wpi.first.math.geometry.Translation2d;

/**
 * Configuration for swerve drive chassis simulation.
 * Encapsulates the physical chassis properties needed by ODE4J.
 * Motor/tire physics are owned by MapleSim's SwerveModuleSimulation.
 */
public class ChassisConfig {
    private final Translation2d[] modulePositions;
    private final double robotMassKg;
    private final double robotMOI; // moment of inertia about z-axis (kg*m^2)
    private final double bumperLengthX; // meters (front-to-back)
    private final double bumperWidthY; // meters (left-to-right)
    private final double bumperHeight; // meters

    private ChassisConfig(Builder builder) {
        this.modulePositions = builder.modulePositions;
        this.robotMassKg = builder.robotMassKg;
        this.robotMOI = builder.robotMOI;
        this.bumperLengthX = builder.bumperLengthX;
        this.bumperWidthY = builder.bumperWidthY;
        this.bumperHeight = builder.bumperHeight;
    }

    public Translation2d[] getModulePositions() { return modulePositions; }
    public double getRobotMassKg() { return robotMassKg; }
    public double getRobotMOI() { return robotMOI; }
    public double getBumperLengthX() { return bumperLengthX; }
    public double getBumperWidthY() { return bumperWidthY; }
    public double getBumperHeight() { return bumperHeight; }

    public static class Builder {
        private Translation2d[] modulePositions;
        private double robotMassKg = 50.0;
        private double robotMOI = 6.0;
        private double bumperLengthX = 0.8;
        private double bumperWidthY = 0.8;
        private double bumperHeight = 0.2;

        public Builder withModulePositions(Translation2d... positions) {
            this.modulePositions = positions;
            return this;
        }

        public Builder withRobotMass(double massKg) {
            this.robotMassKg = massKg;
            return this;
        }

        public Builder withRobotMOI(double moi) {
            this.robotMOI = moi;
            return this;
        }

        public Builder withBumperSize(double lengthX, double widthY, double height) {
            this.bumperLengthX = lengthX;
            this.bumperWidthY = widthY;
            this.bumperHeight = height;
            return this;
        }

        public ChassisConfig build() {
            if (modulePositions == null || modulePositions.length != 4) {
                throw new IllegalStateException("Must provide exactly 4 module positions (FL, FR, BL, BR)");
            }
            return new ChassisConfig(this);
        }
    }
}
