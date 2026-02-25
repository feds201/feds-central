package frc.sim.scoring;

import java.util.ArrayList;
import java.util.List;

/**
 * Accumulates score and logs events.
 * NT publishing is handled by the game-specific sim manager that has
 * access to the WPILib runtime (JNI not available in unit tests).
 */
public class ScoringTracker {
    /** Maximum number of recent events to keep in the rolling log. */
    private static final int MAX_EVENT_HISTORY = 20;

    private int totalScore = 0;
    private final List<String> events = new ArrayList<>();

    /**
     * Record a scoring event.
     * @param event description of the scoring event (e.g., "High Goal")
     * @param points points to add
     */
    public void markScore(String event, int points) {
        totalScore += points;
        events.add(event + " (+" + points + ")");

        if (events.size() > MAX_EVENT_HISTORY) {
            events.remove(0);
        }
    }

    public int getTotalScore() { return totalScore; }
    public List<String> getEvents() { return new ArrayList<>(events); }

    public void reset() {
        totalScore = 0;
        events.clear();
    }
}
