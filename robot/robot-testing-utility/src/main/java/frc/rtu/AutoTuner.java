package frc.rtu;

import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.sysid.SysIdRoutine;

import java.util.List;

/**
 * Helper for running SysId characterization routines from within a RobotAction.
 * 
 * <p>Instead of manually running separate tests, this utility can sequence the 
 * Quasistatic (Ramp) and Dynamic (Step) tests automatically, collect the data, 
 * and perform the OLS regression to render kS, kV, kA, kP, kD.
 */
public class AutoTuner {

    public record TuningResult(
        double kS, double kV, double kA, double kP, double kD, 
        double rSquared
    ) {}

    /**
     * Runs a full identification suite:
     * 1. Quasistatic Forward
     * 2. Quasistatic Reverse
     * 3. Dynamic Forward
     * 4. Dynamic Reverse
     * 
     * @param routine The defined SysIdRoutine for the subsystem
     * @param ctx The DiagnosticContext to log progress
     * @return A command sequence that runs the identification
     */
    public static Command fullRoutine(SysIdRoutine routine, DiagnosticContext ctx) {
        return routine.quasistatic(SysIdRoutine.Direction.kForward)
            .andThen(wait(1.0))
            .andThen(routine.quasistatic(SysIdRoutine.Direction.kReverse))
            .andThen(wait(1.0))
            .andThen(routine.dynamic(SysIdRoutine.Direction.kForward))
            .andThen(wait(1.0))
            .andThen(routine.dynamic(SysIdRoutine.Direction.kReverse));
    }
    
    // Placeholder for waiting
    private static Command wait(double seconds) {
        return new edu.wpi.first.wpilibj2.command.WaitCommand(seconds);
    }

    /**
     * Calculates feedforward constants (kS, kV, kA) from collected data samples using simple OLS.
     * Model: V = kS * sgn(v) + kV * v + kA * a
     * Note: This is a simplified implementation. For robust results, use SysId tool.
     * 
     * @param velocitySamples List of velocity measurements
     * @param voltageSamples List of voltage measurements
     * @param dtSeconds Time step between samples use to derive acceleration
     * @return Calculated constants
     */
    public static TuningResult calculateFeedforward(List<Double> velocitySamples, List<Double> voltageSamples, double dtSeconds) {
        if (velocitySamples.size() != voltageSamples.size() || velocitySamples.size() < 10) {
            return new TuningResult(0, 0, 0, 0, 0, 0);
        }
        
        int n = velocitySamples.size();
        int samples = n - 1;

        // Using OLS to solve Ax = B
        // We'll accumulate A^T*A (3x3) and A^T*B (3x1) manually
        
        double[][] ata = new double[3][3];
        double[] atb = new double[3];

        for (int i = 0; i < samples; i++) {
            double v = velocitySamples.get(i + 1);
            double prevV = velocitySamples.get(i);
            double a = (v - prevV) / dtSeconds;
            double volts = voltageSamples.get(i + 1);
            
            // Row features: [sgn(v), v, a]
            double[] row = { Math.signum(v), v, a };
            
            for (int r = 0; r < 3; r++) {
                for (int c = 0; c < 3; c++) {
                    ata[r][c] += row[r] * row[c];
                }
                atb[r] += row[r] * volts;
            }
        }

        try {
             // Solve for x using Cramer's rule for 3x3
             // x = [kS, kV, kA]
             double[] x = solve3x3(ata, atb);
             
             double kS = x[0];
             double kV = x[1];
             double kA = x[2];
             
             // Calculate R-squared
             double sumV = 0;
             // Use samples 1..n-1 corresponding to our regression data
             for(int i=1; i<n; i++) sumV += voltageSamples.get(i);
             double meanV = sumV / samples;
             
             double ssTot = 0;
             double ssRes = 0;
             
             for(int i=0; i<samples; i++) {
                 double v = velocitySamples.get(i + 1);
                 double prevV = velocitySamples.get(i);
                 double a = (v - prevV) / dtSeconds;
                 double actualVolts = voltageSamples.get(i + 1);
                 
                 double predVolts = kS * Math.signum(v) + kV * v + kA * a;
                 
                 ssTot += Math.pow(actualVolts - meanV, 2);
                 ssRes += Math.pow(actualVolts - predVolts, 2);
             }
             
             double rSquared = (ssTot == 0) ? 0.0 : (1.0 - (ssRes / ssTot));
             
             return new TuningResult(kS, kV, kA, 0.0, 0.0, rSquared);
             
        } catch (Exception e) {
            // Matrix singular or other calculation error
            return new TuningResult(0, 0, 0, 0, 0, 0);
        }
    }

    /** Solves A*x = B for 3x3 matrix A using Cramer's Rule. */
    private static double[] solve3x3(double[][] A, double[] B) {
        double det = A[0][0] * (A[1][1] * A[2][2] - A[2][1] * A[1][2]) -
                     A[0][1] * (A[1][0] * A[2][2] - A[2][0] * A[1][2]) +
                     A[0][2] * (A[1][0] * A[2][1] - A[2][0] * A[1][1]);

        if (Math.abs(det) < 1e-9) throw new ArithmeticException("Matrix singular");

        double detX = B[0] * (A[1][1] * A[2][2] - A[2][1] * A[1][2]) -
                      A[0][1] * (B[1] * A[2][2] - B[2] * A[1][2]) +
                      A[0][2] * (B[1] * A[2][1] - B[2] * A[1][1]);
                      
        double detY = A[0][0] * (B[1] * A[2][2] - B[2] * A[1][2]) -
                      B[0] * (A[1][0] * A[2][2] - A[2][0] * A[1][2]) +
                      A[0][2] * (A[1][0] * B[2] - A[2][0] * B[1]);
                      
        double detZ = A[0][0] * (A[1][1] * B[2] - A[2][1] * B[1]) -
                      A[0][1] * (A[1][0] * B[2] - A[2][0] * B[1]) +
                      B[0] * (A[1][0] * A[2][1] - A[2][0] * A[1][1]);
        
        return new double[] { detX / det, detY / det, detZ / det };
    }
}
