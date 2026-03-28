import 'dart:convert';

import '../data/models.dart';
import '../util/constants.dart';
import '../util/test_flags.dart';

/// Data needed to show a single match notification.
class MatchNotificationData {
  final String matchKey;
  final int notificationId;
  final String title;
  final String body;
  final String allianceSide; // 'red' or 'blue'

  /// The chronometer target time (queue time) in milliseconds since epoch.
  final int chronometerTargetMs;

  /// JSON payload for notification tap action.
  final String payload;

  const MatchNotificationData({
    required this.matchKey,
    required this.notificationId,
    required this.title,
    required this.body,
    required this.allianceSide,
    required this.chronometerTargetMs,
    required this.payload,
  });
}

/// Payload parsed from a notification tap.
class NotificationTapAction {
  final String matchKey;
  final String compLevel;
  final List<int> teamNumbers;

  const NotificationTapAction({
    required this.matchKey,
    required this.compLevel,
    required this.teamNumbers,
  });
}

/// Pure-function builder that computes notification data from match state.
class MatchNotificationBuilder {
  MatchNotificationBuilder._();

  /// Build notification data for all upcoming matches within the notification
  /// window. Returns notifications sorted by match time (soonest first).
  static List<MatchNotificationData> build({
    required List<Match> ourMatches,
    required List<Match> allMatches,
    required int teamNumber,
    required int nowUnixSeconds,
    String? eventShortName,
  }) {
    // Test mode: inject a fake match 15 minutes from now
    if (TestFlags.fakeMatchNotification) {
      final fakeMatch = _buildFakeTestMatch(teamNumber, nowUnixSeconds);
      ourMatches = [fakeMatch];
      allMatches = [
        _buildFakeTestMatch(teamNumber, nowUnixSeconds, offsetSeconds: -720),
        _buildFakeTestMatch(teamNumber, nowUnixSeconds, offsetSeconds: -360),
        fakeMatch,
      ];
    }

    // Sort input by bestTime so output order is soonest-first
    final sortedMatches = List<Match>.from(ourMatches)
      ..sort((a, b) {
        final aTime = a.bestTime ?? 0;
        final bTime = b.bestTime ?? 0;
        return aTime.compareTo(bTime);
      });

    final results = <MatchNotificationData>[];

    for (final match in sortedMatches) {
      final bestTime = match.bestTime;
      if (bestTime == null) continue;

      // Skip matches that have been played (both scores are non-negative)
      if (match.redScore >= 0 && match.blueScore >= 0) continue;

      // Skip matches not within the notification window
      final secondsUntil = bestTime - nowUnixSeconds;
      if (secondsUntil > AppConstants.matchNotificationWindowSeconds) continue;
      if (secondsUntil < -300) continue; // skip matches >5 min in the past

      results.add(_buildNotification(
        match: match,
        allMatches: allMatches,
        teamNumber: teamNumber,
        nowUnixSeconds: nowUnixSeconds,
        eventShortName: eventShortName,
      ));
    }

    return results;
  }

  static MatchNotificationData _buildNotification({
    required Match match,
    required List<Match> allMatches,
    required int teamNumber,
    required int nowUnixSeconds,
    String? eventShortName,
  }) {
    final teamKey = 'frc$teamNumber';
    final isOnRed = match.redTeamKeys.contains(teamKey);
    final allianceSide = isOnRed ? 'red' : 'blue';

    final ourTeamKeys = isOnRed ? match.redTeamKeys : match.blueTeamKeys;
    final opponentTeamKeys = isOnRed ? match.blueTeamKeys : match.redTeamKeys;

    // Build title: "RED -- Q15" or "RED -- Q15 (MIKET)"
    final sideLabel = allianceSide.toUpperCase();
    final matchName = match.displayName;
    final title = eventShortName != null
        ? '$sideLabel \u2014 $matchName ($eventShortName)'
        : '$sideLabel \u2014 $matchName';

    // Build body lines
    final ourTeams = ourTeamKeys.map(_stripFrc).join(', ');
    final oppTeams = opponentTeamKeys.map(_stripFrc).join(', ');
    final teamsLine = '$ourTeams  vs  $oppTeams';

    final timeLine = _buildTimeLine(match);

    final queueTime = computeQueueTime(match, allMatches);
    final bestTime = match.bestTime!;
    final startLine = _buildStartLine(bestTime, queueTime, nowUnixSeconds);

    final body = '$teamsLine\n$timeLine\n$startLine';

    // Chronometer counts down to queue time
    final chronometerTarget = queueTime ?? bestTime;

    // Build payload for tap action
    final payload = buildPayload(
      matchKey: match.matchKey,
      compLevel: match.compLevel,
      teamNumber: teamNumber,
      ourTeamKeys: ourTeamKeys,
      opponentTeamKeys: opponentTeamKeys,
    );

    return MatchNotificationData(
      matchKey: match.matchKey,
      notificationId: match.matchKey.hashCode.abs() % 100000,
      title: title,
      body: body,
      allianceSide: allianceSide,
      chronometerTargetMs: chronometerTarget * 1000,
      payload: payload,
    );
  }

  static String _buildTimeLine(Match match) {
    final scheduled = match.time;
    final predicted = match.predictedTime;
    final actual = match.actualTime;

    // If match has actual time, just show that
    if (actual != null) {
      return _formatTime(actual);
    }

    // If predicted differs from scheduled by >60s, show both
    if (predicted != null && scheduled != null &&
        (predicted - scheduled).abs() > 60) {
      return '${_formatTime(scheduled)} \u2192 Est ${_formatTimeShort(predicted)}';
    }

    // Otherwise just show the best available time
    final best = match.bestTime;
    if (best != null) return _formatTime(best);
    return '';
  }

  static String _buildStartLine(int matchTime, int? queueTime, int nowUnixSeconds) {
    final startDelta = matchTime - nowUnixSeconds;
    final startText = 'Match starts in ${_formatDuration(startDelta)}';

    if (queueTime == null) return startText;

    final queueDelta = queueTime - nowUnixSeconds;
    if (queueDelta <= 0) {
      return '$startText \u00b7 QUEUE NOW';
    }
    return '$startText \u00b7 Queue in ${_formatDuration(queueDelta)}';
  }

  /// Compute queue time: the bestTime of the match ~2 matches before ours.
  static int? computeQueueTime(Match ourMatch, List<Match> allMatches) {
    final eventMatches = allMatches
        .where((m) => m.eventKey == ourMatch.eventKey && m.bestTime != null)
        .toList()
      ..sort((a, b) => a.bestTime!.compareTo(b.bestTime!));

    final ourIndex = eventMatches.indexWhere(
      (m) => m.matchKey == ourMatch.matchKey,
    );
    if (ourIndex < 0) return null;

    final queueIndex = (ourIndex - AppConstants.queueMatchesBefore)
        .clamp(0, eventMatches.length - 1);

    if (queueIndex == ourIndex) {
      // One of the first matches — queue time = match time
      return ourMatch.bestTime;
    }

    final queueMatch = eventMatches[queueIndex];
    return queueMatch.bestTime;
  }

  /// Build JSON payload string for notification tap.
  static String buildPayload({
    required String matchKey,
    required String compLevel,
    required int teamNumber,
    required List<String> ourTeamKeys,
    required List<String> opponentTeamKeys,
  }) {
    // Quals: show alliance partners. Playoffs: show opponents.
    final isQuals = compLevel == 'qm';
    final List<int> teams;
    if (isQuals) {
      // Partners = our alliance minus our team
      teams = ourTeamKeys
          .map((k) => int.tryParse(_stripFrc(k)))
          .where((n) => n != null && n != teamNumber)
          .cast<int>()
          .toList();
    } else {
      // Opponents
      teams = opponentTeamKeys
          .map((k) => int.tryParse(_stripFrc(k)))
          .where((n) => n != null)
          .cast<int>()
          .toList();
    }

    return jsonEncode({
      'matchKey': matchKey,
      'compLevel': compLevel,
      'teams': teams,
    });
  }

  /// Parse a notification tap payload.
  static NotificationTapAction? parsePayload(String payload) {
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      return NotificationTapAction(
        matchKey: map['matchKey'] as String,
        compLevel: map['compLevel'] as String,
        teamNumbers: (map['teams'] as List<dynamic>)
            .map((e) => e as int)
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }

  static String _stripFrc(String key) => key.replaceFirst('frc', '');

  /// Format unix seconds as "Thu 2:30 PM".
  static String _formatTime(int unixSeconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final day = weekdays[dt.weekday - 1];
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$day $hour:$minute $amPm';
  }

  /// Format unix seconds as just "2:30 PM" (no day name, for estimated time).
  static String _formatTimeShort(int unixSeconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }

  /// Format a duration in seconds as "47 min" or "1h 12m".
  static String _formatDuration(int seconds) {
    if (seconds < 0) return '0 min';
    final totalMinutes = (seconds / 60).round();
    if (totalMinutes < 60) return '$totalMinutes min';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    return '${hours}h ${mins}m';
  }

  /// Build a fake Match for test mode.
  static Match _buildFakeTestMatch(
    int teamNumber,
    int nowUnixSeconds, {
    int offsetSeconds = 900, // default 15 min from now
  }) {
    final matchTime = nowUnixSeconds + offsetSeconds;
    final matchNumber = offsetSeconds == 900 ? 42 : (offsetSeconds + 1000);
    final matchKey = offsetSeconds == 900
        ? 'test_event_qm42'
        : 'test_event_qm${matchNumber.abs()}';
    return Match(
      matchKey: matchKey,
      eventKey: 'test_event',
      compLevel: 'qm',
      setNumber: 1,
      matchNumber: matchNumber.abs(),
      time: matchTime,
      predictedTime: matchTime + 60, // 1 min delayed to test delay display
      redTeamKeys: ['frc$teamNumber', 'frc217', 'frc4362'],
      blueTeamKeys: ['frc1114', 'frc2056', 'frc33'],
    );
  }
}
