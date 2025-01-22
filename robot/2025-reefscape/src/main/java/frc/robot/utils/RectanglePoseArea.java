package frc.robot.utils;

import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Translation2d;

/**
 * Class representing a rectangular area for pose calculations.
 */
public class RectanglePoseArea {
  private final Translation2d bottomLeft;
  private final Translation2d topRight;

  /**
   * Create a 2D rectangular area for pose calculations.
   *
   * @param bottomLeft bottom left corner of the rectangle.
   * @param topRight top right corner of the rectangle.
   */
  public RectanglePoseArea(Translation2d bottomLeft, Translation2d topRight) {
    this.bottomLeft = bottomLeft;
    this.topRight = topRight;
  }

  /**
   * Gets the minimum X coordinate of the rectangle.
   * 
   * @return the minimum X coordinate.
   */
  public double getMinX() {
    return bottomLeft.getX();
  }

  /**
   * Gets the maximum X coordinate of the rectangle.
   * 
   * @return the maximum X coordinate.
   */
  public double getMaxX() {
    return topRight.getX();
  }

  /**
   * Gets the minimum Y coordinate of the rectangle.
   * 
   * @return the minimum Y coordinate.
   */
  public double getMinY() {
    return bottomLeft.getY();
  }

  /**
   * Gets the maximum Y coordinate of the rectangle.
   * 
   * @return the maximum Y coordinate.
   */
  public double getMaxY() {
    return topRight.getY();
  }

  /**
   * Gets the bottom left point of the rectangle.
   * 
   * @return the bottom left point.
   */
  public Translation2d getBottomLeftPoint() {
    return bottomLeft;
  }

  /**
   * Gets the top right point of the rectangle.
   * 
   * @return the top right point.
   */
  public Translation2d getTopRightPoint() {
    return topRight;
  }

  /**
   * Checks if a pose is within the rectangular area.
   * 
   * @param pose the pose to check.
   * @return true if the pose is within the area, false otherwise.
   */
  public boolean isPoseWithinArea(Pose2d pose) {
    return pose.getX() >= bottomLeft.getX()
        && pose.getX() <= topRight.getX()
        && pose.getY() >= bottomLeft.getY()
        && pose.getY() <= topRight.getY();
  }
}