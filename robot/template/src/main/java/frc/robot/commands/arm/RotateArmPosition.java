package frc.robot.commands.arm;

import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.subsystems.ArmSubsystem4;

public class RotateArmPosition extends CommandBase {
    private final double m_position;
    private final ArmSubsystem4 s_arm;

    public RotateArmPosition(ArmSubsystem4 s_arm, double position) {
        this.s_arm = s_arm;
        addRequirements(s_arm);

        this.m_position = position;
    }
    
    @Override
    public void initialize() {
        s_arm.setPosition(this.m_position);
    }

}
