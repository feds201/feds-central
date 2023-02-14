package frc.robot.sensors;

import com.ctre.phoenix.sensors.Pigeon2;

import frc.robot.Constants;

public class Pigeon {
    private static Pigeon _instance;
    private final Pigeon2 m_pigeon;

    public static Pigeon getInstance() {
        if (_instance == null) 
            _instance = new Pigeon();
        
        return _instance;
    }

    private Pigeon() {
        this.m_pigeon = new Pigeon2(Constants.SensorConstants.kPigeon);
    }

    public double getYaw() {
        return m_pigeon.getYaw();
    }
}
