package frc.robot.commands.claw;

import edu.wpi.first.wpilibj2.command.CommandBase;
import frc.robot.subsystems.ClawSubsystem;

public class OuttakeCone extends CommandBase {
    private final ClawSubsystem s_claw;
    public OuttakeCone(ClawSubsystem s_claw) {
        this.s_claw = s_claw;
        addRequirements(s_claw);
    }

    @Override
    public void execute() {
        this.s_claw.outtakeCone();
    }
}
