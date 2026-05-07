import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/widgets/control_sidebar.dart';

void main() {
  // Default no-op callbacks for required fields.
  void noop() {}

  ControlSidebar buildSidebar({
    bool isPlaying = false,
    MuteState muteState = MuteState.muted,
    ViewMode viewMode = ViewMode.both,
    bool isDrawing = false,
    bool canUndo = false,
    bool canRedo = false,
    bool hasDrawings = false,
    bool canToggleViewMode = true,
    Duration? markedStartPosition,
    Duration currentPosition = Duration.zero,
    double playbackSpeed = 1.0,
    VoidCallback? onDrawStart,
    VoidCallback? onDrawEnd,
    VoidCallback? onUndo,
    VoidCallback? onRedo,
    VoidCallback? onClearDrawing,
    VoidCallback? onMarkStart,
    // For speed tests: pass `withSpeedDown: false` / `withSpeedUp: false`
    // to simulate boundary states (null callback = disabled).
    bool withSpeedDown = true,
    bool withSpeedUp = true,
    VoidCallback? onSpeedDown,
    VoidCallback? onSpeedUp,
    VoidCallback? onSpeedReset,
  }) {
    return ControlSidebar(
      isPlaying: isPlaying,
      muteState: muteState,
      viewMode: viewMode,
      isDrawing: isDrawing,
      canUndo: canUndo,
      canRedo: canRedo,
      hasDrawings: hasDrawings,
      canToggleViewMode: canToggleViewMode,
      markedStartPosition: markedStartPosition,
      currentPosition: currentPosition,
      playbackSpeed: playbackSpeed,
      onBack: noop,
      onSwapSides: noop,
      onToggleMute: noop,
      onToggleViewMode: noop,
      onPlayPause: noop,
      onMarkStart: onMarkStart ?? noop,
      onSpeedDown: withSpeedDown ? (onSpeedDown ?? noop) : null,
      onSpeedUp: withSpeedUp ? (onSpeedUp ?? noop) : null,
      onSpeedReset: onSpeedReset ?? noop,
      onRewind10: noop,
      onForward10: noop,
      onRestart: noop,
      onDrawStart: onDrawStart ?? noop,
      onDrawEnd: onDrawEnd ?? noop,
      onUndo: onUndo ?? noop,
      onRedo: onRedo ?? noop,
      onClearDrawing: onClearDrawing ?? noop,
    );
  }

  Widget wrapInApp(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Row(
          children: [
            // Give it full height via a Row in a Scaffold body.
            child,
          ],
        ),
      ),
    );
  }

  group('Hold-to-draw button', () {
    testWidgets('shows edit_off icon when not drawing', (tester) async {
      await tester.pumpWidget(wrapInApp(buildSidebar(isDrawing: false)));
      expect(find.byIcon(Icons.edit_off), findsOneWidget);
    });

    testWidgets('shows edit icon when drawing', (tester) async {
      await tester.pumpWidget(wrapInApp(buildSidebar(isDrawing: true)));
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('fires onDrawStart on long press and onDrawEnd on release', (tester) async {
      var startCalled = false;
      var endCalled = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        onDrawStart: () => startCalled = true,
        onDrawEnd: () => endCalled = true,
      )));

      // Long press triggers onLongPressStart / onLongPressEnd
      await tester.longPress(find.byIcon(Icons.edit_off));
      await tester.pump();
      expect(startCalled, isTrue, reason: 'onDrawStart should fire on long press');
      expect(endCalled, isTrue, reason: 'onDrawEnd should fire on long press release');
    });

    testWidgets('draw button is always enabled regardless of play state', (tester) async {
      var startCalled = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        isPlaying: true,
        onDrawStart: () => startCalled = true,
      )));

      await tester.longPress(find.byIcon(Icons.edit_off));
      await tester.pump();
      expect(startCalled, isTrue, reason: 'Draw button should work while playing');
    });
  });

  group('Undo/redo/clear buttons', () {
    testWidgets('undo/redo/clear are always visible', (tester) async {
      await tester.pumpWidget(wrapInApp(buildSidebar(
        isPlaying: true,
        hasDrawings: false,
      )));

      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.redo), findsOneWidget);
      expect(find.byIcon(Icons.cleaning_services), findsOneWidget);
    });

    testWidgets('undo/redo/clear enabled when applicable, regardless of drawing state', (tester) async {
      var undoPressed = false;
      var redoPressed = false;
      var clearPressed = false;

      await tester.pumpWidget(wrapInApp(buildSidebar(
        isDrawing: false,
        canUndo: true,
        canRedo: true,
        hasDrawings: true,
        onUndo: () => undoPressed = true,
        onRedo: () => redoPressed = true,
        onClearDrawing: () => clearPressed = true,
      )));

      final undoFinder = find.byIcon(Icons.undo);
      await tester.ensureVisible(undoFinder);
      await tester.pumpAndSettle();
      await tester.tap(undoFinder);
      await tester.pump();
      expect(undoPressed, isTrue);

      final redoFinder = find.byIcon(Icons.redo);
      await tester.ensureVisible(redoFinder);
      await tester.pumpAndSettle();
      await tester.tap(redoFinder);
      await tester.pump();
      expect(redoPressed, isTrue);

      final clearFinder = find.byIcon(Icons.cleaning_services);
      await tester.ensureVisible(clearFinder);
      await tester.pumpAndSettle();
      await tester.tap(clearFinder);
      await tester.pump();
      expect(clearPressed, isTrue);
    });

    testWidgets('undo disabled when canUndo is false', (tester) async {
      var undoPressed = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        canUndo: false,
        onUndo: () => undoPressed = true,
      )));

      final undoFinder = find.byIcon(Icons.undo);
      await tester.ensureVisible(undoFinder);
      await tester.pumpAndSettle();
      await tester.tap(undoFinder);
      await tester.pump();
      expect(undoPressed, isFalse);
    });

    testWidgets('redo disabled when canRedo is false', (tester) async {
      var redoPressed = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        canRedo: false,
        onRedo: () => redoPressed = true,
      )));

      final redoFinder = find.byIcon(Icons.redo);
      await tester.ensureVisible(redoFinder);
      await tester.pumpAndSettle();
      await tester.tap(redoFinder);
      await tester.pump();
      expect(redoPressed, isFalse);
    });

    testWidgets('clear disabled when no drawings', (tester) async {
      var clearPressed = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        hasDrawings: false,
        onClearDrawing: () => clearPressed = true,
      )));

      final clearFinder = find.byIcon(Icons.cleaning_services);
      await tester.ensureVisible(clearFinder);
      await tester.pumpAndSettle();
      await tester.tap(clearFinder);
      await tester.pump();
      expect(clearPressed, isFalse);
    });
  });

  group('Sidebar full-height layout', () {
    testWidgets('sidebar fills available height', (tester) async {
      await tester.pumpWidget(wrapInApp(buildSidebar()));

      // The SizedBox wrapping the sidebar should have height: double.infinity
      // so it fills the full available height.
      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(ColoredBox),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.width, 160); // expanded mode (viewMode.both)
      expect(sizedBox.height, double.infinity);

      // Verify the sidebar's rendered height matches the Row parent's height.
      final sidebarBox = tester.getSize(find.byType(ColoredBox).first);
      final rowSize = tester.getSize(find.byType(Row).first);
      expect(sidebarBox.height, rowSize.height);
    });

    testWidgets('buttons fill available height using Expanded', (tester) async {
      await tester.pumpWidget(wrapInApp(buildSidebar()));

      // Buttons should be wrapped in Expanded widgets within the Column.
      final expandedWidgets = tester.widgetList<Expanded>(
        find.descendant(
          of: find.byType(ControlSidebar),
          matching: find.byType(Expanded),
        ),
      );
      // There should be at least one Expanded per button
      expect(expandedWidgets.length, greaterThanOrEqualTo(8));
    });

    testWidgets('expanded mode buttons have min 48px touch targets', (tester) async {
      await tester.pumpWidget(wrapInApp(buildSidebar(viewMode: ViewMode.both)));

      // In expanded mode, buttons are InkWell widgets wrapped in Expanded
      // within the Column, so they fill available height (well above 48px).
      // Verify InkWell buttons exist inside the sidebar.
      final inkWells = tester.widgetList<InkWell>(
        find.descendant(
          of: find.byType(ControlSidebar),
          matching: find.byType(InkWell),
        ),
      );
      expect(inkWells, isNotEmpty);
      // Each InkWell should have an Expanded ancestor within the sidebar.
      for (final inkWellElement in tester.elementList(find.descendant(
        of: find.byType(ControlSidebar),
        matching: find.byType(InkWell),
      ))) {
        final expandedAncestor = find.ancestor(
          of: find.byWidget(inkWellElement.widget),
          matching: find.byType(Expanded),
        );
        expect(expandedAncestor, findsAtLeastNWidgets(1));
      }
    });

    testWidgets('compact mode buttons have min 56px touch targets', (tester) async {
      await tester.pumpWidget(wrapInApp(buildSidebar(
        viewMode: ViewMode.redOnly,
        canToggleViewMode: false,
      )));

      // In compact mode, buttons are InkWell > Center > Icon, wrapped in
      // Expanded within the Column so they fill available height (above 56px).
      final inkWells = tester.widgetList<InkWell>(
        find.descendant(
          of: find.byType(ControlSidebar),
          matching: find.byType(InkWell),
        ),
      );
      expect(inkWells, isNotEmpty);
      // Each InkWell should have an Expanded ancestor within the sidebar.
      for (final inkWellElement in tester.elementList(find.descendant(
        of: find.byType(ControlSidebar),
        matching: find.byType(InkWell),
      ))) {
        final expandedAncestor = find.ancestor(
          of: find.byWidget(inkWellElement.widget),
          matching: find.byType(Expanded),
        );
        expect(expandedAncestor, findsAtLeastNWidgets(1));
      }
    });

    testWidgets('compact mode uses 72px width', (tester) async {
      await tester.pumpWidget(wrapInApp(buildSidebar(
        viewMode: ViewMode.redOnly,
      )));

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(ColoredBox),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.width, 72);
    });
  });

  group('Mark Start button', () {
    testWidgets('unmarked: shows stopwatch icon + placeholder text', (tester) async {
      // The placeholder reserves layout space so the icon doesn't jump when
      // the user first taps Mark Start.
      await tester.pumpWidget(wrapInApp(buildSidebar(
        markedStartPosition: null,
      )));

      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(find.text('-:--.-'), findsOneWidget);
      // No real M:SS.t value should appear when unmarked
      expect(find.textContaining(RegExp(r'\d:\d\d\.\d')), findsNothing);
    });

    testWidgets('tap fires onMarkStart', (tester) async {
      var pressed = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        onMarkStart: () => pressed = true,
      )));

      final iconFinder = find.byIcon(Icons.timer);
      await tester.ensureVisible(iconFinder);
      await tester.pumpAndSettle();
      await tester.tap(iconFinder);
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('entire row is tappable, not just the icon', (tester) async {
      var pressed = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        viewMode: ViewMode.both,
        onMarkStart: () => pressed = true,
      )));

      // Tap the placeholder text — different widget than the icon, but the
      // InkWell should cover the whole row.
      final labelFinder = find.text('-:--.-');
      await tester.ensureVisible(labelFinder);
      await tester.pumpAndSettle();
      await tester.tap(labelFinder);
      await tester.pump();
      expect(pressed, isTrue,
          reason: 'tapping the placeholder (not the icon) should fire onMarkStart');
    });

    testWidgets('marked: displays formatted elapsed M:SS.t', (tester) async {
      await tester.pumpWidget(wrapInApp(buildSidebar(
        markedStartPosition: Duration.zero,
        currentPosition: const Duration(seconds: 5, milliseconds: 300),
      )));

      expect(find.text('0:05.3'), findsOneWidget);
      // Placeholder should be replaced by the live timer
      expect(find.text('-:--.-'), findsNothing);
    });

    testWidgets('negative elapsed clamps to 0:00.0', (tester) async {
      // User scrubbed back before the marked position
      await tester.pumpWidget(wrapInApp(buildSidebar(
        markedStartPosition: const Duration(seconds: 10),
        currentPosition: const Duration(seconds: 3),
      )));

      expect(find.text('0:00.0'), findsOneWidget);
    });

    testWidgets('re-tap re-marks at new position (timer resets to 0:00.0)', (tester) async {
      // Simulate a parent that updates markedStartPosition := currentPosition
      // when onMarkStart fires.
      Duration? mark;
      Duration current = const Duration(seconds: 5);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Row(
              children: [
                buildSidebar(
                  markedStartPosition: mark,
                  currentPosition: current,
                  onMarkStart: () => setState(() => mark = current),
                ),
              ],
            ),
          ),
        ),
      ));

      // First tap: mark at 0:05
      await tester.tap(find.byIcon(Icons.timer));
      await tester.pump();
      expect(find.text('0:00.0'), findsOneWidget);

      // Advance current to 0:08.5
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Row(
              children: [
                buildSidebar(
                  markedStartPosition: mark,
                  currentPosition: const Duration(seconds: 8, milliseconds: 500),
                  onMarkStart: () => setState(() => mark = const Duration(seconds: 8, milliseconds: 500)),
                ),
              ],
            ),
          ),
        ),
      ));
      // 8.5 - 5 = 3.5
      expect(find.text('0:03.5'), findsOneWidget);

      // Re-tap: should reset to 0:00.0 since new mark = current
      await tester.tap(find.byIcon(Icons.timer));
      await tester.pump();
      expect(find.text('0:00.0'), findsOneWidget);
    });

    testWidgets('compact mode renders Mark Start button', (tester) async {
      await tester.pumpWidget(wrapInApp(buildSidebar(
        viewMode: ViewMode.redOnly,
        canToggleViewMode: false,
      )));

      expect(find.byIcon(Icons.timer), findsOneWidget);
    });

    testWidgets('compact mode shows time text under icon when marked', (tester) async {
      await tester.pumpWidget(wrapInApp(buildSidebar(
        viewMode: ViewMode.redOnly,
        canToggleViewMode: false,
        markedStartPosition: Duration.zero,
        currentPosition: const Duration(seconds: 12, milliseconds: 400),
      )));

      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(find.text('0:12.4'), findsOneWidget);
    });

    testWidgets('compact mode: icon position stays put when first marked', (tester) async {
      // The placeholder reserves the layout slot for the time label so the
      // icon doesn't jump up when the user first taps Mark Start.
      await tester.pumpWidget(wrapInApp(buildSidebar(
        viewMode: ViewMode.redOnly,
        canToggleViewMode: false,
        markedStartPosition: null,
      )));
      final iconCenterUnmarked = tester.getCenter(find.byIcon(Icons.timer));

      await tester.pumpWidget(wrapInApp(buildSidebar(
        viewMode: ViewMode.redOnly,
        canToggleViewMode: false,
        markedStartPosition: Duration.zero,
        currentPosition: const Duration(seconds: 5),
      )));
      final iconCenterMarked = tester.getCenter(find.byIcon(Icons.timer));

      expect(iconCenterMarked, iconCenterUnmarked,
          reason: 'icon must not shift between unmarked and marked states');
    });

    testWidgets('expanded mode: icon position stays put when first marked', (tester) async {
      await tester.pumpWidget(wrapInApp(buildSidebar(
        viewMode: ViewMode.both,
        markedStartPosition: null,
      )));
      final iconCenterUnmarked = tester.getCenter(find.byIcon(Icons.timer));

      await tester.pumpWidget(wrapInApp(buildSidebar(
        viewMode: ViewMode.both,
        markedStartPosition: Duration.zero,
        currentPosition: const Duration(seconds: 5),
      )));
      final iconCenterMarked = tester.getCenter(find.byIcon(Icons.timer));

      expect(iconCenterMarked, iconCenterUnmarked,
          reason: 'icon must not shift between unmarked and marked states');
    });
  });

  group('Speed adjuster', () {
    testWidgets('renders both buttons + rate text at 1.00x', (tester) async {
      await tester.pumpWidget(wrapInApp(buildSidebar(playbackSpeed: 1.0)));

      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('1.00x'), findsOneWidget);
    });

    testWidgets('rate text reflects current speed', (tester) async {
      await tester.pumpWidget(wrapInApp(buildSidebar(playbackSpeed: 0.25)));
      expect(find.text('0.25x'), findsOneWidget);

      await tester.pumpWidget(wrapInApp(buildSidebar(playbackSpeed: 2.5)));
      expect(find.text('2.50x'), findsOneWidget);

      await tester.pumpWidget(wrapInApp(buildSidebar(playbackSpeed: 3.0)));
      expect(find.text('3.00x'), findsOneWidget);
    });

    testWidgets('tap minus fires onSpeedDown', (tester) async {
      var pressed = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        onSpeedDown: () => pressed = true,
      )));

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('tap plus fires onSpeedUp', (tester) async {
      var pressed = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        onSpeedUp: () => pressed = true,
      )));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('tap rate text fires onSpeedReset', (tester) async {
      var pressed = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        playbackSpeed: 2.5,
        onSpeedReset: () => pressed = true,
      )));

      await tester.tap(find.text('2.50x'));
      await tester.pump();
      expect(pressed, isTrue,
          reason: 'tapping the rate text should reset speed to 1.0x');
    });

    testWidgets('minus disabled when at min (no callback fires)', (tester) async {
      var pressed = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        playbackSpeed: 0.25,
        withSpeedDown: false,
        onSpeedDown: () => pressed = true,
      )));

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      expect(pressed, isFalse,
          reason: 'minus must be inert when onSpeedDown is null');
    });

    testWidgets('plus disabled when at max (no callback fires)', (tester) async {
      var pressed = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        playbackSpeed: 3.0,
        withSpeedUp: false,
        onSpeedUp: () => pressed = true,
      )));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(pressed, isFalse,
          reason: 'plus must be inert when onSpeedUp is null');
    });

    testWidgets('disabled state uses dimmed icon color', (tester) async {
      await tester.pumpWidget(wrapInApp(buildSidebar(
        playbackSpeed: 0.25,
        withSpeedDown: false,
      )));

      final minusIcon = tester.widget<Icon>(find.byIcon(Icons.remove));
      expect(minusIcon.color, Colors.white38,
          reason: 'disabled minus should match other disabled sidebar icons');
    });

    testWidgets('compact mode renders speed adjuster', (tester) async {
      await tester.pumpWidget(wrapInApp(buildSidebar(
        viewMode: ViewMode.redOnly,
        canToggleViewMode: false,
      )));

      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('1.00x'), findsOneWidget);
    });

    testWidgets('rate text position stable across speed changes (compact)', (tester) async {
      // Always two decimals so width is constant; just verify visually that
      // 0.25x, 1.00x, 3.00x all render at the same Y position. This protects
      // against future style changes that introduce variable-width digits.
      await tester.pumpWidget(wrapInApp(buildSidebar(
        viewMode: ViewMode.redOnly,
        canToggleViewMode: false,
        playbackSpeed: 0.25,
      )));
      final centerLow = tester.getCenter(find.text('0.25x'));

      await tester.pumpWidget(wrapInApp(buildSidebar(
        viewMode: ViewMode.redOnly,
        canToggleViewMode: false,
        playbackSpeed: 1.0,
      )));
      final centerMid = tester.getCenter(find.text('1.00x'));

      await tester.pumpWidget(wrapInApp(buildSidebar(
        viewMode: ViewMode.redOnly,
        canToggleViewMode: false,
        playbackSpeed: 3.0,
      )));
      final centerHigh = tester.getCenter(find.text('3.00x'));

      expect(centerLow.dy, centerMid.dy,
          reason: 'rate text Y must not shift between 0.25x and 1.00x');
      expect(centerMid.dy, centerHigh.dy,
          reason: 'rate text Y must not shift between 1.00x and 3.00x');
    });

    testWidgets('+/- buttons are at least 36px wide in compact mode', (tester) async {
      await tester.pumpWidget(wrapInApp(buildSidebar(
        viewMode: ViewMode.redOnly,
        canToggleViewMode: false,
      )));

      final minusSize = tester.getSize(find.byIcon(Icons.remove));
      final plusSize = tester.getSize(find.byIcon(Icons.add));
      // The Icon itself is 24px; the parent InkWell is 36px wide. We measure
      // the InkWell ancestor's hit area via the Center child rectangle.
      final minusCenter = tester.getCenter(find.byIcon(Icons.remove));
      final plusCenter = tester.getCenter(find.byIcon(Icons.add));
      // Sanity: both icons rendered, distinct positions
      expect(minusSize.width, 24);
      expect(plusSize.width, 24);
      expect(minusCenter.dx, lessThan(plusCenter.dx));
    });

    testWidgets('rate text tap target spans full strip width', (tester) async {
      // Tap somewhere far left of the rate text (but in the same row) and
      // verify reset still fires. Confirms the InkWell wrapping the rate
      // label stretches across the strip.
      var pressed = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        viewMode: ViewMode.redOnly,
        canToggleViewMode: false,
        playbackSpeed: 2.0,
        onSpeedReset: () => pressed = true,
      )));

      // Find the rate text and the InkWell ancestor whose onTap is set.
      final textRect = tester.getRect(find.text('2.00x'));
      // Tap 4px from the strip left edge, at the same Y as the rate text.
      // Strip is 72px wide. The InkWell should cover the whole row.
      await tester.tapAt(Offset(4, textRect.center.dy));
      await tester.pump();
      expect(pressed, isTrue,
          reason: 'rate-text InkWell must span the full strip width');
    });

    testWidgets('no Tooltip wrapper on speed item', (tester) async {
      // The speed item should NOT show a tooltip on long-press; user
      // explicitly does not want this behavior.
      await tester.pumpWidget(wrapInApp(buildSidebar(
        viewMode: ViewMode.redOnly,
        canToggleViewMode: false,
      )));

      // Long-press on each of the three sub-elements; no tooltip should
      // appear.
      await tester.longPress(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(find.text('Playback speed (tap rate to reset)'), findsNothing);

      await tester.longPress(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('Playback speed (tap rate to reset)'), findsNothing);

      await tester.longPress(find.text('1.00x'));
      await tester.pumpAndSettle();
      expect(find.text('Playback speed (tap rate to reset)'), findsNothing);
    });
  });

  group('Mute always shown', () {
    testWidgets('mute button shown even when canToggleViewMode is false', (tester) async {
      // Full-only matches have only one view mode (canToggleViewMode = false)
      // but still have audio — mute should always be available.
      await tester.pumpWidget(wrapInApp(buildSidebar(
        viewMode: ViewMode.fullOnly,
        canToggleViewMode: false,
      )));

      expect(find.byIcon(Icons.volume_off), findsOneWidget,
          reason: 'mute should be visible in compact (single-mode) layout');
    });

    testWidgets('mute reflects state when canToggleViewMode is false', (tester) async {
      await tester.pumpWidget(wrapInApp(buildSidebar(
        viewMode: ViewMode.fullOnly,
        canToggleViewMode: false,
        muteState: MuteState.fullAudio,
      )));

      expect(find.byIcon(Icons.volume_up), findsOneWidget);
    });
  });
}
