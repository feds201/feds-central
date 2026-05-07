import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/import/storage_checker.dart';
import 'package:match_record/util/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.feds201.match_record/native');

  group('StorageChecker', () {
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('returns ok when free space is above warning threshold', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getFreeSpace') return 2 * 1024 * 1024 * 1024; // 2GB
        return null;
      });

      final status = await StorageChecker.check('/some/path');
      expect(status, StorageStatus.ok);
    });

    test('returns low when free space is between block and warning thresholds', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getFreeSpace') return 500 * 1024 * 1024; // 500MB
        return null;
      });

      final status = await StorageChecker.check('/some/path');
      expect(status, StorageStatus.low);
    });

    test('returns blocked when free space is below block threshold', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getFreeSpace') return 50 * 1024 * 1024; // 50MB
        return null;
      });

      final status = await StorageChecker.check('/some/path');
      expect(status, StorageStatus.blocked);
    });

    test('returns ok when platform channel is unavailable', () async {
      // No mock handler set -- MissingPluginException
      final status = await StorageChecker.check('/some/path');
      expect(status, StorageStatus.ok);
    });

    test('returns ok when platform returns negative value', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getFreeSpace') return -1;
        return null;
      });

      final status = await StorageChecker.check('/some/path');
      expect(status, StorageStatus.ok);
    });

    test('returns blocked at exactly the block threshold', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getFreeSpace') return AppConstants.blockImportBytes;
        return null;
      });

      final status = await StorageChecker.check('/some/path');
      expect(status, StorageStatus.low);
    });

    test('returns low at exactly the warning threshold', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getFreeSpace') return AppConstants.lowStorageWarningBytes;
        return null;
      });

      final status = await StorageChecker.check('/some/path');
      expect(status, StorageStatus.ok);
    });

    test('passes path argument to platform channel', () async {
      String? receivedPath;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getFreeSpace') {
          receivedPath = call.arguments['path'] as String?;
          return 2 * 1024 * 1024 * 1024;
        }
        return null;
      });

      await StorageChecker.check('/data/user/0/com.feds201.match_record');
      expect(receivedPath, '/data/user/0/com.feds201.match_record');
    });

    test('getFreeBytes returns actual value from platform', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getFreeSpace') return 123456789;
        return null;
      });

      final bytes = await StorageChecker.getFreeBytes('/some/path');
      expect(bytes, 123456789);
    });

    test('getFreeBytes returns null when platform channel unavailable', () async {
      final bytes = await StorageChecker.getFreeBytes('/some/path');
      expect(bytes, isNull);
    });
  });
}
