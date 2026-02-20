package frc.sim.core;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.ode4j.math.DVector3C;
import org.ode4j.ode.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.ode4j.ode.OdeHelper.*;

class PhysicsWorldTest {
    private PhysicsWorld world;

    @BeforeEach
    void setUp() {
        world = new PhysicsWorld();
    }

    @Test
    void worldStepsWithoutError() {
        // Should not throw
        for (int i = 0; i < 100; i++) {
            world.step(0.02);
        }
    }

    @Test
    void staticBoxBlocksDynamicSphere() {
        // Place a box at x=2, y=0, z=0.5 (1m cube on the ground)
        world.addStaticBox(1, 1, 1, 2, 0, 0.5);

        // Create a dynamic sphere rolling toward the box
        DBody ball = createBody(world.getWorld());
        ball.setPosition(0.5, 0, 0.15);
        ball.setLinearVel(2.0, 0, 0); // moving toward box at 2m/s

        DMass mass = createMass();
        mass.setSphereTotal(0.2, 0.1);
        ball.setMass(mass);
        ball.setAutoDisableFlag(false);

        DGeom geom = createSphere(world.getSpace(), 0.1);
        geom.setBody(ball);

        // Step for 2 seconds
        for (int i = 0; i < 100; i++) {
            world.step(0.02);
        }

        // Ball should have been stopped by the box — X should be less than 2.0
        double finalX = ball.getPosition().get0();
        assertTrue(finalX > 0.5 && finalX < 1.5, "Ball should stop at wall face minus radius, got x=" + finalX);
    }

    @Test
    void sphereFallsUnderGravity() {
        DBody ball = createBody(world.getWorld());
        ball.setPosition(5, 5, 2.0);
        ball.setAutoDisableFlag(false);

        DMass mass = createMass();
        mass.setSphereTotal(0.2, 0.1);
        ball.setMass(mass);

        DGeom geom = createSphere(world.getSpace(), 0.1);
        geom.setBody(ball);

        // Step for 1 second
        for (int i = 0; i < 50; i++) {
            world.step(0.02);
        }

        // Should have fallen and bounced on ground plane (z should be near ground)
        double finalZ = ball.getPosition().get2();
        assertTrue(finalZ < 0.3, "Ball should be near ground after 1s free fall, got z=" + finalZ);
        assertTrue(finalZ >= 0.0, "Ball should not go below ground");
    }

    @Test
    void sleepingBodyWakesOnContact() {
        // Create a stationary ball (will auto-disable / sleep)
        // Elevated and gravity-free so ground friction doesn't interfere
        DBody stationaryBall = createBody(world.getWorld());
        stationaryBall.setPosition(2, 0, 1.0);
        stationaryBall.setAutoDisableFlag(true);
        stationaryBall.setGravityMode(false);

        DMass mass1 = createMass();
        mass1.setSphereTotal(0.2, 0.1);
        stationaryBall.setMass(mass1);

        DGeom geom1 = createSphere(world.getSpace(), 0.1);
        geom1.setBody(stationaryBall);

        // Let it sleep
        for (int i = 0; i < 100; i++) {
            world.step(0.02);
        }

        // Create a moving ball heading toward the sleeping one (close, fast, no gravity)
        DBody movingBall = createBody(world.getWorld());
        movingBall.setPosition(1, 0, 1.0);
        movingBall.setLinearVel(5.0, 0, 0);
        movingBall.setAutoDisableFlag(false);
        movingBall.setGravityMode(false);

        DMass mass2 = createMass();
        mass2.setSphereTotal(0.2, 0.1);
        movingBall.setMass(mass2);

        DGeom geom2 = createSphere(world.getSpace(), 0.1);
        geom2.setBody(movingBall);

        // Step until collision
        for (int i = 0; i < 50; i++) {
            world.step(0.02);
        }

        // Stationary ball should have been woken and moved
        DVector3C stationaryPos = stationaryBall.getPosition();
        assertTrue(stationaryPos.get0() > 2.0,
                "Sleeping ball should wake and move when hit, got x=" + stationaryPos.get0());
    }

    @Test
    void sensorDetectsOverlapWithoutPhysics() {
        // Create a sensor as a static geom (no body) — like an intake zone
        DGeom sensorGeom = createSphere(world.getSpace(), 0.3);
        sensorGeom.setPosition(2, 0, 1.0);
        world.registerSensor(sensorGeom);

        // Create a dynamic ball heading toward sensor
        DBody ball = createBody(world.getWorld());
        ball.setPosition(0.5, 0, 1.0);
        ball.setLinearVel(5.0, 0, 0);
        ball.setAutoDisableFlag(false);
        ball.setGravityMode(false);

        DMass ballMass = createMass();
        ballMass.setSphereTotal(0.2, 0.1);
        ball.setMass(ballMass);

        DGeom ballGeom = createSphere(world.getSpace(), 0.1);
        ballGeom.setBody(ball);

        // Step until the ball reaches the sensor area
        boolean detected = false;
        for (int i = 0; i < 50; i++) {
            world.step(0.02);
            if (world.getSensorContacts(sensorGeom).contains(ball)) {
                detected = true;
            }
        }

        assertTrue(detected, "Sensor should have detected the ball");

        // Ball should pass through sensor (not be blocked)
        // World damping (5%/step) slows the ball, so it won't travel as far as v*t
        double finalX = ball.getPosition().get0();
        assertTrue(finalX > 2.0, "Ball should pass through sensor, got x=" + finalX);
    }
}
