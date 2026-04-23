import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/util/constants.dart';
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

  // Moves far enough from origin to pass the deadzone
  const pastDeadzone = Offset(10, 10);

  /// Simulates a complete stroke: down at [start], move to [end], up.
  /// [end] must be far enough from [start] to pass the deadzone.
  void drawStroke(DrawingController c, Offset start, Offset end) {
    c.onPointerDown(start);
    c.onPointerMove(end);
    c.onPointerUp();
  }

  group('DrawingController stroke creation', () {
    test('initial state has no strokes', () {
      expect(controller.strokes, isEmpty);
      expect(controller.currentStrokePoints, isEmpty);
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isFalse);
      expect(controller.opacity, 1.0);
    });

    test('pointer down does not start a visible stroke', () {
      controller.onPointerDown(const Offset(10, 20));
      expect(controller.currentStrokePoints, isEmpty);
      expect(controller.strokes, isEmpty);
    });

    test('pointer move past deadzone starts current stroke with two points', () {
      controller.onPointerDown(const Offset(0, 0));
      controller.onPointerMove(pastDeadzone);
      expect(controller.currentStrokePoints, hasLength(2));
      expect(controller.currentStrokePoints[0], const Offset(0, 0));
      expect(controller.currentStrokePoints[1], pastDeadzone);
    });

    test('additional pointer moves append to current stroke', () {
      controller.onPointerDown(const Offset(0, 0));
      controller.onPointerMove(pastDeadzone);
      controller.onPointerMove(const Offset(30, 40));
      controller.onPointerMove(const Offset(50, 60));
      expect(controller.currentStrokePoints, hasLength(4));
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
      drawStroke(controller, const Offset(0, 0), const Offset(10, 10));
      drawStroke(controller, const Offset(20, 20), const Offset(30, 30));

      expect(controller.strokes, hasLength(2));
    });

    test('pointer up without prior down does not add stroke', () {
      controller.onPointerUp();
      expect(controller.strokes, isEmpty);
    });
  });

  group('DrawingController undo/redo', () {
    test('undo removes last stroke', () {
      drawStroke(controller, const Offset(0, 0), pastDeadzone);
      drawStroke(controller, const Offset(20, 20), const Offset(30, 30));

      expect(controller.strokes, hasLength(2));

      controller.undo();
      expect(controller.strokes, hasLength(1));
      expect(controller.canUndo, isTrue);
      expect(controller.canRedo, isTrue);
    });

    test('redo restores undone stroke', () {
      drawStroke(controller, const Offset(0, 0), pastDeadzone);

      controller.undo();
      expect(controller.strokes, isEmpty);

      controller.redo();
      expect(controller.strokes, hasLength(1));
      expect(controller.canRedo, isFalse);
    });

    test('new stroke clears redo stack', () {
      drawStroke(controller, const Offset(0, 0), pastDeadzone);
      drawStroke(controller, const Offset(20, 20), const Offset(30, 30));

      controller.undo();
      expect(controller.canRedo, isTrue);

      // New stroke should clear redo
      drawStroke(controller, const Offset(40, 40), const Offset(50, 50));
      expect(controller.canRedo, isFalse);
    });

    test('undo with no strokes does nothing', () {
      final countBefore = notifyCount;
      controller.undo();
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

      drawStroke(controller, const Offset(0, 0), pastDeadzone);
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
      drawStroke(controller, const Offset(0, 0), pastDeadzone);
      drawStroke(controller, const Offset(20, 20), const Offset(30, 30));
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
    test('onPointerDown does not notify', () {
      final countBefore = notifyCount;
      controller.onPointerDown(const Offset(0, 0));
      expect(notifyCount, countBefore);
    });

    test('onPointerMove past deadzone notifies', () {
      controller.onPointerDown(const Offset(0, 0));
      final countBefore = notifyCount;
      controller.onPointerMove(pastDeadzone);
      expect(notifyCount, countBefore + 1);
    });

    test('onPointerMove within deadzone does not notify', () {
      controller.onPointerDown(const Offset(0, 0));
      final countBefore = notifyCount;
      controller.onPointerMove(const Offset(1, 1));
      expect(notifyCount, countBefore);
    });

    test('onPointerUp after passing deadzone notifies', () {
      controller.onPointerDown(const Offset(0, 0));
      controller.onPointerMove(pastDeadzone);
      final countBefore = notifyCount;
      controller.onPointerUp();
      expect(notifyCount, countBefore + 1);
    });

    test('onPointerUp without passing deadzone does not notify', () {
      controller.onPointerDown(const Offset(0, 0));
      final countBefore = notifyCount;
      controller.onPointerUp();
      expect(notifyCount, countBefore);
    });

    test('undo notifies when stroke exists', () {
      drawStroke(controller, const Offset(0, 0), pastDeadzone);
      final countBefore = notifyCount;
      controller.undo();
      expect(notifyCount, countBefore + 1);
    });

    test('redo notifies when redo stack is not empty', () {
      drawStroke(controller, const Offset(0, 0), pastDeadzone);
      controller.undo();
      final countBefore = notifyCount;
      controller.redo();
      expect(notifyCount, countBefore + 1);
    });

    test('clear notifies', () {
      drawStroke(controller, const Offset(0, 0), pastDeadzone);
      final countBefore = notifyCount;
      controller.clear();
      expect(notifyCount, countBefore + 1);
    });
  });

  group('DrawingController hasNonEmptyStrokes', () {
    test('false when no strokes', () {
      expect(controller.hasNonEmptyStrokes, isFalse);
    });

    test('true after real stroke', () {
      drawStroke(controller, const Offset(0, 0), pastDeadzone);
      expect(controller.hasNonEmptyStrokes, isTrue);
    });

    test('false after clearing', () {
      drawStroke(controller, const Offset(0, 0), pastDeadzone);
      controller.clear();
      expect(controller.hasNonEmptyStrokes, isFalse);
    });
  });

  group('DrawingController cancelStroke', () {
    test('discards in-progress stroke after deadzone passed', () {
      controller.onPointerDown(const Offset(10, 20));
      controller.onPointerMove(const Offset(30, 40));
      expect(controller.currentStrokePoints, hasLength(2));

      controller.cancelStroke();
      expect(controller.currentStrokePoints, isEmpty);
      expect(controller.strokes, isEmpty);
    });

    test('resets deadzone state when called before deadzone passed', () {
      controller.onPointerDown(const Offset(10, 20));
      // Finger hasn't moved past deadzone yet
      final countBefore = notifyCount;
      controller.cancelStroke();
      // No notify because no visual state changed
      expect(notifyCount, countBefore);

      // Verify state is clean: a new stroke should work normally
      controller.onPointerDown(const Offset(50, 50));
      controller.onPointerMove(const Offset(60, 60));
      expect(controller.currentStrokePoints, hasLength(2));
    });

    test('with no active gesture does nothing', () {
      final countBefore = notifyCount;
      controller.cancelStroke();
      expect(notifyCount, countBefore);
    });

    test('notifies when in-progress stroke has points', () {
      controller.onPointerDown(const Offset(10, 20));
      controller.onPointerMove(const Offset(30, 40));
      final countBefore = notifyCount;
      controller.cancelStroke();
      expect(notifyCount, countBefore + 1);
    });

    test('does not affect completed strokes', () {
      drawStroke(controller, const Offset(0, 0), pastDeadzone);
      expect(controller.strokes, hasLength(1));

      controller.onPointerDown(const Offset(10, 10));
      controller.onPointerMove(const Offset(20, 20));
      controller.cancelStroke();

      expect(controller.strokes, hasLength(1));
      expect(controller.currentStrokePoints, isEmpty);
    });

    test('does not affect redo stack', () {
      drawStroke(controller, const Offset(0, 0), pastDeadzone);
      controller.undo();
      expect(controller.canRedo, isTrue);

      controller.onPointerDown(const Offset(10, 10));
      controller.cancelStroke();
      expect(controller.canRedo, isTrue);
    });
  });

  group('DrawingController deadzone', () {
    test('move within deadzone does not start stroke', () {
      controller.onPointerDown(const Offset(100, 100));
      // Move less than touchDeadZonePx (3.0) away
      controller.onPointerMove(const Offset(101, 101));
      expect(controller.currentStrokePoints, isEmpty);
    });

    test('move exactly at deadzone boundary does not start stroke', () {
      controller.onPointerDown(const Offset(100, 100));
      // Distance of exactly 2.0 (< 3.0)
      controller.onPointerMove(const Offset(102, 100));
      expect(controller.currentStrokePoints, isEmpty);
    });

    test('move past deadzone starts stroke with down position and current', () {
      controller.onPointerDown(const Offset(100, 100));
      controller.onPointerMove(const Offset(104, 100));
      expect(controller.currentStrokePoints, hasLength(2));
      expect(controller.currentStrokePoints[0], const Offset(100, 100));
      expect(controller.currentStrokePoints[1], const Offset(104, 100));
    });

    test('up within deadzone discards without creating stroke', () {
      controller.onPointerDown(const Offset(100, 100));
      controller.onPointerMove(const Offset(101, 101));
      controller.onPointerUp();
      expect(controller.strokes, isEmpty);
      expect(controller.currentStrokePoints, isEmpty);
    });

    test('up without any move discards without creating stroke', () {
      controller.onPointerDown(const Offset(100, 100));
      controller.onPointerUp();
      expect(controller.strokes, isEmpty);
    });

    test('up after passing deadzone finalizes stroke', () {
      controller.onPointerDown(const Offset(100, 100));
      controller.onPointerMove(const Offset(110, 110));
      controller.onPointerUp();
      expect(controller.strokes, hasLength(1));
      expect(controller.strokes[0].points, hasLength(2));
    });

    test('deadzone is measured from initial down position', () {
      controller.onPointerDown(const Offset(100, 100));
      // Move 1px right — still in deadzone
      controller.onPointerMove(const Offset(101, 100));
      expect(controller.currentStrokePoints, isEmpty);
      // Move another 1px right — still in deadzone (2px total from origin)
      controller.onPointerMove(const Offset(102, 100));
      expect(controller.currentStrokePoints, isEmpty);
      // Move past deadzone (4px from origin)
      controller.onPointerMove(const Offset(104, 100));
      expect(controller.currentStrokePoints, hasLength(2));
      expect(controller.currentStrokePoints[0], const Offset(100, 100),
          reason: 'First point should be the original down position');
    });

    test('deadzone uses Euclidean distance', () {
      controller.onPointerDown(const Offset(0, 0));
      // Move diagonally: sqrt(2*2 + 2*2) = sqrt(8) ≈ 2.83 < 3.0
      controller.onPointerMove(const Offset(2, 2));
      expect(controller.currentStrokePoints, isEmpty,
          reason: 'Diagonal distance ~2.83px should be within 3px deadzone');

      // sqrt(2.5*2.5 + 2.5*2.5) = sqrt(12.5) ≈ 3.54 >= 3.0
      controller.onPointerMove(const Offset(2.5, 2.5));
      expect(controller.currentStrokePoints, hasLength(2),
          reason: 'Diagonal distance ~3.54px should pass 3px deadzone');
    });

    test('deadzone resets between strokes', () {
      // First stroke passes deadzone
      drawStroke(controller, const Offset(0, 0), pastDeadzone);
      expect(controller.strokes, hasLength(1));

      // Second stroke: deadzone should apply fresh
      controller.onPointerDown(const Offset(50, 50));
      controller.onPointerMove(const Offset(51, 51));
      expect(controller.currentStrokePoints, isEmpty,
          reason: 'Deadzone should reset for each new stroke');
    });

    test('onPointerMove without prior onPointerDown is ignored', () {
      controller.onPointerMove(const Offset(100, 100));
      expect(controller.currentStrokePoints, isEmpty);
      expect(notifyCount, 0);
    });

    test('uses touchDeadZonePx constant', () {
      // Verify the constant value we depend on
      expect(AppConstants.touchDeadZonePx, 3.0);
    });
  });
}
