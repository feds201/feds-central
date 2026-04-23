import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/util/result.dart';

void main() {
  group('Result', () {
    test('Ok holds a value', () {
      const result = Ok<int>(42);
      expect(result.value, 42);
    });

    test('Err holds a message', () {
      const result = Err<int>('something went wrong');
      expect(result.message, 'something went wrong');
    });

    test('Ok is a Result', () {
      const Result<int> result = Ok(42);
      expect(result, isA<Ok<int>>());
      expect(result, isNot(isA<Err<int>>()));
    });

    test('Err is a Result', () {
      const Result<int> result = Err('fail');
      expect(result, isA<Err<int>>());
      expect(result, isNot(isA<Ok<int>>()));
    });

    test('pattern matching with switch extracts Ok value', () {
      const Result<String> result = Ok('hello');
      final output = switch (result) {
        Ok<String>(value: final v) => 'got: $v',
        Err<String>(message: final m) => 'error: $m',
      };
      expect(output, 'got: hello');
    });

    test('pattern matching with switch extracts Err message', () {
      const Result<String> result = Err('bad');
      final output = switch (result) {
        Ok<String>(value: final v) => 'got: $v',
        Err<String>(message: final m) => 'error: $m',
      };
      expect(output, 'error: bad');
    });

    test('Ok with null value', () {
      const result = Ok<int?>(null);
      expect(result.value, isNull);
    });

    test('Err with empty message', () {
      const result = Err<int>('');
      expect(result.message, '');
    });
  });
}
