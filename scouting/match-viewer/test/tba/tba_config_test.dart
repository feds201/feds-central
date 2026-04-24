import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/tba/tba_config.dart';

void main() {
  group('TbaConfig.resolveApiKey', () {
    test('returns settings override when non-empty', () {
      final result = TbaConfig.resolveApiKey('my-custom-key');
      expect(result, 'my-custom-key');
    });

    test('returns default when settings override is null', () {
      final result = TbaConfig.resolveApiKey(null);
      expect(result, TbaConfig.defaultApiKey);
    });

    test('returns default when settings override is empty string', () {
      final result = TbaConfig.resolveApiKey('');
      expect(result, TbaConfig.defaultApiKey);
    });
  });
}
