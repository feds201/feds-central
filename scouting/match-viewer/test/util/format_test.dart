import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/util/format.dart';

void main() {
  group('formatStopwatch', () {
    test('zero duration', () {
      expect(formatStopwatch(Duration.zero), '0:00.0');
    });

    test('seconds only', () {
      expect(
        formatStopwatch(const Duration(seconds: 5, milliseconds: 300)),
        '0:05.3',
      );
    });

    test('truncates tenths (does not round)', () {
      // 5.349s should display as 5.3, not 5.4 — visual stability when the
      // underlying value samples just below a boundary on consecutive frames.
      expect(
        formatStopwatch(const Duration(seconds: 5, milliseconds: 349)),
        '0:05.3',
      );
    });

    test('minutes and seconds', () {
      expect(
        formatStopwatch(
          const Duration(minutes: 2, seconds: 14, milliseconds: 700),
        ),
        '2:14.7',
      );
    });

    test('pads seconds to two digits', () {
      expect(
        formatStopwatch(const Duration(seconds: 7)),
        '0:07.0',
      );
    });

    test('does not pad minutes', () {
      expect(
        formatStopwatch(const Duration(minutes: 12, seconds: 30)),
        '12:30.0',
      );
    });

    test('negative duration clamps to zero', () {
      expect(formatStopwatch(const Duration(milliseconds: -50)), '0:00.0');
      expect(formatStopwatch(const Duration(seconds: -10)), '0:00.0');
    });

    test('exact minute boundary', () {
      expect(formatStopwatch(const Duration(minutes: 1)), '1:00.0');
    });

    test('999ms is 0.9 (truncated)', () {
      expect(
        formatStopwatch(const Duration(milliseconds: 999)),
        '0:00.9',
      );
    });
  });

  group('formatPlaybackSpeed', () {
    test('1.0x', () {
      expect(formatPlaybackSpeed(1.0), '1.00x');
    });

    test('0.25x', () {
      expect(formatPlaybackSpeed(0.25), '0.25x');
    });

    test('2.5x', () {
      expect(formatPlaybackSpeed(2.5), '2.50x');
    });

    test('3.0x', () {
      expect(formatPlaybackSpeed(3.0), '3.00x');
    });
  });
}
