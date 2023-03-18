package frc.robot.commands.arm;

import java.util.function.DoubleSupplier;

import edu.wpi.first.wpilibj2.command.CommandBase;
import edu.wpi.first.wpilibj2.command.SequentialCommandGroup;
import edu.wpi.first.wpilibj2.command.WaitCommand;
import frc.robot.subsystems.ArmSubsystem4;


public class RotateArmManual extends CommandBase {
    private final ArmSubsystem4 s_arm;
    private final DoubleSupplier rotateSpeed;
    
    public RotateArmManual(ArmSubsystem4 s_arm, DoubleSupplier rotateSpeed) {
     this.s_arm = s_arm;
     this.rotateSpeed = rotateSpeed;
     addRequirements(s_arm);
    }

    @Override
    public void initialize() {

    }
    @Override
    public void execute() {
        s_arm.manualArmRotate(rotateSpeed.getAsDouble());
    }

}
