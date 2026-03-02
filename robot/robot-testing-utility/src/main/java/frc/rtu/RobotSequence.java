package frc.rtu;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Marks a method as a multi-subsystem sequence test.
 * The method must return a WPILib Command.
 * The Root Testing Utility will schedule the command and wait for it to finish.
 */
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface RobotSequence {
    String name() default "";
    String description() default "";
    int order() default Integer.MAX_VALUE;
    double timeoutSeconds() default 15.0;
}
