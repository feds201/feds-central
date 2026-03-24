import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/viewer/coordinate_transform.dart';

void main() {
  group('CoordinateTransform.inverseRotate', () {
    const paneSize = Size(400, 300);

    test('no rotation returns same point', () {
      const point = Offset(100, 50);
      final result = CoordinateTransform.inverseRotate(point, 0, paneSize);
      expect(result, const Offset(100, 50));
    });

    test('inverse of 90 CW rotation', () {
      // RotatedBox quarterTurns=1 rotates CW 90.
      // Inverse: (y, width - x)
      const point = Offset(100, 50);
      final result = CoordinateTransform.inverseRotate(point, 1, paneSize);
      expect(result, const Offset(50, 300)); // (y=50, width-x=400-100=300)
    });

    test('inverse of 180 rotation', () {
      const point = Offset(100, 50);
      final result = CoordinateTransform.inverseRotate(point, 2, paneSize);
      expect(result, const Offset(300, 250)); // (width-x=300, height-y=250)
    });

    test('inverse of 270 CW rotation', () {
      const point = Offset(100, 50);
      final result = CoordinateTransform.inverseRotate(point, 3, paneSize);
      expect(result, const Offset(250, 100)); // (height-y=300-50=250, x=100)
    });

    test('quarterTurns wraps around modulo 4', () {
      const point = Offset(100, 50);
      final result4 = CoordinateTransform.inverseRotate(point, 4, paneSize);
      expect(result4, const Offset(100, 50)); // same as 0

      final result5 = CoordinateTransform.inverseRotate(point, 5, paneSize);
      final result1 = CoordinateTransform.inverseRotate(point, 1, paneSize);
      expect(result5, result1); // same as 1
    });

    test('origin point', () {
      const origin = Offset(0, 0);

      expect(
        CoordinateTransform.inverseRotate(origin, 0, paneSize),
        const Offset(0, 0),
      );
      expect(
        CoordinateTransform.inverseRotate(origin, 1, paneSize),
        Offset(0, paneSize.width), // (0, 400)
      );
      expect(
        CoordinateTransform.inverseRotate(origin, 2, paneSize),
        Offset(paneSize.width, paneSize.height), // (400, 300)
      );
      expect(
        CoordinateTransform.inverseRotate(origin, 3, paneSize),
        Offset(paneSize.height, 0), // (300, 0)
      );
    });
  });

  group('CoordinateTransform.toVideoSpace', () {
    const paneSize = Size(400, 300);

    test('identity zoom with no rotation passes through', () {
      final identity = Matrix4.identity();
      const point = Offset(150, 100);
      final result = CoordinateTransform.toVideoSpace(
        point, identity, 0, paneSize,
      );
      expect(result, const Offset(150, 100));
    });

    test('2x zoom at origin maps point to half coordinates', () {
      // A 2x zoom centered at origin: the zoom matrix scales by 2,
      // so inverse maps (200, 100) → (100, 50)
      final zoom2x = Matrix4.identity()..scale(2.0, 2.0, 1.0);
      const point = Offset(200, 100);
      final result = CoordinateTransform.toVideoSpace(
        point, zoom2x, 0, paneSize,
      );
      expect(result.dx, closeTo(100, 0.01));
      expect(result.dy, closeTo(50, 0.01));
    });

    test('zoom with pan offset', () {
      // Zoom 2x with translation (50, 30): matrix = scale(2) * translate(50,30)
      // Actually InteractiveViewer's matrix is: translate then scale,
      // but let's test with a known matrix.
      final matrix = Matrix4.identity()
        ..translate(50.0, 30.0)
        ..scale(2.0, 2.0, 1.0);
      const point = Offset(250, 130);
      final result = CoordinateTransform.toVideoSpace(
        point, matrix, 0, paneSize,
      );
      // Inverse of scale(2)*translate(50,30) applied to (250, 130):
      // First inverse translate: (250-50, 130-30) = (200, 100)
      // Then inverse scale: (200/2, 100/2) = (100, 50)
      expect(result.dx, closeTo(100, 0.01));
      expect(result.dy, closeTo(50, 0.01));
    });

    test('identity zoom with 90 CW rotation applies inverse rotation', () {
      final identity = Matrix4.identity();
      const point = Offset(100, 50);
      final result = CoordinateTransform.toVideoSpace(
        point, identity, 1, paneSize,
      );
      // No zoom change, just inverse rotation: (y, width-x) = (50, 300)
      expect(result, const Offset(50, 300));
    });

    test('combined zoom and rotation', () {
      final zoom2x = Matrix4.identity()..scale(2.0, 2.0, 1.0);
      const point = Offset(200, 100);
      final result = CoordinateTransform.toVideoSpace(
        point, zoom2x, 1, paneSize,
      );
      // Step 1: inverse zoom (200/2, 100/2) = (100, 50)
      // Step 2: inverse rotate quarterTurns=1: (y, width-x) = (50, 400-100=300)
      expect(result.dx, closeTo(50, 0.01));
      expect(result.dy, closeTo(300, 0.01));
    });
  });
}
