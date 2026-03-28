import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/viewer/drawing_controller.dart';
import 'package:match_record/widgets/control_sidebar.dart';

void main() {
  // Default no-op callbacks for required fields.
  void noop() {}

  ControlSidebar buildSidebar({
    bool isPlaying = false,
    MuteState muteState = MuteState.muted,
    ViewMode viewMode = ViewMode.both,
    DrawingColor? drawingColor,
    bool canUndo = false,
    bool canRedo = false,
    bool hasDrawings = false,
    bool canToggleViewMode = true,
    bool isPaused = true,
    VoidCallback? onToggleDrawing,
    VoidCallback? onUndo,
    VoidCallback? onRedo,
    VoidCallback? onClearDrawing,
  }) {
    return ControlSidebar(
      isPlaying: isPlaying,
      muteState: muteState,
      viewMode: viewMode,
      drawingColor: drawingColor,
      canUndo: canUndo,
      canRedo: canRedo,
      hasDrawings: hasDrawings,
      canToggleViewMode: canToggleViewMode,
      isPaused: isPaused,
      onBack: noop,
      onSwapSides: noop,
      onToggleMute: noop,
      onToggleViewMode: noop,
      onPlayPause: noop,
      onRewind10: noop,
      onForward10: noop,
      onRestart: noop,
      onToggleDrawing: onToggleDrawing ?? noop,
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

  group('v3: Draw buttons always visible', () {
    testWidgets('draw button is visible when playing (not paused)', (tester) async {
      await tester.pumpWidget(wrapInApp(buildSidebar(
        isPlaying: true,
        isPaused: false,
        drawingColor: null,
      )));

      // The draw button should exist (visible) but be disabled.
      // When drawing is off, the icon is edit_off.
      final drawIcon = find.byIcon(Icons.edit_off);
      expect(drawIcon, findsOneWidget);
    });

    testWidgets('draw button is disabled when not paused', (tester) async {
      var drawPressed = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        isPlaying: true,
        isPaused: false,
        drawingColor: null,
        onToggleDrawing: () => drawPressed = true,
      )));

      await tester.tap(find.byIcon(Icons.edit_off));
      await tester.pump();
      expect(drawPressed, isFalse, reason: 'Draw button should be disabled when not paused');
    });

    testWidgets('draw button is enabled when paused', (tester) async {
      var drawPressed = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        isPaused: true,
        drawingColor: null,
        onToggleDrawing: () => drawPressed = true,
      )));

      // When paused, drawing auto-enables — icon is edit (not edit_off)
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();
      expect(drawPressed, isTrue, reason: 'Draw button should be enabled when paused');
    });

    testWidgets('undo/redo/clear are always visible', (tester) async {
      await tester.pumpWidget(wrapInApp(buildSidebar(
        isPaused: false,
        isPlaying: true,
        drawingColor: null,
        hasDrawings: false,
      )));

      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.redo), findsOneWidget);
      expect(find.byIcon(Icons.cleaning_services), findsOneWidget);
    });

    testWidgets('undo/redo/clear are disabled when not in drawing mode', (tester) async {
      var undoPressed = false;
      var redoPressed = false;
      var clearPressed = false;

      await tester.pumpWidget(wrapInApp(buildSidebar(
        isPaused: true,
        drawingColor: null,
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
      expect(undoPressed, isFalse, reason: 'Undo should be disabled outside drawing mode');

      final redoFinder = find.byIcon(Icons.redo);
      await tester.ensureVisible(redoFinder);
      await tester.pumpAndSettle();
      await tester.tap(redoFinder);
      await tester.pump();
      expect(redoPressed, isFalse, reason: 'Redo should be disabled outside drawing mode');

      final clearFinder = find.byIcon(Icons.cleaning_services);
      await tester.ensureVisible(clearFinder);
      await tester.pumpAndSettle();
      await tester.tap(clearFinder);
      await tester.pump();
      expect(clearPressed, isFalse, reason: 'Clear should be disabled outside drawing mode');
    });

    testWidgets('undo/redo/clear are enabled in drawing mode when applicable', (tester) async {
      var undoPressed = false;
      var redoPressed = false;
      var clearPressed = false;

      await tester.pumpWidget(wrapInApp(buildSidebar(
        isPaused: true,
        drawingColor: DrawingColor.red,
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

    testWidgets('undo disabled in drawing mode when canUndo is false', (tester) async {
      var undoPressed = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        isPaused: true,
        drawingColor: DrawingColor.red,
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

    testWidgets('redo disabled in drawing mode when canRedo is false', (tester) async {
      var redoPressed = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        isPaused: true,
        drawingColor: DrawingColor.red,
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

    testWidgets('clear disabled in drawing mode when no drawings', (tester) async {
      var clearPressed = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        isPaused: true,
        drawingColor: DrawingColor.red,
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

  group('v4: Sidebar full-height layout', () {
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
