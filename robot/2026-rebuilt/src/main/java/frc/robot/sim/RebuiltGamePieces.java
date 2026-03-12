package frc.robot.sim;

import frc.sim.gamepiece.GamePieceConfig;

/**
 * Game piece configuration for REBUILT 2026 fuel balls.
 */
public class RebuiltGamePieces {
    /** Fuel ball: 6" diameter foam ball, ~0.2kg. */
    public static final GamePieceConfig FUEL = new GamePieceConfig.Builder()
            .withName("Fuel")
            .withShape(GamePieceConfig.Shape.SPHERE)
            .withRadius(0.075) // 75mm radius = 150mm diameter (~6 inches)
            .withMass(0.2) // ~0.2 kg
            .withBounce(0.15) // low bounce — foam on carpet
            .withFriction(0.5) // carpet friction
            .build();
}
