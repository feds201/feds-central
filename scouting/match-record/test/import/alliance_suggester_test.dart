import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/import/alliance_suggester.dart';

void main() {
  group('AllianceSuggester', () {
    test('red alliance config returns "red"', () {
      final result =
          AllianceSuggester.suggest(configJsonContent: '{"alliance": "red"}');
      expect(result.side, 'red');
    });

    test('blue alliance config returns "blue"', () {
      final result =
          AllianceSuggester.suggest(configJsonContent: '{"alliance": "blue"}');
      expect(result.side, 'blue');
    });

    test('case insensitive - uppercase RED returns "red"', () {
      final result =
          AllianceSuggester.suggest(configJsonContent: '{"alliance": "RED"}');
      expect(result.side, 'red');
    });

    test('case insensitive - mixed case Blue returns "blue"', () {
      final result =
          AllianceSuggester.suggest(configJsonContent: '{"alliance": "Blue"}');
      expect(result.side, 'blue');
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

    test('missing alliance key returns null side', () {
      final result =
          AllianceSuggester.suggest(configJsonContent: '{"team": "201"}');
      expect(result.side, isNull);
    });

    test('empty string returns null side', () {
      final result = AllianceSuggester.suggest(configJsonContent: '');
      expect(result.side, isNull);
    });

    test('alliance value that is not red or blue returns null side', () {
      final result =
          AllianceSuggester.suggest(configJsonContent: '{"alliance": "green"}');
      expect(result.side, isNull);
    });

    test('alliance value is a number returns null side', () {
      final result =
          AllianceSuggester.suggest(configJsonContent: '{"alliance": 42}');
      expect(result.side, isNull);
    });

    test('alliance value with whitespace is handled', () {
      final result = AllianceSuggester.suggest(
          configJsonContent: '{"alliance": " red "}');
      expect(result.side, 'red');
    });

    test('JSON array instead of object returns null side', () {
      final result =
          AllianceSuggester.suggest(configJsonContent: '["red", "blue"]');
      expect(result.side, isNull);
    });
  });
}
