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

    test('custom exponent changes the curve - lower exponent is more linear', () {
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
}
