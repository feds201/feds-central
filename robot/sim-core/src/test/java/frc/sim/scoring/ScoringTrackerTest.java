package frc.sim.scoring;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class ScoringTrackerTest {
    @Test
    void markScoreAccumulatesCorrectly() {
        ScoringTracker tracker = new ScoringTracker();

        tracker.markScore("Low Goal", 1);
        assertEquals(1, tracker.getTotalScore());

        tracker.markScore("High Goal", 3);
        assertEquals(4, tracker.getTotalScore());

        tracker.markScore("High Goal", 3);
        assertEquals(7, tracker.getTotalScore());

        assertEquals(3, tracker.getEvents().size());
    }

    @Test
    void resetClearsScoreAndEvents() {
        ScoringTracker tracker = new ScoringTracker();
        tracker.markScore("Goal", 5);
        tracker.reset();

        assertEquals(0, tracker.getTotalScore());
        assertTrue(tracker.getEvents().isEmpty());
    }
}
