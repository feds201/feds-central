import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/data/models.dart';
import 'package:match_record/notifications/match_notification_builder.dart';

/// Helper to create a Match with sensible defaults.
Match _makeMatch({
  String matchKey = '2026miket_qm1',
  String eventKey = '2026miket',
  String compLevel = 'qm',
  int setNumber = 1,
  int matchNumber = 1,
  int? time,
  int? actualTime,
  int? predictedTime,
  List<String> redTeamKeys = const ['frc201', 'frc217', 'frc4362'],
  List<String> blueTeamKeys = const ['frc1114', 'frc2056', 'frc33'],
  int redScore = -1,
  int blueScore = -1,
}) {
  return Match(
    matchKey: matchKey,
    eventKey: eventKey,
    compLevel: compLevel,
    setNumber: setNumber,
    matchNumber: matchNumber,
    time: time,
    actualTime: actualTime,
    predictedTime: predictedTime,
    redTeamKeys: redTeamKeys,
    blueTeamKeys: blueTeamKeys,
    redScore: redScore,
    blueScore: blueScore,
  );
}

void main() {
  group('MatchNotificationBuilder.build', () {
    const teamNumber = 201;
    const now = 1000000; // arbitrary reference time

    test('includes match within 3-hour window', () {
      final match = _makeMatch(
        time: now + 3600, // 1 hour from now
      );

      final results = MatchNotificationBuilder.build(
        ourMatches: [match],
        allMatches: [match],
        teamNumber: teamNumber,
        nowUnixSeconds: now,
      );

      expect(results, hasLength(1));
      expect(results.first.matchKey, '2026miket_qm1');
    });

    test('excludes match beyond 3-hour window', () {
      final match = _makeMatch(
        time: now + 3 * 3600 + 60, // 3 hours + 1 min
      );

      final results = MatchNotificationBuilder.build(
        ourMatches: [match],
        allMatches: [match],
        teamNumber: teamNumber,
        nowUnixSeconds: now,
      );

      expect(results, isEmpty);
    });

    test('excludes played match (both scores >= 0)', () {
      final match = _makeMatch(
        time: now + 600,
        redScore: 42,
        blueScore: 38,
      );

      final results = MatchNotificationBuilder.build(
        ourMatches: [match],
        allMatches: [match],
        teamNumber: teamNumber,
        nowUnixSeconds: now,
      );

      expect(results, isEmpty);
    });

    test('includes match with only one score (partially played)', () {
      final match = _makeMatch(
        time: now + 600,
        redScore: 42,
        blueScore: -1,
      );

      final results = MatchNotificationBuilder.build(
        ourMatches: [match],
        allMatches: [match],
        teamNumber: teamNumber,
        nowUnixSeconds: now,
      );

      expect(results, hasLength(1));
    });

    test('excludes match with no bestTime', () {
      final match = _makeMatch(); // no time fields set

      final results = MatchNotificationBuilder.build(
        ourMatches: [match],
        allMatches: [match],
        teamNumber: teamNumber,
        nowUnixSeconds: now,
      );

      expect(results, isEmpty);
    });

    test('excludes match more than 5 min in the past', () {
      final match = _makeMatch(
        time: now - 400, // 6+ minutes ago
      );

      final results = MatchNotificationBuilder.build(
        ourMatches: [match],
        allMatches: [match],
        teamNumber: teamNumber,
        nowUnixSeconds: now,
      );

      expect(results, isEmpty);
    });

    test('includes match up to 5 min in the past', () {
      final match = _makeMatch(
        time: now - 200, // ~3 min ago
      );

      final results = MatchNotificationBuilder.build(
        ourMatches: [match],
        allMatches: [match],
        teamNumber: teamNumber,
        nowUnixSeconds: now,
      );

      expect(results, hasLength(1));
    });

    test('detects red alliance side correctly', () {
      final match = _makeMatch(
        time: now + 600,
        redTeamKeys: ['frc201', 'frc217', 'frc4362'],
        blueTeamKeys: ['frc1114', 'frc2056', 'frc33'],
      );

      final results = MatchNotificationBuilder.build(
        ourMatches: [match],
        allMatches: [match],
        teamNumber: 201,
        nowUnixSeconds: now,
      );

      expect(results.first.allianceSide, 'red');
      expect(results.first.title, contains('RED'));
    });

    test('detects blue alliance side correctly', () {
      final match = _makeMatch(
        time: now + 600,
        redTeamKeys: ['frc1114', 'frc2056', 'frc33'],
        blueTeamKeys: ['frc201', 'frc217', 'frc4362'],
      );

      final results = MatchNotificationBuilder.build(
        ourMatches: [match],
        allMatches: [match],
        teamNumber: 201,
        nowUnixSeconds: now,
      );

      expect(results.first.allianceSide, 'blue');
      expect(results.first.title, contains('BLUE'));
    });

    test('title contains match display name', () {
      final match = _makeMatch(
        matchKey: '2026miket_qm15',
        matchNumber: 15,
        time: now + 600,
      );

      final results = MatchNotificationBuilder.build(
        ourMatches: [match],
        allMatches: [match],
        teamNumber: teamNumber,
        nowUnixSeconds: now,
      );

      expect(results.first.title, contains('Q15'));
    });

    test('title includes event short name when provided', () {
      final match = _makeMatch(time: now + 600);

      final results = MatchNotificationBuilder.build(
        ourMatches: [match],
        allMatches: [match],
        teamNumber: teamNumber,
        nowUnixSeconds: now,
        eventShortName: 'MIKET',
      );

      expect(results.first.title, contains('MIKET'));
    });

    test('body shows our teams first, then opponents', () {
      final match = _makeMatch(
        time: now + 600,
        redTeamKeys: ['frc201', 'frc217', 'frc4362'],
        blueTeamKeys: ['frc1114', 'frc2056', 'frc33'],
      );

      final results = MatchNotificationBuilder.build(
        ourMatches: [match],
        allMatches: [match],
        teamNumber: 201,
        nowUnixSeconds: now,
      );

      final body = results.first.body;
      final teamsLine = body.split('\n').first;
      expect(teamsLine, contains('201, 217, 4362'));
      expect(teamsLine, contains('vs'));
      expect(teamsLine, contains('1114, 2056, 33'));
      // Our teams appear before "vs"
      final vsIndex = teamsLine.indexOf('vs');
      expect(teamsLine.indexOf('201'), lessThan(vsIndex));
    });

    test('body shows delayed time with arrow when predicted differs', () {
      final match = _makeMatch(
        time: now + 600,
        predictedTime: now + 900, // 5 min later than scheduled
      );

      final results = MatchNotificationBuilder.build(
        ourMatches: [match],
        allMatches: [match],
        teamNumber: teamNumber,
        nowUnixSeconds: now,
      );

      final body = results.first.body;
      // Should contain arrow between scheduled and estimated
      expect(body, contains('\u2192'));
      expect(body, contains('Est'));
    });

    test('body shows single time when on schedule', () {
      final match = _makeMatch(
        time: now + 600,
        predictedTime: now + 620, // only 20s difference, within 60s threshold
      );

      final results = MatchNotificationBuilder.build(
        ourMatches: [match],
        allMatches: [match],
        teamNumber: teamNumber,
        nowUnixSeconds: now,
      );

      final body = results.first.body;
      expect(body, isNot(contains('\u2192')));
    });

    test('body shows QUEUE NOW when queue time is past', () {
      // Our match is 10 min from now, with 2 matches before it already past
      final m1 = _makeMatch(
        matchKey: '2026miket_qm1',
        matchNumber: 1,
        time: now - 600,
      );
      final m2 = _makeMatch(
        matchKey: '2026miket_qm2',
        matchNumber: 2,
        time: now - 300,
      );
      final ourMatch = _makeMatch(
        matchKey: '2026miket_qm3',
        matchNumber: 3,
        time: now + 600,
      );

      final results = MatchNotificationBuilder.build(
        ourMatches: [ourMatch],
        allMatches: [m1, m2, ourMatch],
        teamNumber: teamNumber,
        nowUnixSeconds: now,
      );

      expect(results.first.body, contains('QUEUE NOW'));
    });

    test('multiple matches sorted by time (soonest first)', () {
      final match1 = _makeMatch(
        matchKey: '2026miket_qm10',
        matchNumber: 10,
        time: now + 7200, // 2 hours
      );
      final match2 = _makeMatch(
        matchKey: '2026miket_qm5',
        matchNumber: 5,
        time: now + 3600, // 1 hour
      );

      final results = MatchNotificationBuilder.build(
        ourMatches: [match1, match2],
        allMatches: [match1, match2],
        teamNumber: teamNumber,
        nowUnixSeconds: now,
      );

      expect(results, hasLength(2));
      expect(results[0].matchKey, '2026miket_qm5');
      expect(results[1].matchKey, '2026miket_qm10');
    });

    test('notification ID is stable for same matchKey', () {
      final match = _makeMatch(time: now + 600);

      final results1 = MatchNotificationBuilder.build(
        ourMatches: [match],
        allMatches: [match],
        teamNumber: teamNumber,
        nowUnixSeconds: now,
      );
      final results2 = MatchNotificationBuilder.build(
        ourMatches: [match],
        allMatches: [match],
        teamNumber: teamNumber,
        nowUnixSeconds: now + 300,
      );

      expect(results1.first.notificationId, results2.first.notificationId);
    });

    test('match at exact 3-hour boundary is included', () {
      final match = _makeMatch(
        time: now + 3 * 3600, // exactly 3 hours
      );

      final results = MatchNotificationBuilder.build(
        ourMatches: [match],
        allMatches: [match],
        teamNumber: teamNumber,
        nowUnixSeconds: now,
      );

      expect(results, hasLength(1));
    });
  });

  group('computeQueueTime', () {
    const now = 1000000;

    test('returns bestTime of match 2 positions before', () {
      final m1 = _makeMatch(matchKey: 'e_qm1', matchNumber: 1, time: now);
      final m2 = _makeMatch(matchKey: 'e_qm2', matchNumber: 2, time: now + 300);
      final m3 = _makeMatch(matchKey: 'e_qm3', matchNumber: 3, time: now + 600);

      final result = MatchNotificationBuilder.computeQueueTime(m3, [m1, m2, m3]);

      expect(result, now); // m1's time
    });

    test('returns match time when first match (no 2-before)', () {
      final m1 = _makeMatch(matchKey: 'e_qm1', matchNumber: 1, time: now);

      final result = MatchNotificationBuilder.computeQueueTime(m1, [m1]);

      expect(result, now); // own time
    });

    test('returns match 1-before when second match', () {
      final m1 = _makeMatch(matchKey: 'e_qm1', matchNumber: 1, time: now);
      final m2 = _makeMatch(matchKey: 'e_qm2', matchNumber: 2, time: now + 300);

      final result = MatchNotificationBuilder.computeQueueTime(m2, [m1, m2]);

      expect(result, now); // m1's time (clamped to index 0)
    });

    test('returns null when match not in allMatches', () {
      final m1 = _makeMatch(matchKey: 'e_qm1', matchNumber: 1, time: now);
      final missing = _makeMatch(matchKey: 'e_qm99', matchNumber: 99, time: now + 600);

      final result = MatchNotificationBuilder.computeQueueTime(missing, [m1]);

      expect(result, isNull);
    });

    test('only considers matches from the same event', () {
      final other = _makeMatch(
        matchKey: 'other_qm1',
        eventKey: 'other_event',
        matchNumber: 1,
        time: now,
      );
      final m1 = _makeMatch(matchKey: 'e_qm1', matchNumber: 1, time: now + 100);
      final m2 = _makeMatch(matchKey: 'e_qm2', matchNumber: 2, time: now + 200);
      final m3 = _makeMatch(matchKey: 'e_qm3', matchNumber: 3, time: now + 300);

      final result = MatchNotificationBuilder.computeQueueTime(
        m3,
        [other, m1, m2, m3],
      );

      // Should use m1 (index 0 in same-event list), not 'other'
      expect(result, now + 100);
    });

    test('skips matches with no bestTime', () {
      final noTime = _makeMatch(matchKey: 'e_qm1', matchNumber: 1);
      final m2 = _makeMatch(matchKey: 'e_qm2', matchNumber: 2, time: now);
      final m3 = _makeMatch(matchKey: 'e_qm3', matchNumber: 3, time: now + 300);
      final m4 = _makeMatch(matchKey: 'e_qm4', matchNumber: 4, time: now + 600);

      final result = MatchNotificationBuilder.computeQueueTime(
        m4,
        [noTime, m2, m3, m4],
      );

      // noTime is excluded, so m2 is at index 0, m3 at 1, m4 at 2
      // 2 before m4 (index 2) = index 0 = m2
      expect(result, now);
    });
  });

  group('payload', () {
    test('quals payload contains alliance partners excluding our team', () {
      final payload = MatchNotificationBuilder.buildPayload(
        matchKey: '2026miket_qm15',
        compLevel: 'qm',
        teamNumber: 201,
        ourTeamKeys: ['frc201', 'frc217', 'frc4362'],
        opponentTeamKeys: ['frc1114', 'frc2056', 'frc33'],
      );

      final parsed = jsonDecode(payload) as Map<String, dynamic>;
      expect(parsed['matchKey'], '2026miket_qm15');
      expect(parsed['compLevel'], 'qm');
      final teams = (parsed['teams'] as List).cast<int>();
      expect(teams, containsAll([217, 4362]));
      expect(teams, isNot(contains(201)));
    });

    test('playoff payload contains opponents', () {
      final payload = MatchNotificationBuilder.buildPayload(
        matchKey: '2026miket_sf1m1',
        compLevel: 'sf',
        teamNumber: 201,
        ourTeamKeys: ['frc201', 'frc217', 'frc4362'],
        opponentTeamKeys: ['frc1114', 'frc2056', 'frc33'],
      );

      final parsed = jsonDecode(payload) as Map<String, dynamic>;
      expect(parsed['compLevel'], 'sf');
      final teams = (parsed['teams'] as List).cast<int>();
      expect(teams, containsAll([1114, 2056, 33]));
    });

    test('parsePayload round-trips correctly', () {
      final payload = MatchNotificationBuilder.buildPayload(
        matchKey: '2026miket_qm15',
        compLevel: 'qm',
        teamNumber: 201,
        ourTeamKeys: ['frc201', 'frc217', 'frc4362'],
        opponentTeamKeys: ['frc1114', 'frc2056', 'frc33'],
      );

      final action = MatchNotificationBuilder.parsePayload(payload);
      expect(action, isNotNull);
      expect(action!.matchKey, '2026miket_qm15');
      expect(action.compLevel, 'qm');
      expect(action.teamNumbers, containsAll([217, 4362]));
    });

    test('parsePayload returns null for invalid JSON', () {
      expect(MatchNotificationBuilder.parsePayload('not json'), isNull);
    });

    test('parsePayload returns null for empty string', () {
      expect(MatchNotificationBuilder.parsePayload(''), isNull);
    });
  });

  group('chronometer target', () {
    const now = 1000000;

    test('chronometer targets queue time when available', () {
      final m1 = _makeMatch(matchKey: 'e_qm1', matchNumber: 1, time: now);
      final m2 = _makeMatch(matchKey: 'e_qm2', matchNumber: 2, time: now + 300);
      final m3 = _makeMatch(matchKey: 'e_qm3', matchNumber: 3, time: now + 600);

      final results = MatchNotificationBuilder.build(
        ourMatches: [m3],
        allMatches: [m1, m2, m3],
        teamNumber: 201,
        nowUnixSeconds: now,
      );

      // Queue time = m1's time (2 before m3)
      expect(results.first.chronometerTargetMs, now * 1000);
    });

    test('chronometer targets match time when no queue match', () {
      final match = _makeMatch(time: now + 600);

      final results = MatchNotificationBuilder.build(
        ourMatches: [match],
        allMatches: [match],
        teamNumber: 201,
        nowUnixSeconds: now,
      );

      // Only match in schedule, so queue time = match time
      expect(results.first.chronometerTargetMs, (now + 600) * 1000);
    });
  });

  group('duration formatting', () {
    const now = 1000000;

    test('shows minutes for durations under 1 hour', () {
      final match = _makeMatch(time: now + 47 * 60); // 47 min

      final results = MatchNotificationBuilder.build(
        ourMatches: [match],
        allMatches: [match],
        teamNumber: 201,
        nowUnixSeconds: now,
      );

      expect(results.first.body, contains('47 min'));
    });

    test('shows hours and minutes for durations over 1 hour', () {
      final match = _makeMatch(time: now + 72 * 60); // 1h 12m

      final results = MatchNotificationBuilder.build(
        ourMatches: [match],
        allMatches: [match],
        teamNumber: 201,
        nowUnixSeconds: now,
      );

      expect(results.first.body, contains('1h 12m'));
    });
  });

  group('playoff match display name in title', () {
    const now = 1000000;

    test('semifinal match shows SF in title', () {
      final match = _makeMatch(
        matchKey: '2026miket_sf1m1',
        compLevel: 'sf',
        setNumber: 2,
        matchNumber: 1,
        time: now + 600,
      );

      final results = MatchNotificationBuilder.build(
        ourMatches: [match],
        allMatches: [match],
        teamNumber: 201,
        nowUnixSeconds: now,
      );

      expect(results.first.title, contains('SF 2'));
    });

    test('final match shows F in title', () {
      final match = _makeMatch(
        matchKey: '2026miket_f1m2',
        compLevel: 'f',
        setNumber: 1,
        matchNumber: 2,
        time: now + 600,
      );

      final results = MatchNotificationBuilder.build(
        ourMatches: [match],
        allMatches: [match],
        teamNumber: 201,
        nowUnixSeconds: now,
      );

      expect(results.first.title, contains('F2'));
    });
  });
}
