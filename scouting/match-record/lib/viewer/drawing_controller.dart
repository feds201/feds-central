import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../util/constants.dart';

/// Color for a drawing stroke.
enum DrawingColor {
  red,
  blue;

  Color get color {
    switch (this) {
      case DrawingColor.red:
        return AppColors.redAlliance;
      case DrawingColor.blue:
        return AppColors.blueAlliance;
    }
  }
}

/// A completed or in-progress stroke with its color.
class ColoredStroke {
  final List<Offset> points;
  final DrawingColor color;

  ColoredStroke(this.points, this.color);

  bool get isEmpty => points.isEmpty;
  bool get isNotEmpty => points.isNotEmpty;
}

/// Manages drawing strokes with undo/redo support.
///
/// Extends [ChangeNotifier] so widgets can rebuild when strokes change.
class DrawingController extends ChangeNotifier {
  final List<ColoredStroke> _strokes = [];
  List<Offset> _currentStrokePoints = [];
  DrawingColor _currentColor = DrawingColor.red;
  final List<ColoredStroke> _redoStack = [];
  double _opacity = 1.0;

  /// All completed strokes.
  List<ColoredStroke> get strokes => List.unmodifiable(_strokes);

  /// The stroke currently being drawn (empty if no active drawing).
  List<Offset> get currentStrokePoints => List.unmodifiable(_currentStrokePoints);

  /// Color of the stroke currently being drawn.
  DrawingColor get currentColor => _currentColor;

  /// Current drawing opacity (1.0 when paused, 0.5 when playing).
  double get opacity => _opacity;

  bool get canUndo => _strokes.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// Whether any stroke contains actual points (not just no-op empty strokes).
  bool get hasNonEmptyStrokes => _strokes.any((s) => s.isNotEmpty);

  /// Set the color for new strokes.
  void setColor(DrawingColor color) {
    _currentColor = color;
  }

  /// Called when a pointer makes contact with the surface.
  void onPointerDown(Offset position) {
    _currentStrokePoints = [position];
    notifyListeners();
  }

  /// Called when a pointer moves across the surface.
  void onPointerMove(Offset position) {
    _currentStrokePoints.add(position);
    notifyListeners();
  }

  /// Called when a pointer lifts from the surface. Finalizes the current stroke.
  void onPointerUp() {
    if (_currentStrokePoints.isNotEmpty) {
      _strokes.add(ColoredStroke(List.of(_currentStrokePoints), _currentColor));
      _currentStrokePoints = [];
      _redoStack.clear();
      notifyListeners();
    }
  }

  /// Cancel the current in-progress stroke without finalizing it.
  /// Used when a 2nd finger is detected, converting the gesture to zoom/pan.
  void cancelStroke() {
    if (_currentStrokePoints.isNotEmpty) {
      _currentStrokePoints = [];
      notifyListeners();
    }
  }

  /// Remove the last stroke from the stack without pushing to redo.
  /// Used to clean up a no-op that was pushed before the gesture was
  /// recognized as multi-touch.
  void popLastStroke() {
    if (_strokes.isNotEmpty) {
      _strokes.removeLast();
      notifyListeners();
    }
  }

  /// Undo the last completed stroke.
  void undo() {
    if (_strokes.isNotEmpty) {
      _redoStack.add(_strokes.removeLast());
      notifyListeners();
    }
  }

  /// Redo the last undone stroke.
  void redo() {
    if (_redoStack.isNotEmpty) {
      _strokes.add(_redoStack.removeLast());
      notifyListeners();
    }
  }

  /// Clear all strokes and the redo stack.
  void clear() {
    _strokes.clear();
    _currentStrokePoints = [];
    _redoStack.clear();
    notifyListeners();
  }

  /// Push an empty stroke (no-op) to keep undo stacks synced across controllers.
  ///
  /// When drawing on one pane, the other pane's controller gets a pushNoOp()
  /// so that undo/redo operations stay aligned between the two controllers.
  void pushNoOp() {
    _strokes.add(ColoredStroke([], _currentColor));
    _redoStack.clear();
    notifyListeners();
  }

  /// Set drawing opacity. Use 1.0 when paused, 0.5 when playing.
  void setOpacity(double value) {
    if (_opacity != value) {
      _opacity = value;
      notifyListeners();
    }
  }
}
