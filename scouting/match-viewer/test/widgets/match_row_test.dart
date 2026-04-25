import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/data/models.dart';
import 'package:match_record/widgets/match_row.dart';

void main() {
  group('MatchRow.formatTime', () {
    test('returns empty string for null', () {
      expect(MatchRow.formatTime(null), '');
    });

    test('formats afternoon time correctly', () {
      // 2026-03-23 14:30:00 UTC -> Mon 2:30 PM (depends on local timezone)
      // Use a known timestamp instead
      final dt = DateTime(2026, 3, 23, 14, 30);
      final unixSeconds = dt.millisecondsSinceEpoch ~/ 1000;
      final result = MatchRow.formatTime(unixSeconds);
      expect(result, contains('2:30 PM'));
      expect(result, contains('Mon'));
    });

    test('formats morning time correctly', () {
      final dt = DateTime(2026, 3, 23, 9, 5);
      final unixSeconds = dt.millisecondsSinceEpoch ~/ 1000;
      final result = MatchRow.formatTime(unixSeconds);
      expect(result, contains('9:05 AM'));
    });

    test('formats midnight as 12:00 AM', () {
      final dt = DateTime(2026, 3, 23, 0, 0);
      final unixSeconds = dt.millisecondsSinceEpoch ~/ 1000;
      final result = MatchRow.formatTime(unixSeconds);
      expect(result, contains('12:00 AM'));
    });

    test('formats noon as 12:00 PM', () {
      final dt = DateTime(2026, 3, 23, 12, 0);
      final unixSeconds = dt.millisecondsSinceEpoch ~/ 1000;
      final result = MatchRow.formatTime(unixSeconds);
      expect(result, contains('12:00 PM'));
    });
  });

  group('MatchRow.shouldShowDelayedTime', () {
    Match _makeMatch({
      int? time,
      int? actualTime,
      int? predictedTime,
    }) {
      return Match(
        matchKey: '2026mimid_qm1',
        eventKey: '2026mimid',
        compLevel: 'qm',
        setNumber: 1,
        matchNumber: 1,
        time: time,
        actualTime: actualTime,
        predictedTime: predictedTime,
        redTeamKeys: ['frc201'],
        blueTeamKeys: ['frc254'],
      );
    }

    test('returns false when actualTime is set', () {
      final m = _makeMatch(
        time: 1000,
        actualTime: 1200,
        predictedTime: 1200,
      );
      expect(MatchRow.shouldShowDelayedTime(m), false);
    });

    test('returns false when predictedTime is null', () {
      final m = _makeMatch(time: 1000);
      expect(MatchRow.shouldShowDelayedTime(m), false);
    });

    test('returns false when time is null', () {
      final m = _makeMatch(predictedTime: 1200);
      expect(MatchRow.shouldShowDelayedTime(m), false);
    });

    test('returns false when predicted differs by <= 60 seconds', () {
      final m = _makeMatch(time: 1000, predictedTime: 1060);
      expect(MatchRow.shouldShowDelayedTime(m), false);
    });

    test('returns false when predicted differs by exactly 60 seconds', () {
      final m = _makeMatch(time: 1000, predictedTime: 1060);
      expect(MatchRow.shouldShowDelayedTime(m), false);
    });

    test('returns true when predicted differs by > 60 seconds (later)', () {
      final m = _makeMatch(time: 1000, predictedTime: 1061);
      expect(MatchRow.shouldShowDelayedTime(m), true);
    });

    test('returns true when predicted differs by > 60 seconds (earlier)', () {
      final m = _makeMatch(time: 1000, predictedTime: 939);
      expect(MatchRow.shouldShowDelayedTime(m), true);
    });

    test('returns true for large delay', () {
      final m = _makeMatch(time: 1000, predictedTime: 2000);
      expect(MatchRow.shouldShowDelayedTime(m), true);
    });
  });
}
