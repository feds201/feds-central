import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Manages drawing strokes with undo/redo support.
///
/// Extends [ChangeNotifier] so widgets can rebuild when strokes change.
class DrawingController extends ChangeNotifier {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  final List<List<Offset>> _redoStack = [];
  double _opacity = 1.0;

  /// All completed strokes.
  List<List<Offset>> get strokes => List.unmodifiable(_strokes);

  /// The stroke currently being drawn (empty if no active drawing).
  List<Offset> get currentStroke => List.unmodifiable(_currentStroke);

  /// Current drawing opacity (1.0 when paused, 0.5 when playing).
  double get opacity => _opacity;

  bool get canUndo => _strokes.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// Called when a pointer makes contact with the surface.
  void onPointerDown(Offset position) {
    _currentStroke = [position];
    notifyListeners();
  }

  /// Called when a pointer moves across the surface.
  void onPointerMove(Offset position) {
    _currentStroke.add(position);
    notifyListeners();
  }

  /// Called when a pointer lifts from the surface. Finalizes the current stroke.
  void onPointerUp() {
    if (_currentStroke.isNotEmpty) {
      _strokes.add(List.of(_currentStroke));
      _currentStroke = [];
      _redoStack.clear();
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
    _currentStroke = [];
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
