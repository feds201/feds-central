package frc.robot.utils.RTU;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Marks a method on a {@link edu.wpi.first.wpilibj2.command.SubsystemBase} as
 * a testable robot action.  The Root Testing Utility discovers these at
 * runtime via reflection and runs them when the robot enters <b>Test mode</b>.
 *
 * <h3>Method contract</h3>
 * <ul>
 *   <li><b>{@code boolean} return</b> – returns {@code true} to pass,
 *       {@code false} to fail.</li>
 *   <li><b>{@code void} return</b> – passes if it completes without throwing;
 *       any {@link Throwable} means failure.</li>
 * </ul>
 *
 * Methods may be {@code public} or {@code protected} (the scanner
 * uses {@code getDeclaredMethods}).
 */
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface RobotAction {
    /** Human-readable test name.  Defaults to the method name. */
    String name() default "";

    /** Short description of what this test validates. */
    String description() default "";

    /** Execution order — lower values run first. */
    int order() default Integer.MAX_VALUE;

    /** Maximum time (seconds) the test may take before it is auto-failed. */
    double timeoutSeconds() default 5.0;
}
