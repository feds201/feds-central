package frc.sim.core;

import org.ode4j.ode.DGeom;

import java.io.IOException;
import java.io.InputStream;

/**
 * Loads field collision geometry (OBJ trimesh or static boxes) into
 * a PhysicsWorld. Subclass for game-specific field layouts.
 */
public class FieldGeometry {
    protected final PhysicsWorld physicsWorld;
    private DGeom fieldMesh;

    public FieldGeometry(PhysicsWorld physicsWorld) {
        this.physicsWorld = physicsWorld;
    }

    /**
     * Load an OBJ mesh as the field collision surface.
     * @param objStream OBJ file contents
     * @param surface contact material to use for this mesh
     */
    public void loadMesh(InputStream objStream, TerrainSurface surface) throws IOException {
        fieldMesh = physicsWorld.loadFieldMesh(objStream);
        physicsWorld.setGeomSurface(fieldMesh, surface);
    }

    /**
     * Add field boundary walls.
     * @param fieldLength field length in meters (X direction)
     * @param fieldWidth field width in meters (Y direction)
     * @param wallHeight wall height in meters
     * @param wallThickness wall thickness in meters
     */
    public void addBoundaryWalls(double fieldLength, double fieldWidth,
                                  double wallHeight, double wallThickness) {
        double halfH = wallHeight / 2.0;
        double halfT = wallThickness / 2.0;

        // X=0 wall (left)
        DGeom w1 = physicsWorld.addStaticBox(wallThickness, fieldWidth, wallHeight,
                -halfT, fieldWidth / 2.0, halfH);
        physicsWorld.setGeomSurface(w1, TerrainSurface.WALL);

        // X=fieldLength wall (right)
        DGeom w2 = physicsWorld.addStaticBox(wallThickness, fieldWidth, wallHeight,
                fieldLength + halfT, fieldWidth / 2.0, halfH);
        physicsWorld.setGeomSurface(w2, TerrainSurface.WALL);

        // Y=0 wall (bottom)
        DGeom w3 = physicsWorld.addStaticBox(fieldLength, wallThickness, wallHeight,
                fieldLength / 2.0, -halfT, halfH);
        physicsWorld.setGeomSurface(w3, TerrainSurface.WALL);

        // Y=fieldWidth wall (top)
        DGeom w4 = physicsWorld.addStaticBox(fieldLength, wallThickness, wallHeight,
                fieldLength / 2.0, fieldWidth + halfT, halfH);
        physicsWorld.setGeomSurface(w4, TerrainSurface.WALL);
    }

    public DGeom getFieldMesh() { return fieldMesh; }
}
