import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/viewer/drawing_controller.dart';

void main() {
  late DrawingController controller;
  late int notifyCount;

  setUp(() {
    controller = DrawingController();
    notifyCount = 0;
    controller.addListener(() => notifyCount++);
  });

  tearDown(() {
    controller.dispose();
  });

  group('DrawingController stroke creation', () {
    test('initial state has no strokes', () {
      expect(controller.strokes, isEmpty);
      expect(controller.currentStrokePoints, isEmpty);
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isFalse);
      expect(controller.opacity, 1.0);
    });

    test('pointer down starts a current stroke', () {
      controller.onPointerDown(const Offset(10, 20));
      expect(controller.currentStrokePoints, hasLength(1));
      expect(controller.currentStrokePoints[0], const Offset(10, 20));
      expect(controller.strokes, isEmpty);
    });

    test('pointer move adds points to current stroke', () {
      controller.onPointerDown(const Offset(10, 20));
      controller.onPointerMove(const Offset(30, 40));
      controller.onPointerMove(const Offset(50, 60));
      expect(controller.currentStrokePoints, hasLength(3));
    });

    test('pointer up finalizes stroke and clears current', () {
      controller.onPointerDown(const Offset(10, 20));
      controller.onPointerMove(const Offset(30, 40));
      controller.onPointerUp();

      expect(controller.strokes, hasLength(1));
      expect(controller.strokes[0].points, hasLength(2));
      expect(controller.currentStrokePoints, isEmpty);
    });

    test('multiple strokes accumulate', () {
      // Stroke 1
      controller.onPointerDown(const Offset(0, 0));
      controller.onPointerMove(const Offset(10, 10));
      controller.onPointerUp();

      // Stroke 2
      controller.onPointerDown(const Offset(20, 20));
      controller.onPointerMove(const Offset(30, 30));
      controller.onPointerUp();

      expect(controller.strokes, hasLength(2));
    });

    test('pointer up with empty current stroke does not add stroke', () {
      controller.onPointerUp();
      expect(controller.strokes, isEmpty);
    });
  });

  group('DrawingController undo/redo', () {
    test('undo removes last stroke', () {
      controller.onPointerDown(const Offset(0, 0));
      controller.onPointerUp();
      controller.onPointerDown(const Offset(10, 10));
      controller.onPointerUp();

      expect(controller.strokes, hasLength(2));

      controller.undo();
      expect(controller.strokes, hasLength(1));
      expect(controller.canUndo, isTrue);
      expect(controller.canRedo, isTrue);
    });

    test('redo restores undone stroke', () {
      controller.onPointerDown(const Offset(0, 0));
      controller.onPointerUp();

      controller.undo();
      expect(controller.strokes, isEmpty);

      controller.redo();
      expect(controller.strokes, hasLength(1));
      expect(controller.canRedo, isFalse);
    });

    test('new stroke clears redo stack', () {
      controller.onPointerDown(const Offset(0, 0));
      controller.onPointerUp();
      controller.onPointerDown(const Offset(10, 10));
      controller.onPointerUp();

      controller.undo();
      expect(controller.canRedo, isTrue);

      // New stroke should clear redo
      controller.onPointerDown(const Offset(20, 20));
      controller.onPointerUp();
      expect(controller.canRedo, isFalse);
    });

    test('undo with no strokes does nothing', () {
      final countBefore = notifyCount;
      controller.undo();
      // Should not notify if nothing changed
      expect(notifyCount, countBefore);
    });

    test('redo with empty redo stack does nothing', () {
      final countBefore = notifyCount;
      controller.redo();
      expect(notifyCount, countBefore);
    });

    test('canUndo and canRedo track state correctly', () {
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isFalse);

      controller.onPointerDown(const Offset(0, 0));
      controller.onPointerUp();
      expect(controller.canUndo, isTrue);
      expect(controller.canRedo, isFalse);

      controller.undo();
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isTrue);

      controller.redo();
      expect(controller.canUndo, isTrue);
      expect(controller.canRedo, isFalse);
    });
  });

  group('DrawingController clear', () {
    test('clear removes all strokes and redo stack', () {
      controller.onPointerDown(const Offset(0, 0));
      controller.onPointerUp();
      controller.onPointerDown(const Offset(10, 10));
      controller.onPointerUp();
      controller.undo();

      controller.clear();
      expect(controller.strokes, isEmpty);
      expect(controller.currentStrokePoints, isEmpty);
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isFalse);
    });
  });

  group('DrawingController opacity', () {
    test('default opacity is 1.0', () {
      expect(controller.opacity, 1.0);
    });

    test('setOpacity changes value and notifies', () {
      final countBefore = notifyCount;
      controller.setOpacity(0.5);
      expect(controller.opacity, 0.5);
      expect(notifyCount, countBefore + 1);
    });

    test('setOpacity with same value does not notify', () {
      controller.setOpacity(0.5);
      final countBefore = notifyCount;
      controller.setOpacity(0.5);
      expect(notifyCount, countBefore);
    });
  });

  group('DrawingController notifyListeners', () {
    test('onPointerDown notifies', () {
      final countBefore = notifyCount;
      controller.onPointerDown(const Offset(0, 0));
      expect(notifyCount, countBefore + 1);
    });

    test('onPointerMove notifies', () {
      controller.onPointerDown(const Offset(0, 0));
      final countBefore = notifyCount;
      controller.onPointerMove(const Offset(10, 10));
      expect(notifyCount, countBefore + 1);
    });

    test('onPointerUp notifies', () {
      controller.onPointerDown(const Offset(0, 0));
      final countBefore = notifyCount;
      controller.onPointerUp();
      expect(notifyCount, countBefore + 1);
    });

    test('undo notifies when stroke exists', () {
      controller.onPointerDown(const Offset(0, 0));
      controller.onPointerUp();
      final countBefore = notifyCount;
      controller.undo();
      expect(notifyCount, countBefore + 1);
    });

    test('redo notifies when redo stack is not empty', () {
      controller.onPointerDown(const Offset(0, 0));
      controller.onPointerUp();
      controller.undo();
      final countBefore = notifyCount;
      controller.redo();
      expect(notifyCount, countBefore + 1);
    });

    test('clear notifies', () {
      controller.onPointerDown(const Offset(0, 0));
      controller.onPointerUp();
      final countBefore = notifyCount;
      controller.clear();
      expect(notifyCount, countBefore + 1);
    });
  });

  group('DrawingController pushNoOp', () {
    test('pushNoOp adds empty stroke to strokes list', () {
      controller.pushNoOp();
      expect(controller.strokes, hasLength(1));
      expect(controller.strokes[0].isEmpty, isTrue);
    });

    test('pushNoOp clears redo stack', () {
      controller.onPointerDown(const Offset(0, 0));
      controller.onPointerUp();
      controller.undo();
      expect(controller.canRedo, isTrue);

      controller.pushNoOp();
      expect(controller.canRedo, isFalse);
    });

    test('pushNoOp notifies listeners', () {
      final countBefore = notifyCount;
      controller.pushNoOp();
      expect(notifyCount, countBefore + 1);
    });

    test('pushNoOp keeps undo stacks synced between two controllers', () {
      final controller2 = DrawingController();

      // Draw on controller1, no-op on controller2
      controller.onPointerDown(const Offset(10, 10));
      controller.onPointerMove(const Offset(20, 20));
      controller.onPointerUp();
      controller2.pushNoOp();

      expect(controller.strokes, hasLength(1));
      expect(controller2.strokes, hasLength(1));

      // Undo both — both should have 0 strokes
      controller.undo();
      controller2.undo();
      expect(controller.strokes, isEmpty);
      expect(controller2.strokes, isEmpty);

      // Redo both
      controller.redo();
      controller2.redo();
      expect(controller.strokes, hasLength(1));
      expect(controller2.strokes, hasLength(1));
      // controller1 has the real stroke, controller2 has the no-op
      expect(controller.strokes[0].isNotEmpty, isTrue);
      expect(controller2.strokes[0].isEmpty, isTrue);

      controller2.dispose();
    });

    test('canUndo is true after pushNoOp', () {
      controller.pushNoOp();
      expect(controller.canUndo, isTrue);
    });

    test('undo after pushNoOp removes the empty stroke', () {
      controller.pushNoOp();
      controller.undo();
      expect(controller.strokes, isEmpty);
      expect(controller.canUndo, isFalse);
    });
  });

  group('DrawingController hasNonEmptyStrokes', () {
    test('false when no strokes', () {
      expect(controller.hasNonEmptyStrokes, isFalse);
    });

    test('true after real stroke', () {
      controller.onPointerDown(const Offset(0, 0));
      controller.onPointerUp();
      expect(controller.hasNonEmptyStrokes, isTrue);
    });

    test('false after only no-op strokes', () {
      controller.pushNoOp();
      controller.pushNoOp();
      expect(controller.hasNonEmptyStrokes, isFalse);
    });

    test('true when mix of real and no-op strokes', () {
      controller.pushNoOp();
      controller.onPointerDown(const Offset(0, 0));
      controller.onPointerUp();
      controller.pushNoOp();
      expect(controller.hasNonEmptyStrokes, isTrue);
    });

    test('false after clearing', () {
      controller.onPointerDown(const Offset(0, 0));
      controller.onPointerUp();
      controller.clear();
      expect(controller.hasNonEmptyStrokes, isFalse);
    });
  });

  group('DrawingController cancelStroke', () {
    test('discards in-progress stroke', () {
      controller.onPointerDown(const Offset(10, 20));
      controller.onPointerMove(const Offset(30, 40));
      expect(controller.currentStrokePoints, hasLength(2));

      controller.cancelStroke();
      expect(controller.currentStrokePoints, isEmpty);
      expect(controller.strokes, isEmpty);
    });

    test('with no in-progress stroke does nothing', () {
      final countBefore = notifyCount;
      controller.cancelStroke();
      expect(notifyCount, countBefore);
    });

    test('notifies listeners', () {
      controller.onPointerDown(const Offset(10, 20));
      final countBefore = notifyCount;
      controller.cancelStroke();
      expect(notifyCount, countBefore + 1);
    });

    test('does not affect completed strokes', () {
      controller.onPointerDown(const Offset(0, 0));
      controller.onPointerUp();
      expect(controller.strokes, hasLength(1));

      controller.onPointerDown(const Offset(10, 10));
      controller.onPointerMove(const Offset(20, 20));
      controller.cancelStroke();

      expect(controller.strokes, hasLength(1));
      expect(controller.currentStrokePoints, isEmpty);
    });

    test('does not affect redo stack', () {
      controller.onPointerDown(const Offset(0, 0));
      controller.onPointerUp();
      controller.undo();
      expect(controller.canRedo, isTrue);

      controller.onPointerDown(const Offset(10, 10));
      controller.cancelStroke();
      expect(controller.canRedo, isTrue);
    });
  });

  group('DrawingController popLastStroke', () {
    test('removes last stroke', () {
      controller.onPointerDown(const Offset(0, 0));
      controller.onPointerUp();
      controller.onPointerDown(const Offset(10, 10));
      controller.onPointerUp();
      expect(controller.strokes, hasLength(2));

      controller.popLastStroke();
      expect(controller.strokes, hasLength(1));
    });

    test('does not push to redo stack', () {
      controller.onPointerDown(const Offset(0, 0));
      controller.onPointerUp();

      controller.popLastStroke();
      expect(controller.strokes, isEmpty);
      expect(controller.canRedo, isFalse);
    });

    test('with no strokes does nothing', () {
      final countBefore = notifyCount;
      controller.popLastStroke();
      expect(notifyCount, countBefore);
    });

    test('notifies listeners', () {
      controller.onPointerDown(const Offset(0, 0));
      controller.onPointerUp();
      final countBefore = notifyCount;
      controller.popLastStroke();
      expect(notifyCount, countBefore + 1);
    });

    test('cleans up no-op after cancelled multi-touch draw', () {
      final controller2 = DrawingController();

      // Simulate: draw starts on controller1, no-op pushed to controller2
      controller.onPointerDown(const Offset(10, 10));
      controller.onPointerMove(const Offset(20, 20));
      controller2.pushNoOp();

      // Multi-touch detected: cancel stroke on controller1, pop no-op on controller2
      controller.cancelStroke();
      controller2.popLastStroke();

      expect(controller.strokes, isEmpty);
      expect(controller.currentStrokePoints, isEmpty);
      expect(controller2.strokes, isEmpty);
      expect(controller.canUndo, isFalse);
      expect(controller2.canUndo, isFalse);

      controller2.dispose();
    });
  });
}
