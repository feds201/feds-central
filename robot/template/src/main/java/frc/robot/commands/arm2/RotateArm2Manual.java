package frc.robot.commands.arm2;

import java.util.function.DoubleSupplier;

import edu.wpi.first.math.MathUtil;
import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.constants.ArmConstants;
import frc.robot.constants.OIConstants;
import frc.robot.subsystems.ArmSubsystem5;

public class RotateArm2Manual extends CommandBase {
    private final ArmSubsystem5 s_arm;
    private final DoubleSupplier rotatePowerSupplier;

    public RotateArm2Manual(ArmSubsystem5 s_arm, DoubleSupplier rotatePowerSupplier) {
        this.s_arm = s_arm;
        this.rotatePowerSupplier = rotatePowerSupplier;
        addRequirements(s_arm);
    }


    @Override
    public void execute() {
        double power = rotatePowerSupplier.getAsDouble();
        power = MathUtil.applyDeadband(power, OIConstants.kDriverDeadzone);
        power = Math.copySign(Math.pow(power, 2), power);
        power /= 2;
        s_arm.rotate(power * ArmConstants.kArmManualLimiter);
    }

}
