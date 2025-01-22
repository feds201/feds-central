package frc.robot.utils;

public class PathPair {
    public int redAlliance;
    public int blueAlliance;
    public String leftpath;
    public String rightpath;


    public PathPair(int redAlliance, int blueAlliance, String leftpath, String rightpath) {
        this.redAlliance = redAlliance;
        this.blueAlliance = blueAlliance;
        this.leftpath = leftpath;
        this.rightpath = rightpath;
    }
    
    public String getLeftPath() {
        return leftpath;
    }

    public String getRightPath() {
        return rightpath;
    }

    public boolean tagToPath(int tag) {
        if (tag == redAlliance) {
            return true;
        } else if (tag == blueAlliance) {
            return true;
        } else {
            return false;
        }
    }

}