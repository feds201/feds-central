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
    bool isDrawingMode = false,
    bool canUndo = false,
    bool canRedo = false,
    bool hasDrawings = false,
    bool hasDualVideo = true,
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
      isDrawingMode: isDrawingMode,
      canUndo: canUndo,
      canRedo: canRedo,
      hasDrawings: hasDrawings,
      hasDualVideo: hasDualVideo,
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
        isDrawingMode: false,
      )));

      // The draw button should exist (visible) but be disabled.
      final drawIcon = find.byIcon(Icons.edit);
      expect(drawIcon, findsOneWidget);
    });

    testWidgets('draw button is disabled when not paused', (tester) async {
      var drawPressed = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        isPlaying: true,
        isPaused: false,
        isDrawingMode: false,
        onToggleDrawing: () => drawPressed = true,
      )));

      // In compact mode (viewMode != both would be compact, but both = expanded).
      // The draw button uses InkWell in expanded mode — find it by tooltip or icon.
      // Try tapping the draw area — it should not fire the callback.
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();
      expect(drawPressed, isFalse, reason: 'Draw button should be disabled when not paused');
    });

    testWidgets('draw button is enabled when paused', (tester) async {
      var drawPressed = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        isPaused: true,
        isDrawingMode: false,
        onToggleDrawing: () => drawPressed = true,
      )));

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();
      expect(drawPressed, isTrue, reason: 'Draw button should be enabled when paused');
    });

    testWidgets('undo/redo/clear are always visible', (tester) async {
      await tester.pumpWidget(wrapInApp(buildSidebar(
        isPaused: false,
        isPlaying: true,
        isDrawingMode: false,
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
        isDrawingMode: false,
        canUndo: true,
        canRedo: true,
        hasDrawings: true,
        onUndo: () => undoPressed = true,
        onRedo: () => redoPressed = true,
        onClearDrawing: () => clearPressed = true,
      )));

      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();
      expect(undoPressed, isFalse, reason: 'Undo should be disabled outside drawing mode');

      await tester.tap(find.byIcon(Icons.redo));
      await tester.pump();
      expect(redoPressed, isFalse, reason: 'Redo should be disabled outside drawing mode');

      await tester.tap(find.byIcon(Icons.cleaning_services));
      await tester.pump();
      expect(clearPressed, isFalse, reason: 'Clear should be disabled outside drawing mode');
    });

    testWidgets('undo/redo/clear are enabled in drawing mode when applicable', (tester) async {
      var undoPressed = false;
      var redoPressed = false;
      var clearPressed = false;

      await tester.pumpWidget(wrapInApp(buildSidebar(
        isPaused: true,
        isDrawingMode: true,
        canUndo: true,
        canRedo: true,
        hasDrawings: true,
        onUndo: () => undoPressed = true,
        onRedo: () => redoPressed = true,
        onClearDrawing: () => clearPressed = true,
      )));

      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();
      expect(undoPressed, isTrue);

      await tester.tap(find.byIcon(Icons.redo));
      await tester.pump();
      expect(redoPressed, isTrue);

      await tester.tap(find.byIcon(Icons.cleaning_services));
      await tester.pump();
      expect(clearPressed, isTrue);
    });

    testWidgets('undo disabled in drawing mode when canUndo is false', (tester) async {
      var undoPressed = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        isPaused: true,
        isDrawingMode: true,
        canUndo: false,
        onUndo: () => undoPressed = true,
      )));

      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();
      expect(undoPressed, isFalse);
    });

    testWidgets('redo disabled in drawing mode when canRedo is false', (tester) async {
      var redoPressed = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        isPaused: true,
        isDrawingMode: true,
        canRedo: false,
        onRedo: () => redoPressed = true,
      )));

      await tester.tap(find.byIcon(Icons.redo));
      await tester.pump();
      expect(redoPressed, isFalse);
    });

    testWidgets('clear disabled in drawing mode when no drawings', (tester) async {
      var clearPressed = false;
      await tester.pumpWidget(wrapInApp(buildSidebar(
        isPaused: true,
        isDrawingMode: true,
        hasDrawings: false,
        onClearDrawing: () => clearPressed = true,
      )));

      await tester.tap(find.byIcon(Icons.cleaning_services));
      await tester.pump();
      expect(clearPressed, isFalse);
    });
  });

  group('v4: Sidebar full-height layout', () {
    testWidgets('sidebar fills available height', (tester) async {
      await tester.pumpWidget(wrapInApp(buildSidebar()));

      // The SizedBox wrapping the sidebar should expand to fill the Row's
      // cross-axis (full height of the Scaffold body).
      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(ColoredBox),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.width, 160); // expanded mode (viewMode.both)

      // Verify the sidebar's rendered height matches the Row parent's height.
      final sidebarBox = tester.getSize(find.byType(ColoredBox).first);
      final rowSize = tester.getSize(find.byType(Row).first);
      expect(sidebarBox.height, rowSize.height);
    });

    testWidgets('buttons are top-aligned', (tester) async {
      await tester.pumpWidget(wrapInApp(buildSidebar()));

      // The Column inside should have MainAxisAlignment.start.
      final column = tester.widget<Column>(find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Column),
      ));
      expect(column.mainAxisAlignment, MainAxisAlignment.start);
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
