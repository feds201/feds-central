package frc.robot.utils;

import edu.wpi.first.networktables.NetworkTable;
import edu.wpi.first.networktables.NetworkTableEntry;
import frc.robot.constants.RobotMap.VisionMap;

public class VisionObject {
    private double x;
    private double y;
    private double area;
    private ObjectType type;
    private static NetworkTable table;
    private NetworkTableEntry txEntry;
    private NetworkTableEntry tyEntry;
    private NetworkTableEntry taEntry;
    private NetworkTableEntry tvEntry;

    public VisionObject(double x, double y, double area, ObjectType type) {
        table = type.getNetworkTable();
        this.x = x;
        this.y = y;
        this.area = area;
        this.type = type;
        initializeEntries();
    }

    private void initializeEntries() {
        txEntry = table.getEntry("tx");
        tyEntry = table.getEntry("ty");
        taEntry = table.getEntry("ta");
        tvEntry = table.getEntry("tv");
    }

    public void updateVisionData() {
        this.x = txEntry.getDouble(0);
        this.y = tyEntry.getDouble(0);
        this.area = taEntry.getDouble(0);
    }

    public double getX() {
        return x;
    }

    public boolean isPresent() {
        return tvEntry.getDouble(0) == 1.0;
    }

    public void setX(double x) {
        this.x = x;
    }

    public double getY() {
        return y;
    }

    public void setY(double y) {
        this.y = y;
    }

    public double getArea() {
        return area;
    }

    public void setArea(double area) {
        this.area = area;
    }

    public void update(double x, double y, double area) {
        this.x = x;
        this.y = y;
        this.area = area;
    }

    public ObjectType getType() {
        return type;
    }

    public void setType(ObjectType type) {
        this.type = type;
        table = type.getNetworkTable();
        initializeEntries();
    }

    public double[] getAngle() {
        double[] angle = new double[2];
        double nx = (1.0 / (type.getCameraWidth() / 2)) * (x - (type.getCameraWidth() / 2 - 0.5));
        double ny = (1.0 / (type.getCameraHeight() / 2)) * (y - (type.getCameraHeight() / 2 - 0.5));
        double vpw = 2.0 * Math.tan(type.getHorizontalFov() / 2);
        double vph = 2.0 * Math.tan(type.getVerticalFov() / 2);
        double x = vpw / 2 * nx;
        double y = vph / 2 * ny;
        double ax = Math.atan2(1, x);
        double ay = Math.atan2(1, y);
        angle[0] = Math.toDegrees(ax);
        angle[1] = Math.toDegrees(ay);
        return angle;
    }

    public double getYaw() {
        return getAngle()[0];
    }

    public double getPitch() {
        return getAngle()[1];
    }

    public double getDistance() {
        double targetOffsetAngle_Vertical = y;
        double limelightMountAngleDegrees = VisionMap.cameraAngle;
        double limelightLensHeightMetres = VisionMap.cameraHeight;
        double goalHeightMetres = VisionMap.targetHeight;
        double angleToGoalDegrees = limelightMountAngleDegrees + targetOffsetAngle_Vertical;
        double angleToGoalRadians = Math.toRadians(angleToGoalDegrees);
        return (goalHeightMetres - limelightLensHeightMetres) / Math.tan(angleToGoalRadians);
    }

    public void logVisionData() {
        System.out.println("Vision Data - X: " + x + ", Y: " + y + ", Area: " + area + ", Type: " + type);
    }

    public void resetVisionData() {
        this.x = 0;
        this.y = 0;
        this.area = 0;
    }

    public double getAreaPercentage() {
        return (area / (type.getCameraWidth() * type.getCameraHeight())) * 100;
    }

    public double getAspectRatio() {
        return type.getCameraWidth() / type.getCameraHeight();
    }

    public double[] getCenterOffset() {
        double[] offset = new double[2];
        offset[0] = x - (type.getCameraWidth() / 2);
        offset[1] = y - (type.getCameraHeight() / 2);
        return offset;
    }
}