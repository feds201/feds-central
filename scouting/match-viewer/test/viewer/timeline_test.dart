import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/viewer/timeline.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Test double for a [TimelineSource]. Tests drive `emit*` methods to
/// simulate position/duration/completed events from the underlying player,
/// and assert on the recorded `play/pause/seek/setVolume` calls.
class FakeSource implements TimelineSource {
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _completedController = StreamController<bool>.broadcast();
  final _widthController = StreamController<int?>.broadcast();
  final _heightController = StreamController<int?>.broadcast();

  bool _isPlaying = false;
  Duration currentPosition = Duration.zero;
  double currentVolume = 0;
  double currentRate = 1.0;
  bool disposed = false;

  // Test introspection
  int playCalls = 0;
  int pauseCalls = 0;
  final List<Duration> seekCalls = [];
  final List<double> volumeCalls = [];
  final List<double> rateCalls = [];

  @override
  Stream<Duration> get positionStream => _positionController.stream;
  @override
  Stream<Duration> get durationStream => _durationController.stream;
  @override
  Stream<bool> get completedStream => _completedController.stream;
  @override
  Stream<int?> get widthStream => _widthController.stream;
  @override
  Stream<int?> get heightStream => _heightController.stream;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> play() async {
    _isPlaying = true;
    playCalls++;
  }

  @override
  Future<void> pause() async {
    _isPlaying = false;
    pauseCalls++;
  }

  @override
  Future<void> seek(Duration position) async {
    seekCalls.add(position);
    currentPosition = position;
  }

  @override
  Future<void> setRate(double rate) async {
    currentRate = rate;
    rateCalls.add(rate);
  }

  @override
  void setVolume(double volume) {
    currentVolume = volume;
    volumeCalls.add(volume);
  }

  @override
  void dispose() {
    disposed = true;
    _positionController.close();
    _durationController.close();
    _completedController.close();
    _widthController.close();
    _heightController.close();
  }

  @override
  VideoController? get controller => null;

  // --- Drive streams from tests ---

  void emitPosition(Duration d) {
    currentPosition = d;
    _positionController.add(d);
  }

  void emitDuration(Duration d) => _durationController.add(d);

  void emitCompleted() => _completedController.add(true);

  void emitDimensions(int w, int h) {
    _widthController.add(w);
    _heightController.add(h);
  }
}

/// Yield to the event loop a few times so broadcast stream events propagate
/// to all listeners before assertions.
Future<void> pumpStreams() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Timeline buildTimeline({
  required Map<PlayerRole, ({Duration startOffset, FakeSource source})> sources,
}) {
  return Timeline.forTesting([
    for (final entry in sources.entries)
      (
        role: entry.key,
        startOffset: entry.value.startOffset,
        source: entry.value.source,
      ),
  ]);
}

void main() {
  group('Timeline.computeStartOffsets', () {
    test('all null starts → all zero offsets', () {
      expect(
        Timeline.computeStartOffsets([null, null, null]),
        [Duration.zero, Duration.zero, Duration.zero],
      );
    });

    test('single source → zero offset', () {
      final t = DateTime(2026, 4, 27, 10, 0, 0);
      expect(Timeline.computeStartOffsets([t]), [Duration.zero]);
    });

    test('two sources, same start → both zero', () {
      final t = DateTime(2026, 4, 27, 10, 0, 0);
      expect(
        Timeline.computeStartOffsets([t, t]),
        [Duration.zero, Duration.zero],
      );
    });

    test('two sources, second starts later → second has positive offset', () {
      final a = DateTime(2026, 4, 27, 10, 0, 0);
      final b = DateTime(2026, 4, 27, 10, 0, 5);
      expect(
        Timeline.computeStartOffsets([a, b]),
        [Duration.zero, const Duration(seconds: 5)],
      );
    });

    test('two sources, first starts later → first has positive offset', () {
      final a = DateTime(2026, 4, 27, 10, 0, 7);
      final b = DateTime(2026, 4, 27, 10, 0, 0);
      expect(
        Timeline.computeStartOffsets([a, b]),
        [const Duration(seconds: 7), Duration.zero],
      );
    });

    test('three sources, full earliest → red and blue have positive offsets', () {
      final full = DateTime(2026, 4, 27, 10, 0, 0);
      final red = DateTime(2026, 4, 27, 10, 0, 5);
      final blue = DateTime(2026, 4, 27, 10, 0, 8);
      expect(
        Timeline.computeStartOffsets([red, blue, full]),
        [
          const Duration(seconds: 5),
          const Duration(seconds: 8),
          Duration.zero,
        ],
      );
    });

    test('null start treated as offset 0 alongside known starts', () {
      final a = DateTime(2026, 4, 27, 10, 0, 5);
      final b = DateTime(2026, 4, 27, 10, 0, 10);
      expect(
        Timeline.computeStartOffsets([null, a, b]),
        [Duration.zero, Duration.zero, const Duration(seconds: 5)],
      );
    });

    test('millisecond precision', () {
      final a = DateTime(2026, 4, 27, 10, 0, 0, 0);
      final b = DateTime(2026, 4, 27, 10, 0, 0, 250);
      expect(
        Timeline.computeStartOffsets([a, b]),
        [Duration.zero, const Duration(milliseconds: 250)],
      );
    });
  });

  group('Timeline.computeUnifiedDuration', () {
    test('empty input → zero', () {
      expect(Timeline.computeUnifiedDuration([], []), Duration.zero);
    });

    test('single source → its own duration', () {
      expect(
        Timeline.computeUnifiedDuration(
          [Duration.zero],
          [const Duration(seconds: 30)],
        ),
        const Duration(seconds: 30),
      );
    });

    test('dual: later end > earlier end (Period 3 exists)', () {
      expect(
        Timeline.computeUnifiedDuration(
          [Duration.zero, const Duration(seconds: 5)],
          [const Duration(seconds: 30), const Duration(seconds: 30)],
        ),
        const Duration(seconds: 35),
      );
    });

    test('dual: earlier end > later end (Period 3 is silent on later)', () {
      expect(
        Timeline.computeUnifiedDuration(
          [Duration.zero, const Duration(seconds: 5)],
          [const Duration(seconds: 60), const Duration(seconds: 20)],
        ),
        const Duration(seconds: 60),
      );
    });

    test('triple: full extends past both red and blue', () {
      expect(
        Timeline.computeUnifiedDuration(
          [
            const Duration(seconds: 5),
            const Duration(seconds: 8),
            Duration.zero,
          ],
          [
            const Duration(seconds: 30),
            const Duration(seconds: 30),
            const Duration(seconds: 50),
          ],
        ),
        const Duration(seconds: 50),
      );
    });

    test('triple: blue extends past red and full', () {
      expect(
        Timeline.computeUnifiedDuration(
          [
            const Duration(seconds: 5),
            const Duration(seconds: 8),
            Duration.zero,
          ],
          [
            const Duration(seconds: 30),
            const Duration(seconds: 50),
            const Duration(seconds: 30),
          ],
        ),
        const Duration(seconds: 58),
      );
    });

    test('zero durations (before media_kit reports) → spans known ones', () {
      expect(
        Timeline.computeUnifiedDuration(
          [Duration.zero, const Duration(seconds: 5)],
          [Duration.zero, Duration.zero],
        ),
        const Duration(seconds: 5),
      );
    });
  });

  group('Timeline behavior — single source', () {
    test('unifiedPosition follows the lone source', () async {
      final src = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: src),
      });

      src.emitDuration(const Duration(seconds: 30));
      src.emitPosition(const Duration(seconds: 7));
      await pumpStreams();

      expect(t.unifiedPosition, const Duration(seconds: 7));
      expect(t.unifiedDuration, const Duration(seconds: 30));

      t.dispose();
    });

    test('play/pause forward to the lone source', () async {
      final src = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: src),
      });
      src.emitDuration(const Duration(seconds: 30));

      await t.play();
      expect(src.playCalls, 1);
      expect(src.isPlaying, isTrue);

      await t.pause();
      expect(src.pauseCalls, 1);
      expect(src.isPlaying, isFalse);

      t.dispose();
    });

    test('seek clamps to source duration and sets intended position', () async {
      final src = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: src),
      });
      src.emitDuration(const Duration(seconds: 30));
      await pumpStreams();

      // Seek past end clamps to duration
      await t.seek(const Duration(seconds: 100));
      expect(t.unifiedPosition, const Duration(seconds: 30));
      expect(src.seekCalls.last, const Duration(seconds: 30));

      // Seek negative clamps to zero
      await t.seek(const Duration(seconds: -5));
      expect(t.unifiedPosition, Duration.zero);

      t.dispose();
    });
  });

  group('Timeline behavior — Period 3 handoff', () {
    test('after earlier source ends, later source drives unifiedPosition', () async {
      final earlier = FakeSource();
      final later = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: earlier),
        PlayerRole.blue: (
          startOffset: const Duration(seconds: 5),
          source: later,
        ),
      });

      // Setup: earlier is 20s long, later is 30s long. Unified end: 5 + 30 = 35s.
      earlier.emitDuration(const Duration(seconds: 20));
      later.emitDuration(const Duration(seconds: 30));
      await pumpStreams();
      expect(t.unifiedDuration, const Duration(seconds: 35));

      // Period 1: only earlier playing, unified follows earlier.
      earlier.emitPosition(const Duration(seconds: 3));
      await pumpStreams();
      expect(t.unifiedPosition, const Duration(seconds: 3));

      // Period 2: later joins. Earlier still drives clock; later fires too.
      earlier.emitPosition(const Duration(seconds: 10));
      await pumpStreams();
      expect(t.unifiedPosition, const Duration(seconds: 10));
      // later is at local 5s (matches unified 10s)
      later.emitPosition(const Duration(seconds: 5));
      await pumpStreams();
      // unified should still be 10s (or slightly forward if later's event is later)
      expect(t.unifiedPosition, const Duration(seconds: 10));

      // Earlier ends. Final position event from earlier might arrive at duration.
      earlier.emitPosition(const Duration(seconds: 20));
      await pumpStreams();
      expect(t.unifiedPosition, const Duration(seconds: 20));
      earlier.emitCompleted();
      await pumpStreams();

      // Period 3: only later emits. Should drive unified forward.
      later.emitPosition(const Duration(seconds: 18));
      await pumpStreams();
      // unified = startOffset(5) + localPos(18) = 23s
      expect(t.unifiedPosition, const Duration(seconds: 23));

      later.emitPosition(const Duration(seconds: 25));
      await pumpStreams();
      expect(t.unifiedPosition, const Duration(seconds: 30));

      t.dispose();
    });

    test('monotonic floor: handoff never regresses unified position', () async {
      final earlier = FakeSource();
      final later = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: earlier),
        PlayerRole.blue: (
          startOffset: const Duration(seconds: 5),
          source: later,
        ),
      });
      earlier.emitDuration(const Duration(seconds: 20));
      later.emitDuration(const Duration(seconds: 30));
      await pumpStreams();

      // Drive unified to 19s via earlier.
      earlier.emitPosition(const Duration(seconds: 19));
      await pumpStreams();
      expect(t.unifiedPosition, const Duration(seconds: 19));

      // Simulate: later's stale event reports localPos=13 (unified=18) AFTER
      // earlier already pushed unified to 19. The floor must reject this.
      later.emitPosition(const Duration(seconds: 13));
      await pumpStreams();
      expect(t.unifiedPosition, const Duration(seconds: 19),
          reason: 'monotonic floor must reject sub-frame backwards events');

      // A fresh forward event should advance.
      later.emitPosition(const Duration(seconds: 15));
      await pumpStreams();
      expect(t.unifiedPosition, const Duration(seconds: 20));

      t.dispose();
    });

    test('unifiedPositionStream emits during Period 3', () async {
      final earlier = FakeSource();
      final later = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: earlier),
        PlayerRole.blue: (
          startOffset: const Duration(seconds: 5),
          source: later,
        ),
      });
      earlier.emitDuration(const Duration(seconds: 20));
      later.emitDuration(const Duration(seconds: 30));

      final emissions = <Duration>[];
      final sub = t.unifiedPositionStream.listen(emissions.add);

      // Earlier ends, later takes over.
      earlier.emitPosition(const Duration(seconds: 20));
      earlier.emitCompleted();
      later.emitPosition(const Duration(seconds: 16));
      later.emitPosition(const Duration(seconds: 17));
      later.emitPosition(const Duration(seconds: 18));
      await pumpStreams();

      // Should have received emissions during Period 3.
      // The exact count can vary based on monotonic-floor decisions, but
      // we MUST see at least the late events advancing past 20s.
      final period3Emissions =
          emissions.where((d) => d > const Duration(seconds: 20)).toList();
      expect(period3Emissions, isNotEmpty,
          reason: 'unifiedPositionStream must keep emitting during Period 3');

      await sub.cancel();
      t.dispose();
    });
  });

  group('Timeline behavior — play() window-gating', () {
    test('play() only starts slots whose window contains unifiedPosition', () async {
      final earlier = FakeSource();
      final later = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: earlier),
        PlayerRole.blue: (
          startOffset: const Duration(seconds: 5),
          source: later,
        ),
      });
      earlier.emitDuration(const Duration(seconds: 20));
      later.emitDuration(const Duration(seconds: 30));
      await pumpStreams();

      // unifiedPosition is 0 — only earlier is in its window. Later is waiting.
      await t.play();
      expect(earlier.isPlaying, isTrue,
          reason: 'earlier should play (in window)');
      expect(later.isPlaying, isFalse,
          reason: 'later should NOT play yet (still waiting for offset)');

      t.dispose();
    });

    test('seek to Period 3 then play() only starts the later source', () async {
      final earlier = FakeSource();
      final later = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: earlier),
        PlayerRole.blue: (
          startOffset: const Duration(seconds: 5),
          source: later,
        ),
      });
      earlier.emitDuration(const Duration(seconds: 20));
      later.emitDuration(const Duration(seconds: 30));
      await pumpStreams();

      // Seek to unified 25s. Earlier's window is [0,20] → past end. Later's
      // is [5,35] → in window.
      await t.seek(const Duration(seconds: 25));
      await t.play();

      expect(earlier.isPlaying, isFalse,
          reason: 'earlier is past its window in Period 3');
      expect(later.isPlaying, isTrue,
          reason: 'later is in its window');

      t.dispose();
    });
  });

  group('Timeline behavior — seek() per-slot clamping', () {
    test('seek before later slot start: later pauses + resets to zero', () async {
      final earlier = FakeSource();
      final later = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: earlier),
        PlayerRole.blue: (
          startOffset: const Duration(seconds: 5),
          source: later,
        ),
      });
      earlier.emitDuration(const Duration(seconds: 20));
      later.emitDuration(const Duration(seconds: 30));
      await pumpStreams();

      await t.seek(const Duration(seconds: 2));
      // Earlier in window (local 2s); later out of window (unified before its start).
      expect(earlier.seekCalls.last, const Duration(seconds: 2));
      expect(later.seekCalls.last, Duration.zero,
          reason: 'later should be reset to zero when unified is before its window');
      expect(later.isPlaying, isFalse);

      t.dispose();
    });

    test('seek past earlier end: earlier pauses + parks at its duration', () async {
      final earlier = FakeSource();
      final later = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: earlier),
        PlayerRole.blue: (
          startOffset: const Duration(seconds: 5),
          source: later,
        ),
      });
      earlier.emitDuration(const Duration(seconds: 20));
      later.emitDuration(const Duration(seconds: 30));
      await pumpStreams();

      await t.seek(const Duration(seconds: 25));
      // Earlier out of window; later in window at local 20s.
      expect(earlier.seekCalls.last, const Duration(seconds: 20),
          reason: 'earlier should be parked at its end (its duration)');
      expect(earlier.isPlaying, isFalse);
      expect(later.seekCalls.last, const Duration(seconds: 20));

      t.dispose();
    });

    test('seek clamps to unifiedDuration', () async {
      final src = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: src),
      });
      src.emitDuration(const Duration(seconds: 30));
      await pumpStreams();

      await t.seek(const Duration(seconds: 1000));
      expect(t.unifiedPosition, const Duration(seconds: 30));

      t.dispose();
    });
  });

  group('Timeline behavior — intended position override', () {
    test('after seek, unifiedPosition reflects target until source catches up', () async {
      final src = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: src),
      });
      src.emitDuration(const Duration(seconds: 30));
      await pumpStreams();

      await t.seek(const Duration(seconds: 15));
      // Immediately after seek: unifiedPosition is the intended target.
      expect(t.unifiedPosition, const Duration(seconds: 15));

      // A stale position event from BEFORE the seek arrives. Override holds.
      src.emitPosition(const Duration(seconds: 3));
      await pumpStreams();
      expect(t.unifiedPosition, const Duration(seconds: 15),
          reason: 'intended override should suppress stale pre-seek positions');

      // The real position catches up. Override clears.
      src.emitPosition(const Duration(seconds: 15));
      await pumpStreams();
      src.emitPosition(const Duration(seconds: 16));
      await pumpStreams();
      expect(t.unifiedPosition, const Duration(seconds: 16));

      t.dispose();
    });
  });

  group('Timeline behavior — per-player accessors', () {
    test('isWaitingFor true when unified is before slot start', () async {
      final later = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.blue: (
          startOffset: const Duration(seconds: 5),
          source: later,
        ),
      });
      later.emitDuration(const Duration(seconds: 30));
      await pumpStreams();
      // unifiedPosition is 0 — later waiting until 5s
      expect(t.isWaitingFor(PlayerRole.blue), isTrue);
      expect(t.countdownFor(PlayerRole.blue), const Duration(seconds: 5));

      await t.seek(const Duration(seconds: 7));
      expect(t.isWaitingFor(PlayerRole.blue), isFalse);
      expect(t.countdownFor(PlayerRole.blue), Duration.zero);

      t.dispose();
    });

    test('hasEnded + endedAgoFor true when unified is past slot end', () async {
      final earlier = FakeSource();
      final later = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: earlier),
        PlayerRole.blue: (
          startOffset: const Duration(seconds: 5),
          source: later,
        ),
      });
      earlier.emitDuration(const Duration(seconds: 20));
      later.emitDuration(const Duration(seconds: 30));
      await pumpStreams();

      // Seek to unified 25s. Earlier ends at 20 → ended 5s ago.
      await t.seek(const Duration(seconds: 25));
      expect(t.hasEnded(PlayerRole.red), isTrue);
      expect(t.endedAgoFor(PlayerRole.red), const Duration(seconds: 5));
      // Later not ended yet
      expect(t.hasEnded(PlayerRole.blue), isFalse);
      expect(t.endedAgoFor(PlayerRole.blue), Duration.zero);

      t.dispose();
    });

    test('hasEnded false when slot duration unknown (== zero)', () async {
      final src = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: src),
      });
      // Don't emit duration. seek shouldn't claim hasEnded since duration unknown.
      await t.seek(const Duration(seconds: 100));
      // Position clamps to unifiedDuration which is 0 → unifiedPosition stays 0.
      expect(t.hasEnded(PlayerRole.red), isFalse);
      t.dispose();
    });

    test('setVolumeFor routes to the right source only', () async {
      final red = FakeSource();
      final blue = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: red),
        PlayerRole.blue: (
          startOffset: const Duration(seconds: 5),
          source: blue,
        ),
      });

      await t.setVolumeFor(PlayerRole.red, 100);
      expect(red.currentVolume, 100);
      expect(blue.currentVolume, 0);

      await t.setVolumeFor(PlayerRole.blue, 75);
      expect(red.currentVolume, 100);
      expect(blue.currentVolume, 75);

      // Volume for absent role is a no-op (no exception)
      await t.setVolumeFor(PlayerRole.full, 50);

      t.dispose();
    });

    test('widthFor/heightFor expose source dimensions', () async {
      final src = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: src),
      });
      expect(t.widthFor(PlayerRole.red), isNull);
      expect(t.heightFor(PlayerRole.red), isNull);

      src.emitDimensions(1920, 1080);
      await pumpStreams();

      expect(t.widthFor(PlayerRole.red), 1920);
      expect(t.heightFor(PlayerRole.red), 1080);

      t.dispose();
    });

    test('dimensionsStream fires the role when both w and h known', () async {
      final src = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: src),
      });
      final emissions = <PlayerRole>[];
      final sub = t.dimensionsStream.listen(emissions.add);

      src.emitDimensions(1920, 1080);
      await pumpStreams();

      expect(emissions, contains(PlayerRole.red));
      await sub.cancel();
      t.dispose();
    });
  });

  group('Timeline behavior — disposal', () {
    test('dispose closes streams and disposes sources', () async {
      final src = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: src),
      });
      t.dispose();

      expect(src.disposed, isTrue);
    });
  });

  group('Timeline behavior — triple source unified duration', () {
    test('full extends past red and blue', () async {
      final red = FakeSource();
      final blue = FakeSource();
      final full = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (
          startOffset: const Duration(seconds: 5),
          source: red,
        ),
        PlayerRole.blue: (
          startOffset: const Duration(seconds: 8),
          source: blue,
        ),
        PlayerRole.full: (startOffset: Duration.zero, source: full),
      });

      red.emitDuration(const Duration(seconds: 30)); // ends at 35
      blue.emitDuration(const Duration(seconds: 30)); // ends at 38
      full.emitDuration(const Duration(seconds: 50)); // ends at 50
      await pumpStreams();

      expect(t.unifiedDuration, const Duration(seconds: 50));
      t.dispose();
    });

    test('red ends first, blue second, full third — unified honors all', () async {
      final red = FakeSource();
      final blue = FakeSource();
      final full = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: red),
        PlayerRole.blue: (
          startOffset: const Duration(seconds: 2),
          source: blue,
        ),
        PlayerRole.full: (
          startOffset: const Duration(seconds: 4),
          source: full,
        ),
      });
      red.emitDuration(const Duration(seconds: 10)); // ends at 10
      blue.emitDuration(const Duration(seconds: 12)); // ends at 14
      full.emitDuration(const Duration(seconds: 18)); // ends at 22
      await pumpStreams();
      expect(t.unifiedDuration, const Duration(seconds: 22));
      t.dispose();
    });
  });

  group('Timeline behavior — playback rate', () {
    test('default rate is 1.0', () {
      final src = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: src),
      });
      expect(t.rate, 1.0);
      t.dispose();
    });

    test('setRate forwards to every slot', () async {
      final red = FakeSource();
      final blue = FakeSource();
      final full = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: red),
        PlayerRole.blue: (
          startOffset: const Duration(seconds: 5),
          source: blue,
        ),
        PlayerRole.full: (startOffset: Duration.zero, source: full),
      });

      await t.setRate(1.5);

      expect(red.currentRate, 1.5);
      expect(blue.currentRate, 1.5);
      expect(full.currentRate, 1.5);
      expect(t.rate, 1.5);

      t.dispose();
    });

    test('setRate clamps to [0.25, 3.0]', () async {
      final src = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: src),
      });

      await t.setRate(0.1);
      expect(t.rate, 0.25);
      expect(src.currentRate, 0.25);

      await t.setRate(10.0);
      expect(t.rate, 3.0);
      expect(src.currentRate, 3.0);

      await t.setRate(-1.0);
      expect(t.rate, 0.25);

      t.dispose();
    });

    test('newly-woken slot inherits current rate (Period 1 -> 2)', () async {
      // Earlier starts at 0; later at 5s offset. Set rate to 0.5 before
      // later wakes. When unified time crosses 5s and later wakes via
      // _maybeWakeOrPark, it should be told setRate(0.5).
      final earlier = FakeSource();
      final later = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: earlier),
        PlayerRole.blue: (
          startOffset: const Duration(seconds: 5),
          source: later,
        ),
      });
      earlier.emitDuration(const Duration(seconds: 30));
      later.emitDuration(const Duration(seconds: 30));
      await pumpStreams();

      // Set rate while later is still waiting
      await t.setRate(0.5);
      expect(later.currentRate, 0.5,
          reason: 'setRate should propagate to all slots immediately');

      // Start playback. Earlier in window -> plays. Later out of window -> stays paused.
      await t.play();
      // Reset call log AFTER play() so we can check the wake-up specifically
      // (play() also re-applies rate to in-window slots).
      later.rateCalls.clear();
      expect(earlier.isPlaying, isTrue);
      expect(later.isPlaying, isFalse);

      // Drive earlier forward; eventually unified crosses 5s and later wakes.
      earlier.emitPosition(const Duration(seconds: 6));
      await pumpStreams();

      expect(later.isPlaying, isTrue, reason: 'later should wake at offset');
      expect(later.rateCalls, contains(0.5),
          reason: 'wake-up must apply current rate, not default 1.0x');

      t.dispose();
    });

    test('play() re-applies current rate to slots in window', () async {
      final src = FakeSource();
      final t = buildTimeline(sources: {
        PlayerRole.red: (startOffset: Duration.zero, source: src),
      });
      src.emitDuration(const Duration(seconds: 30));
      await pumpStreams();

      await t.setRate(2.0);
      src.rateCalls.clear();

      await t.play();
      expect(src.rateCalls, contains(2.0),
          reason: 'play() must re-apply current rate');

      t.dispose();
    });
  });
}
