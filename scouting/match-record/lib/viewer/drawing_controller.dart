import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../util/constants.dart';

/// Color for a drawing stroke.
enum DrawingColor {
  red;

  Color get color {
    switch (this) {
      case DrawingColor.red:
        return AppColors.redAlliance;
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

  // Deadzone state: ignore moves < touchDeadZonePx from initial down position
  Offset? _downPosition;
  bool _deadzonePassed = false;

  /// All completed strokes.
  List<ColoredStroke> get strokes => List.unmodifiable(_strokes);

  /// The stroke currently being drawn (empty if no active drawing).
  List<Offset> get currentStrokePoints => List.unmodifiable(_currentStrokePoints);

  /// Color of the stroke currently being drawn.
  DrawingColor get currentColor => _currentColor;

  /// Current drawing opacity (1.0 when paused, reduced when playing).
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
  ///
  /// Stores the initial position for deadzone checking. No stroke points are
  /// added and no listeners are notified until the finger moves past the
  /// deadzone (see [onPointerMove]).
  void onPointerDown(Offset position) {
    _downPosition = position;
    _deadzonePassed = false;
  }

  /// Called when a pointer moves across the surface.
  ///
  /// If the finger hasn't moved [AppConstants.touchDeadZonePx] from the
  /// initial down position, the move is ignored. Once the deadzone is passed,
  /// the initial down position and current position are added as the first
  /// two stroke points, and subsequent moves append normally.
  void onPointerMove(Offset position) {
    if (_downPosition == null) return;

    if (!_deadzonePassed) {
      final dx = position.dx - _downPosition!.dx;
      final dy = position.dy - _downPosition!.dy;
      final distance = sqrt(dx * dx + dy * dy);
      if (distance < AppConstants.touchDeadZonePx) return;

      _deadzonePassed = true;
      _currentStrokePoints = [_downPosition!, position];
      notifyListeners();
      return;
    }

    _currentStrokePoints.add(position);
    notifyListeners();
  }

  /// Called when a pointer lifts from the surface. Finalizes the current stroke.
  ///
  /// If the deadzone was never passed (finger didn't move enough), no stroke
  /// is created and state is silently reset.
  void onPointerUp() {
    if (!_deadzonePassed) {
      _downPosition = null;
      return;
    }

    _downPosition = null;
    _deadzonePassed = false;
    if (_currentStrokePoints.isNotEmpty) {
      _strokes.add(ColoredStroke(List.of(_currentStrokePoints), _currentColor));
      _currentStrokePoints = [];
      _redoStack.clear();
      notifyListeners();
    }
  }

  /// Cancel the current in-progress stroke without finalizing it.
  /// Used when a 2nd finger is detected, converting the gesture to zoom/pan.
  /// Resets deadzone state unconditionally.
  void cancelStroke() {
    _downPosition = null;
    _deadzonePassed = false;
    if (_currentStrokePoints.isNotEmpty) {
      _currentStrokePoints = [];
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
    _downPosition = null;
    _deadzonePassed = false;
    notifyListeners();
  }

  /// Set drawing opacity. Use 1.0 when paused, lower when playing.
  void setOpacity(double value) {
    if (_opacity != value) {
      _opacity = value;
      notifyListeners();
    }
  }
}
