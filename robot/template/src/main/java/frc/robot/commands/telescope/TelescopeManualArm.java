package frc.robot.commands.telescope;

import java.util.function.DoubleSupplier;

import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.subsystems.TelescopeSubsystem;

public class TelescopeManualArm extends CommandBase {

    private final TelescopeSubsystem m_telescopingSubsystem;
    private final DoubleSupplier m_input;

    public TelescopeManualArm(TelescopeSubsystem telescopeSubsystem, DoubleSupplier input) {
        m_telescopingSubsystem = telescopeSubsystem;
        m_input = input;
        addRequirements(telescopeSubsystem);
    }

    @Override
    public void initialize() { 
    }

    @Override
    public void execute() {
        m_telescopingSubsystem.manuallyMove(m_input.getAsDouble()); 
    }
}
