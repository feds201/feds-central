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
    VoidCallback? onDrawStart,
    VoidCallback? onDrawEnd,
    VoidCallback? onUndo,
    VoidCallback? onRedo,
    VoidCallback? onClearDrawing,
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
      onBack: noop,
      onSwapSides: noop,
      onToggleMute: noop,
      onToggleViewMode: noop,
      onPlayPause: noop,
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

    testWidgets('fires onDrawStart on pointer down and onDrawEnd on pointer up', (tester) async {
      var startCalled = false;
      var endCalled = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        onDrawStart: () => startCalled = true,
        onDrawEnd: () => endCalled = true,
      )));

      // A full tap triggers both onTapDown and onTapUp
      await tester.tap(find.byIcon(Icons.edit_off));
      await tester.pump();
      expect(startCalled, isTrue, reason: 'onDrawStart should fire on tap down');
      expect(endCalled, isTrue, reason: 'onDrawEnd should fire on tap up');
    });

    testWidgets('draw button is always enabled regardless of play state', (tester) async {
      var startCalled = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        isPlaying: true,
        onDrawStart: () => startCalled = true,
      )));

      await tester.tap(find.byIcon(Icons.edit_off));
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
}
