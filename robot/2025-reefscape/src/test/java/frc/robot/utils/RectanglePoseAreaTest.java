package frc.robot.utils;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.geometry.Translation2d;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class RectanglePoseAreaTest {

    @Test
    void testInside() {
        RectanglePoseArea area = new RectanglePoseArea(new Translation2d(0, 0), new Translation2d(10, 10));
        assertTrue(area.isPoseWithinArea(new Pose2d(5, 5, new Rotation2d())), "Point inside rectangle should return true");
    }

    @Test
    void testOutside() {
        RectanglePoseArea area = new RectanglePoseArea(new Translation2d(0, 0), new Translation2d(10, 10));
        assertFalse(area.isPoseWithinArea(new Pose2d(-1, 5, new Rotation2d())), "Point to the left should return false");
        assertFalse(area.isPoseWithinArea(new Pose2d(11, 5, new Rotation2d())), "Point to the right should return false");
        assertFalse(area.isPoseWithinArea(new Pose2d(5, -1, new Rotation2d())), "Point below should return false");
        assertFalse(area.isPoseWithinArea(new Pose2d(5, 11, new Rotation2d())), "Point above should return false");
    }

    @Test
    void testBoundary() {
        RectanglePoseArea area = new RectanglePoseArea(new Translation2d(0, 0), new Translation2d(10, 10));
        assertTrue(area.isPoseWithinArea(new Pose2d(0, 5, new Rotation2d())), "Point on min X boundary should return true");
        assertTrue(area.isPoseWithinArea(new Pose2d(10, 5, new Rotation2d())), "Point on max X boundary should return true");
        assertTrue(area.isPoseWithinArea(new Pose2d(5, 0, new Rotation2d())), "Point on min Y boundary should return true");
        assertTrue(area.isPoseWithinArea(new Pose2d(5, 10, new Rotation2d())), "Point on max Y boundary should return true");
    }

    @Test
    void testCorners() {
        RectanglePoseArea area = new RectanglePoseArea(new Translation2d(0, 0), new Translation2d(10, 10));
        assertTrue(area.isPoseWithinArea(new Pose2d(0, 0, new Rotation2d())), "Bottom-Left corner should return true");
        assertTrue(area.isPoseWithinArea(new Pose2d(10, 0, new Rotation2d())), "Bottom-Right corner should return true");
        assertTrue(area.isPoseWithinArea(new Pose2d(0, 10, new Rotation2d())), "Top-Left corner should return true");
        assertTrue(area.isPoseWithinArea(new Pose2d(10, 10, new Rotation2d())), "Top-Right corner should return true");
    }

    @Test
    void testNegativeCoordinates() {
        RectanglePoseArea area = new RectanglePoseArea(new Translation2d(-10, -10), new Translation2d(-5, -5));
        assertTrue(area.isPoseWithinArea(new Pose2d(-7, -7, new Rotation2d())), "Point inside negative coords rectangle should return true");
        assertFalse(area.isPoseWithinArea(new Pose2d(-11, -7, new Rotation2d())), "Point outside (left) negative coords rectangle should return false");
        assertFalse(area.isPoseWithinArea(new Pose2d(-4, -7, new Rotation2d())), "Point outside (right) negative coords rectangle should return false");
    }
}
