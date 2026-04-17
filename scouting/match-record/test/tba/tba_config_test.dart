import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/tba/tba_config.dart';

void main() {
  group('TbaConfig.resolveApiKey', () {
    test('returns settings override when non-empty', () {
      final result = TbaConfig.resolveApiKey('my-custom-key');
      expect(result, 'my-custom-key');
    });

    test('returns null when settings override is null and dotenv not loaded', () {
      // dotenv is not loaded in tests, so dotenvApiKey returns null
      final result = TbaConfig.resolveApiKey(null);
      expect(result, isNull);
    });

    test('returns null when settings override is empty string', () {
      final result = TbaConfig.resolveApiKey('');
      expect(result, isNull);
    });

    test('prefers settings override over dotenv', () {
      // Even if dotenv has a value, settings override takes priority
      final result = TbaConfig.resolveApiKey('override-key');
      expect(result, 'override-key');
    });
  });

  group('TbaConfig.dotenvApiKey', () {
    test('returns null when dotenv not loaded', () {
      expect(TbaConfig.dotenvApiKey, isNull);
    });
  });
}
