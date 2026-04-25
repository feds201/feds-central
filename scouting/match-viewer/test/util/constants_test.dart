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

    test('allianceCategory is green', () {
      expect(AppColors.allianceCategory, Colors.green);
    });

    test('searchCategory is blue', () {
      expect(AppColors.searchCategory, Colors.blue);
    });
  });

  group('AppColors alliance colors', () {
    test('base alliance colors are defined', () {
      expect(AppColors.redAlliance, Colors.red);
      expect(AppColors.blueAlliance, Colors.blue);
      expect(AppColors.fullAlliance, Colors.green);
    });

    test('light alliance colors are shade300 variants', () {
      expect(AppColors.redAllianceLight, Colors.red.shade300);
      expect(AppColors.blueAllianceLight, Colors.blue.shade300);
      expect(AppColors.fullAllianceLight, Colors.green.shade300);
    });

    test('colorForAllianceSide returns correct color for red', () {
      expect(AppColors.colorForAllianceSide('red'), AppColors.redAlliance);
    });

    test('colorForAllianceSide returns correct color for blue', () {
      expect(AppColors.colorForAllianceSide('blue'), AppColors.blueAlliance);
    });

    test('colorForAllianceSide returns full color for full', () {
      expect(AppColors.colorForAllianceSide('full'), AppColors.fullAlliance);
    });

    test('colorForAllianceSide defaults to full for unknown values', () {
      expect(AppColors.colorForAllianceSide(''), AppColors.fullAlliance);
      expect(AppColors.colorForAllianceSide('unknown'), AppColors.fullAlliance);
    });

    test('lightColorForAllianceSide returns correct light color for red', () {
      expect(AppColors.lightColorForAllianceSide('red'), AppColors.redAllianceLight);
    });

    test('lightColorForAllianceSide returns correct light color for blue', () {
      expect(AppColors.lightColorForAllianceSide('blue'), AppColors.blueAllianceLight);
    });

    test('lightColorForAllianceSide returns full light color for full', () {
      expect(AppColors.lightColorForAllianceSide('full'), AppColors.fullAllianceLight);
    });

    test('lightColorForAllianceSide defaults to full for unknown values', () {
      expect(AppColors.lightColorForAllianceSide(''), AppColors.fullAllianceLight);
      expect(AppColors.lightColorForAllianceSide('unknown'), AppColors.fullAllianceLight);
    });
  });
}
