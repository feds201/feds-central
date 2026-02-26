package frc.sim.gamepiece;

/**
 * Physical properties for a type of game piece.
 */
public class GamePieceConfig {
    public enum Shape { SPHERE, CYLINDER, BOX }

    private final String name;
    private final Shape shape;
    private final double radius;       // meters (sphere/cylinder radius)
    private final double length;       // meters (cylinder length or box Z dimension)
    private final double width;        // meters (box Y dimension, unused for sphere/cylinder)
    private final double massKg;
    private final double bounce;       // coefficient of restitution
    private final double friction;

    private GamePieceConfig(Builder builder) {
        this.name = builder.name;
        this.shape = builder.shape;
        this.radius = builder.radius;
        this.length = builder.length;
        this.width = builder.width;
        this.massKg = builder.massKg;
        this.bounce = builder.bounce;
        this.friction = builder.friction;
    }

    public String getName() { return name; }
    public Shape getShape() { return shape; }
    public double getRadius() { return radius; }
    public double getLength() { return length; }
    public double getWidth() { return width; }
    public double getMassKg() { return massKg; }
    public double getBounce() { return bounce; }
    public double getFriction() { return friction; }

    public static class Builder {
        private String name = "piece";
        private Shape shape = Shape.SPHERE;
        private double radius = 0.075;
        private double length = 0;
        private double width = 0;
        private double massKg = 0.2;
        private double bounce = 0.3;
        private double friction = 0.5;

        public Builder withName(String name) { this.name = name; return this; }
        public Builder withShape(Shape shape) { this.shape = shape; return this; }
        public Builder withRadius(double radius) { this.radius = radius; return this; }
        public Builder withLength(double length) { this.length = length; return this; }
        public Builder withWidth(double width) { this.width = width; return this; }
        public Builder withMass(double massKg) { this.massKg = massKg; return this; }
        public Builder withBounce(double bounce) { this.bounce = bounce; return this; }
        public Builder withFriction(double friction) { this.friction = friction; return this; }

        public GamePieceConfig build() { return new GamePieceConfig(this); }
    }
}
