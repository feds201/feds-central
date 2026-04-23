import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/import/alliance_suggester.dart';

void main() {
  group('AllianceSuggester', () {
    test('red type config returns "red"', () {
      final result =
          AllianceSuggester.suggest(configJsonContent: '{"type": "red"}');
      expect(result.side, 'red');
    });

    test('blue type config returns "blue"', () {
      final result =
          AllianceSuggester.suggest(configJsonContent: '{"type": "blue"}');
      expect(result.side, 'blue');
    });

    test('full type config returns "full"', () {
      final result =
          AllianceSuggester.suggest(configJsonContent: '{"type": "full"}');
      expect(result.side, 'full');
    });

    test('case insensitive - uppercase RED returns "red"', () {
      final result =
          AllianceSuggester.suggest(configJsonContent: '{"type": "RED"}');
      expect(result.side, 'red');
    });

    test('case insensitive - mixed case Blue returns "blue"', () {
      final result =
          AllianceSuggester.suggest(configJsonContent: '{"type": "Blue"}');
      expect(result.side, 'blue');
    });

    test('case insensitive - FULL uppercase returns "full"', () {
      final result =
          AllianceSuggester.suggest(configJsonContent: '{"type": "FULL"}');
      expect(result.side, 'full');
    });

    test('null config returns null side', () {
      final result = AllianceSuggester.suggest(configJsonContent: null);
      expect(result.side, isNull);
    });

    test('malformed JSON returns null side', () {
      final result = AllianceSuggester.suggest(
          configJsonContent: '{not valid json!!!}');
      expect(result.side, isNull);
    });

    test('missing type key returns null side', () {
      final result =
          AllianceSuggester.suggest(configJsonContent: '{"team": "201"}');
      expect(result.side, isNull);
    });

    test('empty string returns null side', () {
      final result = AllianceSuggester.suggest(configJsonContent: '');
      expect(result.side, isNull);
    });

    test('type value that is not red, blue, or full returns null side', () {
      final result =
          AllianceSuggester.suggest(configJsonContent: '{"type": "green"}');
      expect(result.side, isNull);
    });

    test('type value is a number returns null side', () {
      final result =
          AllianceSuggester.suggest(configJsonContent: '{"type": 42}');
      expect(result.side, isNull);
    });

    test('type value with whitespace is handled', () {
      final result = AllianceSuggester.suggest(
          configJsonContent: '{"type": " red "}');
      expect(result.side, 'red');
    });

    test('JSON array instead of object returns null side', () {
      final result =
          AllianceSuggester.suggest(configJsonContent: '["red", "blue"]');
      expect(result.side, isNull);
    });
  });
}
