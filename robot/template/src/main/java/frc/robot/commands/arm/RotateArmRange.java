// package frc.robot.commands.arm;

// import java.util.function.BooleanSupplier;
// import java.util.function.DoubleSupplier;

// import edu.wpi.first.wpilibj.XboxController;
// import edu.wpi.first.wpilibj2.command.CommandBase;

// import frc.robot.subsystems.ArmSubsystem;
// import frc.robot.utils.ControllerFunctions;
// import edu.wpi.first.wpilibj2.command.CommandBase;
// import frc.robot.Constants;
// import frc.robot.Constants.ArmConstants;

// public class RotateArmRange extends CommandBase{
//     private final ArmSubsystem m_arm;
//     private final DoubleSupplier m_encoderPositionSupplier;
//     private double m_min, m_max;
//     private BooleanSupplier m_isActiveSupplier;

//     public RotateArmRange(ArmSubsystem arm, DoubleSupplier positionSupplier, BooleanSupplier isActiveSupplier, double minimum, double maximum){
//         this.m_arm = arm;
//         this.m_encoderPositionSupplier = positionSupplier;
//         this.m_min = minimum;
//         this.m_max = maximum;
//         this.m_isActiveSupplier = isActiveSupplier;


//         addRequirements(m_arm);
//     }

//     @Override
//     public void execute(){
//         if(m_isActiveSupplier.getAsBoolean()) {
//             m_arm.rotateArmTo(ControllerFunctions.map(m_encoderPositionSupplier.getAsDouble(), -1, 1, m_min, m_max));
//         }
//     }  
// }
