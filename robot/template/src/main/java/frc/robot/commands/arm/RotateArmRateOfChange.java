package frc.robot.commands.arm;

import java.util.function.BooleanSupplier;
import java.util.function.DoubleSupplier;

import edu.wpi.first.wpilibj.XboxController;
import edu.wpi.first.wpilibj2.command.CommandBase;

import frc.robot.subsystems.ArmSubsystem;
import frc.robot.utils.ControllerFunctions;
import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.Constants;
import frc.robot.Constants.ArmConstants;

public class RotateArmRateOfChange extends CommandBase{
    private final ArmSubsystem m_arm;
    private final DoubleSupplier m_encoderPositionSupplier;
    private double m_min, m_max;
    private BooleanSupplier m_isActiveSupplier;
    private double multiplier;
    private double position = 0;

    public RotateArmRateOfChange(ArmSubsystem arm, DoubleSupplier rateOfChangeSup, BooleanSupplier isActiveSupplier, double minimum, double maximum, double multiplier){
        this.m_arm = arm;
        this.m_encoderPositionSupplier = rateOfChangeSup;
        this.m_min = minimum;
        this.m_max = maximum;
        this.m_isActiveSupplier = isActiveSupplier;
        this.multiplier = multiplier;


        addRequirements(m_arm);
    }

    @Override
    public void execute(){
        if(m_isActiveSupplier.getAsBoolean()) {
            position += (m_encoderPositionSupplier.getAsDouble() * multiplier);
            m_arm.rotateArmTo(position);
        }
    }  
}
