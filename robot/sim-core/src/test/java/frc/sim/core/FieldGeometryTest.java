package frc.sim.core;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.ode4j.ode.*;

import java.io.IOException;
import java.io.InputStream;

import static org.junit.jupiter.api.Assertions.*;
import static org.ode4j.ode.OdeHelper.*;

class FieldGeometryTest {
    private PhysicsWorld world;

    @BeforeEach
    void setUp() {
        world = new PhysicsWorld();
    }

    @Test
    void fieldMeshLoadsWithoutError() throws IOException {
        FieldGeometry field = new FieldGeometry(world);
        InputStream obj = getClass().getResourceAsStream("/test_field.obj");
        assertNotNull(obj, "Test OBJ resource should exist");
        field.loadMesh(obj, TerrainSurface.CARPET);
        assertNotNull(field.getFieldMesh());
    }

    @Test
    void ballDroppedOnFieldBouncesAndStops() throws IOException {
        FieldGeometry field = new FieldGeometry(world);
        InputStream obj = getClass().getResourceAsStream("/test_field.obj");
        field.loadMesh(obj, TerrainSurface.CARPET);

        // Drop a ball from height 2m
        DBody ball = createBody(world.getWorld());
        ball.setPosition(2, 2, 2.0);
        ball.setAutoDisableFlag(false);

        DMass mass = createMass();
        mass.setSphereTotal(0.2, 0.075);
        ball.setMass(mass);

        DGeom geom = createSphere(world.getSpace(), 0.075);
        geom.setBody(ball);

        // Step for 3 seconds
        for (int i = 0; i < 150; i++) {
            world.step(0.02);
        }

        // Ball should be near ground level
        double finalZ = ball.getPosition().get2();
        assertTrue(finalZ < 0.5, "Ball should have settled near ground, got z=" + finalZ);
        assertTrue(finalZ >= 0.0, "Ball should not go below ground");
    }

    @Test
    void boundaryWallsBlockBall() {
        FieldGeometry field = new FieldGeometry(world);
        field.addBoundaryWalls(16.51, 8.04, 0.5, 0.1);

        // Shoot a ball toward the X=0 wall
        DBody ball = createBody(world.getWorld());
        ball.setPosition(1.0, 4.0, 0.2);
        ball.setLinearVel(-5.0, 0, 0);
        ball.setAutoDisableFlag(false);
        ball.setGravityMode(false);

        DMass mass = createMass();
        mass.setSphereTotal(0.2, 0.075);
        ball.setMass(mass);

        DGeom geom = createSphere(world.getSpace(), 0.075);
        geom.setBody(ball);

        for (int i = 0; i < 50; i++) {
            world.step(0.02);
        }

        // Ball should have bounced off wall and not gone past x=0
        double finalX = ball.getPosition().get0();
        assertTrue(finalX > -0.1, "Ball should be blocked by wall, got x=" + finalX);
    }
}
