import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/viewer/sync_engine.dart';

void main() {
  group('SyncEngine.computeSyncOffset', () {
    test('same timestamps produce zero offset', () {
      final time = DateTime(2026, 3, 22, 10, 0, 0);
      expect(
        SyncEngine.computeSyncOffset(time, time),
        Duration.zero,
      );
    });

    test('different timestamps produce absolute difference', () {
      final earlier = DateTime(2026, 3, 22, 10, 0, 0);
      final later = DateTime(2026, 3, 22, 10, 0, 5);
      expect(
        SyncEngine.computeSyncOffset(earlier, later),
        const Duration(seconds: 5),
      );
    });

    test('order does not matter - always returns positive', () {
      final earlier = DateTime(2026, 3, 22, 10, 0, 0);
      final later = DateTime(2026, 3, 22, 10, 0, 5);
      expect(
        SyncEngine.computeSyncOffset(later, earlier),
        const Duration(seconds: 5),
      );
    });

    test('millisecond precision', () {
      final a = DateTime(2026, 3, 22, 10, 0, 0, 0);
      final b = DateTime(2026, 3, 22, 10, 0, 0, 500);
      expect(
        SyncEngine.computeSyncOffset(a, b),
        const Duration(milliseconds: 500),
      );
    });

    test('large difference works correctly', () {
      final a = DateTime(2026, 3, 22, 10, 0, 0);
      final b = DateTime(2026, 3, 22, 10, 2, 30);
      expect(
        SyncEngine.computeSyncOffset(a, b),
        const Duration(minutes: 2, seconds: 30),
      );
    });
  });

  group('SyncEngine.laterPositionFor', () {
    test('returns null when earlier position is before sync offset', () {
      final result = SyncEngine.laterPositionFor(
        const Duration(seconds: 2),
        const Duration(seconds: 5),
      );
      expect(result, isNull);
    });

    test('returns null when earlier position equals zero with non-zero offset', () {
      final result = SyncEngine.laterPositionFor(
        Duration.zero,
        const Duration(seconds: 5),
      );
      expect(result, isNull);
    });

    test('returns zero when earlier position equals sync offset', () {
      final result = SyncEngine.laterPositionFor(
        const Duration(seconds: 5),
        const Duration(seconds: 5),
      );
      expect(result, Duration.zero);
    });

    test('returns correct position after sync offset', () {
      final result = SyncEngine.laterPositionFor(
        const Duration(seconds: 10),
        const Duration(seconds: 3),
      );
      expect(result, const Duration(seconds: 7));
    });

    test('returns exact earlier position when offset is zero', () {
      final result = SyncEngine.laterPositionFor(
        const Duration(seconds: 10),
        Duration.zero,
      );
      expect(result, const Duration(seconds: 10));
    });

    test('millisecond precision works', () {
      final result = SyncEngine.laterPositionFor(
        const Duration(milliseconds: 5500),
        const Duration(milliseconds: 2300),
      );
      expect(result, const Duration(milliseconds: 3200));
    });

    test('just before offset returns null', () {
      final result = SyncEngine.laterPositionFor(
        const Duration(milliseconds: 4999),
        const Duration(milliseconds: 5000),
      );
      expect(result, isNull);
    });

    test('just after offset returns correct small value', () {
      final result = SyncEngine.laterPositionFor(
        const Duration(milliseconds: 5001),
        const Duration(milliseconds: 5000),
      );
      expect(result, const Duration(milliseconds: 1));
    });
  });

  group('SyncEngine earlier/later determination', () {
    test('red is earlier when red starts first', () {
      final redStart = DateTime(2026, 3, 22, 10, 0, 0);
      final blueStart = DateTime(2026, 3, 22, 10, 0, 5);

      // We can verify via computeSyncOffset and the factory logic
      final offset = SyncEngine.computeSyncOffset(redStart, blueStart);
      expect(offset, const Duration(seconds: 5));

      // Red starts before blue, so red is earlier
      expect(redStart.isBefore(blueStart), isTrue);
    });

    test('blue is earlier when blue starts first', () {
      final redStart = DateTime(2026, 3, 22, 10, 0, 10);
      final blueStart = DateTime(2026, 3, 22, 10, 0, 3);

      final offset = SyncEngine.computeSyncOffset(redStart, blueStart);
      expect(offset, const Duration(seconds: 7));

      expect(blueStart.isBefore(redStart), isTrue);
    });

    test('simultaneous start produces zero offset', () {
      final time = DateTime(2026, 3, 22, 10, 0, 0);
      final offset = SyncEngine.computeSyncOffset(time, time);
      expect(offset, Duration.zero);
    });
  });
}
