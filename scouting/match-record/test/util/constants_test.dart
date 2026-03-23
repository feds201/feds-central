import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/util/constants.dart';

void main() {
  group('AppColors', () {
    test('category colors are defined and distinct', () {
      final colors = [
        AppColors.searchCategory,
        AppColors.teamCategory,
        AppColors.matchCategory,
        AppColors.allianceCategory,
      ];

      // All 4 are non-null Material colors
      for (final color in colors) {
        expect(color, isA<Color>());
      }

      // All distinct from each other
      expect(colors.toSet().length, 4,
          reason: 'All four category colors should be distinct');
    });

    test('teamCategory is teal', () {
      expect(AppColors.teamCategory, Colors.teal);
    });

    test('matchCategory is orange', () {
      expect(AppColors.matchCategory, Colors.orange);
    });

    test('allianceCategory is purple', () {
      expect(AppColors.allianceCategory, Colors.purple);
    });

    test('searchCategory is blue', () {
      expect(AppColors.searchCategory, Colors.blue);
    });
  });
}
