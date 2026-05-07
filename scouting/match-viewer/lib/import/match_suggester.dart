import '../data/models.dart';
import 'video_metadata_service.dart';

enum MatchSuggestionConfidence {
  /// Timestamp match or sequential (clear gap)
  high,

  /// Ambiguous gap (between min and max) -- highlight row, require manual
  requiresManual,

  /// No suggestion possible (null timestamps, no schedule, etc.)
  none,
}

class MatchSuggestion {
  final String? matchKey;
  final MatchSuggestionConfidence confidence;

  const MatchSuggestion({
    this.matchKey,
    this.confidence = MatchSuggestionConfidence.none,
  });
}

/// Pure function: suggest match assignment for each video based on
/// recording timestamps and the match schedule.
class MatchSuggester {
  /// Suggest matches for a list of videos.
  ///
  /// [videos] must be sorted by recordingStartTime (ascending).
  /// [schedule] is the list of matches (will be sorted internally by bestTime).
  /// [gapMinMinutes] and [gapMaxMinutes] are the thresholds for sequential logic.
  static List<MatchSuggestion> suggest({
    required List<VideoMetadata> videos,
    required List<Match> schedule,
    required int gapMinMinutes,
    required int gapMaxMinutes,
  }) {
    if (videos.isEmpty) return [];

    if (schedule.isEmpty) {
      return List.filled(
        videos.length,
        const MatchSuggestion(confidence: MatchSuggestionConfidence.none),
      );
    }

    // Sort schedule by bestTime
    final sortedSchedule = List<Match>.from(schedule)
      ..sort((a, b) {
        final aTime = a.bestTime;
        final bTime = b.bestTime;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return aTime.compareTo(bTime);
      });

    final suggestions = <MatchSuggestion>[];
    String? previousMatchKey;

    for (int i = 0; i < videos.length; i++) {
      final video = videos[i];
      final startTime = video.recordingStartTime;

      if (startTime == null) {
        suggestions.add(
          const MatchSuggestion(confidence: MatchSuggestionConfidence.none),
        );
        continue;
      }

      if (i == 0) {
        // First video: nearest match by timestamp
        final nearest = _findNearestMatch(startTime, sortedSchedule);
        if (nearest != null) {
          suggestions.add(MatchSuggestion(
            matchKey: nearest.matchKey,
            confidence: MatchSuggestionConfidence.high,
          ));
          previousMatchKey = nearest.matchKey;
        } else {
          suggestions.add(
            const MatchSuggestion(confidence: MatchSuggestionConfidence.none),
          );
        }
        continue;
      }

      // Subsequent videos: compute gap from previous video
      final prevStartTime = videos[i - 1].recordingStartTime;

      if (prevStartTime == null || previousMatchKey == null) {
        // Can't compute gap; fall back to nearest match
        final nearest = _findNearestMatch(startTime, sortedSchedule);
        if (nearest != null) {
          suggestions.add(MatchSuggestion(
            matchKey: nearest.matchKey,
            confidence: MatchSuggestionConfidence.high,
          ));
          previousMatchKey = nearest.matchKey;
        } else {
          suggestions.add(
            const MatchSuggestion(confidence: MatchSuggestionConfidence.none),
          );
        }
        continue;
      }

      final gapMs =
          startTime.difference(prevStartTime).inMilliseconds;
      final gapMinutes = gapMs / (60 * 1000);

      if (gapMinutes < gapMinMinutes) {
        // Short gap: next sequential match
        final nextMatch =
            _findNextSequentialMatch(previousMatchKey, sortedSchedule);
        if (nextMatch != null) {
          suggestions.add(MatchSuggestion(
            matchKey: nextMatch.matchKey,
            confidence: MatchSuggestionConfidence.high,
          ));
          previousMatchKey = nextMatch.matchKey;
        } else {
          // Beyond end of schedule
          suggestions.add(
            const MatchSuggestion(confidence: MatchSuggestionConfidence.none),
          );
        }
      } else if (gapMinutes > gapMaxMinutes) {
        // Long gap: nearest match by timestamp
        final nearest = _findNearestMatch(startTime, sortedSchedule);
        if (nearest != null) {
          suggestions.add(MatchSuggestion(
            matchKey: nearest.matchKey,
            confidence: MatchSuggestionConfidence.high,
          ));
          previousMatchKey = nearest.matchKey;
        } else {
          suggestions.add(
            const MatchSuggestion(confidence: MatchSuggestionConfidence.none),
          );
        }
      } else {
        // Ambiguous gap: requires manual selection
        // Still try to suggest the next sequential match, but mark as manual
        final nextMatch =
            _findNextSequentialMatch(previousMatchKey, sortedSchedule);
        suggestions.add(MatchSuggestion(
          matchKey: nextMatch?.matchKey,
          confidence: MatchSuggestionConfidence.requiresManual,
        ));
        // Keep previous match key for next iteration's gap calculation
        if (nextMatch != null) {
          previousMatchKey = nextMatch.matchKey;
        }
      }
    }

    return suggestions;
  }

  /// Find the match nearest to the given timestamp.
  static Match? _findNearestMatch(DateTime timestamp, List<Match> schedule) {
    final unixSeconds = timestamp.millisecondsSinceEpoch ~/ 1000;
    Match? nearest;
    int? minDiff;

    for (final m in schedule) {
      final bt = m.bestTime;
      if (bt == null) continue;
      final diff = (unixSeconds - bt).abs();
      if (minDiff == null || diff < minDiff) {
        minDiff = diff;
        nearest = m;
      }
    }

    return nearest;
  }

  /// Find the next match after the given match key in the sorted schedule.
  static Match? _findNextSequentialMatch(
    String currentMatchKey,
    List<Match> sortedSchedule,
  ) {
    for (int i = 0; i < sortedSchedule.length; i++) {
      if (sortedSchedule[i].matchKey == currentMatchKey) {
        if (i + 1 < sortedSchedule.length) {
          return sortedSchedule[i + 1];
        }
        return null; // Beyond end of schedule
      }
    }
    return null; // Match not found in schedule
  }

  /// Cascade match changes from a manual edit at [rowIndex].
  /// Updates subsequent rows with sequential matches until hitting
  /// a manually-set row or the end of the schedule.
  static void cascadeMatchChange({
    required List<MatchSuggestion> suggestions,
    required int rowIndex,
    required String newMatchKey,
    required List<Match> schedule,
    required Set<int> manuallySetRows,
  }) {
    // Sort schedule by bestTime for sequential lookup
    final sortedSchedule = List<Match>.from(schedule)
      ..sort((a, b) {
        final aTime = a.bestTime;
        final bTime = b.bestTime;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return aTime.compareTo(bTime);
      });

    String currentMatchKey = newMatchKey;

    for (int i = rowIndex + 1; i < suggestions.length; i++) {
      // Stop cascading at manually-set rows
      if (manuallySetRows.contains(i)) break;

      final nextMatch =
          _findNextSequentialMatch(currentMatchKey, sortedSchedule);
      if (nextMatch == null) {
        // Beyond end of schedule
        break;
      }

      suggestions[i] = MatchSuggestion(
        matchKey: nextMatch.matchKey,
        confidence: MatchSuggestionConfidence.high,
      );
      currentMatchKey = nextMatch.matchKey;
    }
  }
}
