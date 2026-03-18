package frc.robot.utils;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.function.DoubleConsumer;
import java.util.function.DoubleSupplier;

/**
 * AutoSweeper: runs a loop that sets shooter velocity and hood angle.
 * Supports a fixed-range sweep and a dynamic mode driven by DoubleSuppliers
 * (for example, values coming from the diagnostic dashboard).
 */

/**
 * Utility that runs an automatic sweep of a shooter velocity and sets the hood
 * angle for each step. Thread-safe and designed to be used by RobotContainer or
 * other callers to keep auto-sweep logic out of containers.
 */
public class AutoSweeper {
    private final ExecutorService executor = Executors.newSingleThreadExecutor(r -> new Thread(r, "auto-sweep"));
    private final DoubleConsumer shooterSetter;
    private final DoubleConsumer hoodSetter;

    private volatile boolean running = false;
    private volatile double current = 0.0;
    private volatile Future<?> future = null;

    public AutoSweeper(DoubleConsumer shooterSetter, DoubleConsumer hoodSetter) {
        this.shooterSetter = shooterSetter;
        this.hoodSetter = hoodSetter;
    }

    public synchronized void start(double min, double max, double step, double hoodDeg, int holdMs) {
        stop();
        running = true;
        future = executor.submit(() -> {
            try {
                for (double v = min; v <= max && running; v += step) {
                    current = v;
                    try { shooterSetter.accept(v); } catch (Exception ignored) {}
                    try { hoodSetter.accept(hoodDeg); } catch (Exception ignored) {}
                    try { Thread.sleep(Math.max(10, holdMs)); } catch (InterruptedException ie) { break; }
                }
            } finally {
                running = false;
                future = null;
            }
        });
    }

    /**
     * Start a dynamic sweep driven by suppliers. The suppliers are polled each
     * iteration to obtain the shooter velocity and hood angle. enterTestMode is
     * run before the sweep begins and exitTestMode is run after it finishes.
     */
    public synchronized void startDynamic(DoubleSupplier shooterSupplier, DoubleSupplier hoodSupplier,
                                          Runnable enterTestMode, Runnable exitTestMode, int holdMs) {
        stop();
        running = true;
        future = executor.submit(() -> {
            try {
                if (enterTestMode != null) {
                    try { enterTestMode.run(); } catch (Exception ignored) {}
                }
                while (running) {
                    double v = Double.NaN;
                    double h = Double.NaN;
                    try { v = shooterSupplier.getAsDouble(); } catch (Exception ignored) {}
                    try { h = hoodSupplier.getAsDouble(); } catch (Exception ignored) {}
                    if (!Double.isNaN(v)) {
                        current = v;
                        try { shooterSetter.accept(v); } catch (Exception ignored) {}
                    }
                    if (!Double.isNaN(h)) {
                        try { hoodSetter.accept(h); } catch (Exception ignored) {}
                    }
                    try { Thread.sleep(Math.max(10, holdMs)); } catch (InterruptedException ie) { break; }
                }
            } finally {
                try {
                    if (exitTestMode != null) exitTestMode.run();
                } catch (Exception ignored) {}
                running = false;
                future = null;
            }
        });
    }

    public synchronized void stop() {
        running = false;
        if (future != null) {
            future.cancel(true);
            future = null;
        }
    }

    public boolean isRunning() { return running; }
    public double getCurrent() { return current; }

    public void shutdown() {
        executor.shutdownNow();
    }
}
