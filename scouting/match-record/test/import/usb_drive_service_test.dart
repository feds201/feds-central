import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/import/usb_drive_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('UsbDriveService.inferSideFromLabel', () {
    test('FEDS-RED returns "red"', () {
      expect(UsbDriveService.inferSideFromLabel('FEDS-RED'), 'red');
    });

    test('FEDS-BLUE returns "blue"', () {
      expect(UsbDriveService.inferSideFromLabel('FEDS-BLUE'), 'blue');
    });

    test('FEDS-FULL returns "full"', () {
      expect(UsbDriveService.inferSideFromLabel('FEDS-FULL'), 'full');
    });

    test('case insensitive', () {
      expect(UsbDriveService.inferSideFromLabel('feds-red'), 'red');
      expect(UsbDriveService.inferSideFromLabel('Feds-Blue'), 'blue');
      expect(UsbDriveService.inferSideFromLabel('FEDS-full'), 'full');
    });

    test('underscore separator', () {
      expect(UsbDriveService.inferSideFromLabel('FEDS_RED'), 'red');
      expect(UsbDriveService.inferSideFromLabel('feds_blue'), 'blue');
    });

    test('dot separator', () {
      expect(UsbDriveService.inferSideFromLabel('FEDS.RED'), 'red');
      expect(UsbDriveService.inferSideFromLabel('feds.full'), 'full');
    });

    test('space separator', () {
      expect(UsbDriveService.inferSideFromLabel('FEDS RED'), 'red');
      expect(UsbDriveService.inferSideFromLabel('Feds Blue'), 'blue');
    });

    test('slash separator', () {
      expect(UsbDriveService.inferSideFromLabel('FEDS/RED'), 'red');
    });

    test('backslash separator', () {
      expect(UsbDriveService.inferSideFromLabel(r'FEDS\BLUE'), 'blue');
    });

    test('no separator', () {
      expect(UsbDriveService.inferSideFromLabel('FEDSRED'), 'red');
      expect(UsbDriveService.inferSideFromLabel('fedsblue'), 'blue');
    });

    test('with leading/trailing whitespace', () {
      expect(UsbDriveService.inferSideFromLabel('  FEDS-RED  '), 'red');
    });

    test('unrecognized label returns null', () {
      expect(UsbDriveService.inferSideFromLabel('MY DRIVE'), null);
      expect(UsbDriveService.inferSideFromLabel('USB STICK'), null);
      expect(UsbDriveService.inferSideFromLabel('FEDS'), null);
      expect(UsbDriveService.inferSideFromLabel('RED'), null);
    });

    test('empty string returns null', () {
      expect(UsbDriveService.inferSideFromLabel(''), null);
    });

    test('label with extra text after match still works', () {
      expect(UsbDriveService.inferSideFromLabel('FEDS-RED-2026'), 'red');
    });

    test('label with extra text before FEDS still works', () {
      expect(UsbDriveService.inferSideFromLabel('Team201 FEDS-BLUE'), 'blue');
    });
  });

  group('UsbDriveService.getConnectedDrives', () {
    late UsbDriveService service;

    setUp(() {
      service = UsbDriveService();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.feds201.match_record/native'),
        null,
      );
    });

    void mockChannel(dynamic Function(MethodCall) handler) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.feds201.match_record/native'),
        (call) async => handler(call),
      );
    }

    test('returns empty list when no drives connected', () async {
      mockChannel((_) => <dynamic>[]);

      final drives = await service.getConnectedDrives();
      expect(drives, isEmpty);
    });

    test('parses single drive', () async {
      mockChannel((_) => <dynamic>[
            <String, String>{'path': '/storage/1A2B-3C4D', 'label': 'FEDS-RED'},
          ]);

      final drives = await service.getConnectedDrives();
      expect(drives.length, 1);
      expect(drives[0].path, '/storage/1A2B-3C4D');
      expect(drives[0].label, 'FEDS-RED');
    });

    test('parses multiple drives', () async {
      mockChannel((_) => <dynamic>[
            <String, String>{'path': '/storage/1A2B-3C4D', 'label': 'FEDS-RED'},
            <String, String>{'path': '/storage/5E6F-7A8B', 'label': 'FEDS-BLUE'},
          ]);

      final drives = await service.getConnectedDrives();
      expect(drives.length, 2);
      expect(drives[0].label, 'FEDS-RED');
      expect(drives[1].label, 'FEDS-BLUE');
    });

    test('returns empty list when channel returns null', () async {
      mockChannel((_) => null);

      final drives = await service.getConnectedDrives();
      expect(drives, isEmpty);
    });

    test('skips malformed entries', () async {
      mockChannel((_) => <dynamic>[
            <String, String>{'path': '/storage/1A2B-3C4D', 'label': 'FEDS-RED'},
            <String, dynamic>{'path': '/storage/BAD', 'label': 42},
            'not a map',
            <String, String>{'path': '/storage/5E6F-7A8B', 'label': 'FEDS-BLUE'},
          ]);

      final drives = await service.getConnectedDrives();
      expect(drives.length, 2);
      expect(drives[0].label, 'FEDS-RED');
      expect(drives[1].label, 'FEDS-BLUE');
    });

    test('handles PlatformException gracefully', () async {
      mockChannel((_) => throw PlatformException(code: 'ERROR'));

      final drives = await service.getConnectedDrives();
      expect(drives, isEmpty);
    });
  });
}
