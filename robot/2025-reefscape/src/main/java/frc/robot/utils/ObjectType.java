package frc.robot.utils;

import edu.wpi.first.networktables.NetworkTable;
import edu.wpi.first.networktables.NetworkTableInstance;

/**
 * Enum representing different object types for vision processing.
 */
public enum ObjectType {
    APRIL_TAG_FRONT("April Tag Front", "This object type is for AprilTags", "limelight-seven", 480, 640, 0.0, 59.6, 45.7),
    APRIL_TAG_BACK("April Tag Back", "This object type is for AprilTags", "limelight-five", 480, 640, 0.0, 59.6, 45.7),
    APRIL_TAG_LEFT("April Tag Left", "This object type is for AprilTags", "limelight-three", 480, 640, 0.0, 59.6, 45.7);


    // INFINITE_CHARGE_BALLS("Infinite Charge Balls", "This object type is for Infinite Charge Balls", "limelight-notes", 480, 640, 0.0, 59.6, 45.7),
    // NOTE("Note", "This object type is for Notes", "limelight-notes", 480, 640, 0.0, 59.6, 45.7);

    private final String name;
    private final String description;
    private final String table;
    private final int cameraHeight;
    private final int cameraWidth;
    private final double targetHeight;
    private final double horizontalFov;
    private final double verticalFov;
    private final NetworkTableInstance tableInstance;

    ObjectType(String name, String description, String table, int cameraHeight, int cameraWidth, double targetHeight, double horizontalFov, double verticalFov) {
        this.name = name;
        this.description = description;
        this.table = table;
        this.cameraHeight = cameraHeight;
        this.cameraWidth = cameraWidth;
        this.targetHeight = targetHeight;
        this.horizontalFov = horizontalFov;
        this.verticalFov = verticalFov;
        this.tableInstance = NetworkTableInstance.getDefault();
    }

    /**
     * Gets the name of the object type.
     * 
     * @return the name.
     */
    public String getName() {
        return name;
    }

    /**
     * Gets the description of the object type.
     * 
     * @return the description.
     */
    public String getDescription() {
        return description;
    }

    /**
     * Gets the network table name for the object type.
     * 
     * @return the network table name.
     */
    public String getTable() {
        return table;
    }

    /**
     * Gets the camera height for the object type.
     * 
     * @return the camera height.
     */
    public int getCameraHeight() {
        return cameraHeight;
    }

    /**
     * Gets the camera width for the object type.
     * 
     * @return the camera width.
     */
    public int getCameraWidth() {
        return cameraWidth;
    }

    /**
     * Gets the target height for the object type.
     * 
     * @return the target height.
     */
    public double getTargetHeight() {
        return targetHeight;
    }

    /**
     * Gets the horizontal field of view for the object type.
     * 
     * @return the horizontal field of view.
     */
    public double getHorizontalFov() {
        return horizontalFov;
    }

    /**
     * Gets the vertical field of view for the object type.
     * 
     * @return the vertical field of view.
     */
    public double getVerticalFov() {
        return verticalFov;
    }

    /**
     * Gets the network table name for the object type.
     * 
     * @return the network table name.
     */
    public NetworkTable getNetworkTable() {
        return tableInstance.getTable(table);
    }

    /**
     * Gets an instance of the object type.
     * 
     * @param type the object type.
     * @return the object type instance.
     */
    public static ObjectType getInstance(ObjectType type) {
        switch (type) {
            case APRIL_TAG_FRONT:
                return APRIL_TAG_FRONT;
            case APRIL_TAG_BACK:
                return APRIL_TAG_BACK;
            case APRIL_TAG_LEFT:
                return APRIL_TAG_LEFT;

            default:
                return null;
        }
    }
}
