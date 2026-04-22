import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:match_record/tba/tba_client.dart';
import 'package:match_record/util/result.dart';

class MockDio extends Mock implements Dio {}

void main() {
  group('TbaClient.hasApiKey', () {
    test('returns true when apiKey is provided', () {
      final client = TbaClient(apiKey: 'some-key', dio: MockDio());
      expect(client.hasApiKey, isTrue);
    });

    test('returns false when apiKey is null', () {
      final client = TbaClient(apiKey: null, dio: MockDio());
      expect(client.hasApiKey, isFalse);
    });

    test('returns false when apiKey is empty', () {
      final client = TbaClient(apiKey: '', dio: MockDio());
      expect(client.hasApiKey, isFalse);
    });
  });

  group('TbaClient.apiKey', () {
    test('stores the provided apiKey', () {
      final client = TbaClient(apiKey: 'test-key-123', dio: MockDio());
      expect(client.apiKey, 'test-key-123');
    });

    test('is null when not provided', () {
      final client = TbaClient(dio: MockDio());
      expect(client.apiKey, isNull);
    });
  });

  group('TbaClient without API key', () {
    test('creates client without crashing when no key provided', () {
      // Should not throw
      final client = TbaClient(apiKey: null, dio: MockDio());
      expect(client, isNotNull);
    });
  });
}
