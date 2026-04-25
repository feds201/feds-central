import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/viewer/scrub_controller.dart';

void main() {
  group('ScrubController.computeScrubOffsetMs', () {
    const paneWidth = 500.0;

    test('zero delta returns zero offset', () {
      expect(
        ScrubController.computeScrubOffsetMs(0.0, paneWidth),
        0,
      );
    });

    test('dead zone respected - small delta returns zero', () {
      expect(
        ScrubController.computeScrubOffsetMs(2.0, paneWidth, deadZonePx: 3.0),
        0,
        reason: '2px delta is within the 3px dead zone',
      );
    });

    test('dead zone boundary - exactly at dead zone returns zero', () {
      expect(
        ScrubController.computeScrubOffsetMs(2.9, paneWidth, deadZonePx: 3.0),
        0,
        reason: '2.9px is within the 3px dead zone',
      );
    });

    test('small positive delta produces small positive offset', () {
      final offset = ScrubController.computeScrubOffsetMs(
        10.0,
        paneWidth,
        exponent: 2.5,
        maxRangeMs: 120000,
      );
      expect(offset, greaterThan(0));
      expect(
        offset,
        lessThan(120000),
        reason: 'small delta should not approach max range',
      );
    });

    test('small delta is non-linear - much smaller than linear', () {
      final offset = ScrubController.computeScrubOffsetMs(
        50.0,
        paneWidth,
        exponent: 2.5,
        maxRangeMs: 120000,
      );
      // Linear would be: 50/250 * 120000 = 24000
      // Non-linear with exponent 2.5: (50/250)^2.5 * 120000 ≈ 1072
      expect(
        offset,
        lessThan(5000),
        reason: 'with exponent 2.5, offset should be much less than linear',
      );
      expect(offset, greaterThan(0));
    });

    test('large delta approaches max range', () {
      final offset = ScrubController.computeScrubOffsetMs(
        240.0,
        paneWidth,
        exponent: 2.5,
        maxRangeMs: 120000,
      );
      // normalized = 240/250 = 0.96, pow(0.96, 2.5) ≈ 0.902
      expect(
        offset,
        greaterThan(90000),
        reason: 'near-full-width delta should be close to max range',
      );
    });

    test('full width exactly produces max range', () {
      // deltaX = halfWidth = 250, so normalized = 1.0
      // pow(1.0, 2.5) = 1.0 * 120000 = 120000
      final offset = ScrubController.computeScrubOffsetMs(
        250.0,
        paneWidth,
        exponent: 2.5,
        maxRangeMs: 120000,
      );
      expect(offset, 120000);
    });

    test('beyond full width clamps to max range', () {
      final offset = ScrubController.computeScrubOffsetMs(
        500.0,
        paneWidth,
        exponent: 2.5,
        maxRangeMs: 120000,
      );
      expect(offset, 120000);
    });

    test('negative delta produces negative offset', () {
      final offset = ScrubController.computeScrubOffsetMs(
        -50.0,
        paneWidth,
        exponent: 2.5,
        maxRangeMs: 120000,
      );
      expect(offset, lessThan(0));
    });

    test('negative delta magnitude equals positive delta magnitude', () {
      final positiveOffset = ScrubController.computeScrubOffsetMs(
        50.0,
        paneWidth,
        exponent: 2.5,
        maxRangeMs: 120000,
      );
      final negativeOffset = ScrubController.computeScrubOffsetMs(
        -50.0,
        paneWidth,
        exponent: 2.5,
        maxRangeMs: 120000,
      );
      expect(negativeOffset, -positiveOffset);
    });

    test('custom exponent changes the curve - lower exponent is more linear',
        () {
      final highExp = ScrubController.computeScrubOffsetMs(
        100.0,
        paneWidth,
        exponent: 3.0,
        maxRangeMs: 120000,
      );
      final lowExp = ScrubController.computeScrubOffsetMs(
        100.0,
        paneWidth,
        exponent: 1.5,
        maxRangeMs: 120000,
      );
      expect(
        lowExp,
        greaterThan(highExp),
        reason: 'lower exponent should produce larger offset for same delta',
      );
    });

    test('custom max range scales the result', () {
      final smallRange = ScrubController.computeScrubOffsetMs(
        100.0,
        paneWidth,
        exponent: 2.5,
        maxRangeMs: 60000,
      );
      final largeRange = ScrubController.computeScrubOffsetMs(
        100.0,
        paneWidth,
        exponent: 2.5,
        maxRangeMs: 120000,
      );
      expect(
        largeRange,
        closeTo(smallRange * 2, 1),
        reason: 'doubling max range should double the offset',
      );
    });

    test('zero pane width returns zero', () {
      expect(ScrubController.computeScrubOffsetMs(50.0, 0.0), 0);
    });

    test('negative pane width returns zero', () {
      expect(ScrubController.computeScrubOffsetMs(50.0, -100.0), 0);
    });
  });

  group('ScrubController coalescing timer', () {
    late ScrubController controller;

    setUp(() {
      controller = ScrubController();
    });

    tearDown(() {
      controller.reset();
    });

    test('startCoalescing sets isCoalescing to true', () {
      fakeAsync((async) {
        expect(controller.isCoalescing, isFalse);
        controller.startCoalescing(
          intervalMs: 100,
          onTick: (_) {},
        );
        expect(controller.isCoalescing, isTrue);
        controller.stopCoalescing();
      });
    });

    test('stopCoalescing sets isCoalescing to false', () {
      fakeAsync((async) {
        controller.startCoalescing(
          intervalMs: 100,
          onTick: (_) {},
        );
        controller.stopCoalescing();
        expect(controller.isCoalescing, isFalse);
      });
    });

    test('timer fires onTick with desired position at interval', () {
      fakeAsync((async) {
        final ticks = <Duration>[];
        controller.startCoalescing(
          intervalMs: 100,
          onTick: (pos) => ticks.add(pos),
        );

        controller.updateDesiredPosition(const Duration(seconds: 5));
        async.elapse(const Duration(milliseconds: 100));
        expect(ticks, hasLength(1));
        expect(ticks[0], const Duration(seconds: 5));

        controller.stopCoalescing();
      });
    });

    test('timer does not fire if desired position has not changed', () {
      fakeAsync((async) {
        final ticks = <Duration>[];
        controller.startCoalescing(
          intervalMs: 100,
          onTick: (pos) => ticks.add(pos),
        );

        controller.updateDesiredPosition(const Duration(seconds: 5));
        async.elapse(const Duration(milliseconds: 100));
        expect(ticks, hasLength(1));

        // No update — next tick should not fire
        async.elapse(const Duration(milliseconds: 100));
        expect(ticks, hasLength(1),
            reason: 'no new tick when position unchanged');

        controller.stopCoalescing();
      });
    });

    test('timer fires again when desired position changes', () {
      fakeAsync((async) {
        final ticks = <Duration>[];
        controller.startCoalescing(
          intervalMs: 100,
          onTick: (pos) => ticks.add(pos),
        );

        controller.updateDesiredPosition(const Duration(seconds: 5));
        async.elapse(const Duration(milliseconds: 100));
        expect(ticks, hasLength(1));

        controller.updateDesiredPosition(const Duration(seconds: 10));
        async.elapse(const Duration(milliseconds: 100));
        expect(ticks, hasLength(2));
        expect(ticks[1], const Duration(seconds: 10));

        controller.stopCoalescing();
      });
    });

    test('multiple rapid updates coalesce to latest position', () {
      fakeAsync((async) {
        final ticks = <Duration>[];
        controller.startCoalescing(
          intervalMs: 100,
          onTick: (pos) => ticks.add(pos),
        );

        // Simulate rapid scrub updates (multiple within one timer interval)
        controller.updateDesiredPosition(const Duration(seconds: 1));
        controller.updateDesiredPosition(const Duration(seconds: 3));
        controller.updateDesiredPosition(const Duration(seconds: 7));

        async.elapse(const Duration(milliseconds: 100));
        expect(ticks, hasLength(1));
        expect(ticks[0], const Duration(seconds: 7),
            reason: 'only the latest position should be dispatched');

        controller.stopCoalescing();
      });
    });

    test('timer does not fire if no desired position set', () {
      fakeAsync((async) {
        final ticks = <Duration>[];
        controller.startCoalescing(
          intervalMs: 100,
          onTick: (pos) => ticks.add(pos),
        );

        // No updateDesiredPosition called
        async.elapse(const Duration(milliseconds: 300));
        expect(ticks, isEmpty);

        controller.stopCoalescing();
      });
    });

    test('stopCoalescing returns final position when different from last seeked',
        () {
      fakeAsync((async) {
        controller.startCoalescing(
          intervalMs: 100,
          onTick: (_) {},
        );

        controller.updateDesiredPosition(const Duration(seconds: 5));
        async.elapse(const Duration(milliseconds: 100));

        // Update position but don't let timer tick
        controller.updateDesiredPosition(const Duration(seconds: 8));
        final finalPos = controller.stopCoalescing();
        expect(finalPos, const Duration(seconds: 8));
      });
    });

    test('stopCoalescing returns null when position matches last seeked', () {
      fakeAsync((async) {
        controller.startCoalescing(
          intervalMs: 100,
          onTick: (_) {},
        );

        controller.updateDesiredPosition(const Duration(seconds: 5));
        async.elapse(const Duration(milliseconds: 100));

        // No new update — already seeked to latest
        final finalPos = controller.stopCoalescing();
        expect(finalPos, isNull);
      });
    });

    test('stopCoalescing returns null when no desired position was set', () {
      fakeAsync((async) {
        controller.startCoalescing(
          intervalMs: 100,
          onTick: (_) {},
        );

        final finalPos = controller.stopCoalescing();
        expect(finalPos, isNull);
      });
    });

    test('reset clears coalescing state', () {
      fakeAsync((async) {
        controller.startCoalescing(
          intervalMs: 100,
          onTick: (_) {},
        );
        controller.updateDesiredPosition(const Duration(seconds: 5));
        controller.reset();

        expect(controller.isCoalescing, isFalse);
        expect(controller.desiredPosition, isNull);
        expect(controller.lastSeekedPosition, isNull);
      });
    });

    test('startCoalescing cancels previous timer', () {
      fakeAsync((async) {
        final ticks1 = <Duration>[];
        final ticks2 = <Duration>[];

        controller.startCoalescing(
          intervalMs: 100,
          onTick: (pos) => ticks1.add(pos),
        );
        controller.updateDesiredPosition(const Duration(seconds: 5));

        // Start a new timer before the first fires
        controller.startCoalescing(
          intervalMs: 100,
          onTick: (pos) => ticks2.add(pos),
        );
        controller.updateDesiredPosition(const Duration(seconds: 10));

        async.elapse(const Duration(milliseconds: 100));
        expect(ticks1, isEmpty,
            reason: 'old timer should be cancelled');
        expect(ticks2, hasLength(1));
        expect(ticks2[0], const Duration(seconds: 10));

        controller.stopCoalescing();
      });
    });
  });
}
