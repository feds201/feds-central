import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/import/drive_access.dart';
import 'package:match_record/import/video_metadata_service.dart';

void main() {
  group('parseRecordingStartFromFilename', () {
    group('Pixel format (PXL_YYYYMMDD_HHMMSSmmm)', () {
      test('parses standard Pixel filename as UTC with milliseconds', () {
        final result = parseRecordingStartFromFilename(
          'PXL_20260315_143025123.mp4',
        );
        expect(result, DateTime.utc(2026, 3, 15, 14, 30, 25, 123));
        expect(result!.isUtc, isTrue);
      });

      test('parses Pixel filename with path prefix', () {
        final result = parseRecordingStartFromFilename(
          '/storage/PXL_20260101_000000000.mp4',
        );
        expect(result, DateTime.utc(2026, 1, 1, 0, 0, 0, 0));
      });

      test('parses Pixel filename with 999ms', () {
        final result = parseRecordingStartFromFilename(
          'PXL_20261231_235959999.mp4',
        );
        expect(result, DateTime.utc(2026, 12, 31, 23, 59, 59, 999));
      });

      test('ignores samsungUtcOffset for Pixel filenames', () {
        final result = parseRecordingStartFromFilename(
          'PXL_20260315_143025123.mp4',
          samsungUtcOffset: '+0900',
        );
        // Pixel timestamps are already UTC — offset should not be applied
        expect(result, DateTime.utc(2026, 3, 15, 14, 30, 25, 123));
      });
    });

    group('VID_ format (VID_YYYYMMDD_HHMMSS)', () {
      test('parses with Samsung UTC offset', () {
        final result = parseRecordingStartFromFilename(
          'VID_20260315_143025.mp4',
          samsungUtcOffset: '+0530',
        );
        // 14:30:25 local at +05:30 = 09:00:25 UTC
        expect(result, DateTime.utc(2026, 3, 15, 9, 0, 25));
        expect(result!.isUtc, isTrue);
      });

      test('parses with negative UTC offset', () {
        final result = parseRecordingStartFromFilename(
          'VID_20260315_143025.mp4',
          samsungUtcOffset: '-0800',
        );
        // 14:30:25 local at -08:00 = 22:30:25 UTC
        expect(result, DateTime.utc(2026, 3, 15, 22, 30, 25));
      });

      test('infers UTC offset from creation_time minus duration', () {
        // Scenario: VID recorded at 14:30:25 local (EST, UTC-5)
        // creation_time = end = 14:31:25 EST = 19:31:25 UTC
        // duration = 60000ms
        // approxStartUtc = 19:31:25 - 60s = 19:30:25 UTC
        // filename says 14:30:25 local → offset = -5h
        // result = 14:30:25 + 5h = 19:30:25 UTC
        final creationTime = DateTime.utc(2026, 3, 15, 19, 31, 25);
        final result = parseRecordingStartFromFilename(
          'VID_20260315_143025.mp4',
          creationTime: creationTime,
          durationMs: 60000,
        );
        expect(result, DateTime.utc(2026, 3, 15, 19, 30, 25));
      });

      test('returns null without offset or creation_time', () {
        final result = parseRecordingStartFromFilename(
          'VID_20260315_143025.mp4',
        );
        expect(result, isNull);
      });

      test('returns null with creation_time but no duration', () {
        final result = parseRecordingStartFromFilename(
          'VID_20260315_143025.mp4',
          creationTime: DateTime.utc(2026, 3, 15, 19, 31, 25),
        );
        expect(result, isNull);
      });

      test('Samsung offset preferred over inferred offset', () {
        final result = parseRecordingStartFromFilename(
          'VID_20260315_143025.mp4',
          samsungUtcOffset: '+0530',
          creationTime: DateTime.utc(2026, 3, 15, 19, 31, 25),
          durationMs: 60000,
        );
        // Samsung offset should win: +05:30 → 09:00:25 UTC
        expect(result, DateTime.utc(2026, 3, 15, 9, 0, 25));
      });
    });

    group('bare YYYYMMDD_HHMMSS format', () {
      test('parses with Samsung UTC offset', () {
        final result = parseRecordingStartFromFilename(
          '20260315_143025.mp4',
          samsungUtcOffset: '+0000',
        );
        expect(result, DateTime.utc(2026, 3, 15, 14, 30, 25));
      });

      test('returns null without offset info', () {
        final result = parseRecordingStartFromFilename(
          '20260315_143025.mp4',
        );
        expect(result, isNull);
      });
    });

    group('unrecognized formats', () {
      test('returns null for random filename', () {
        expect(
          parseRecordingStartFromFilename('match_video.mp4'),
          isNull,
        );
      });

      test('returns null for IMG_ prefix', () {
        expect(
          parseRecordingStartFromFilename('IMG_20260315_143025.jpg'),
          isNull,
        );
      });

      test('returns null for empty string', () {
        expect(parseRecordingStartFromFilename(''), isNull);
      });
    });

    group('Pixel format without milliseconds (PXL_YYYYMMDD_HHMMSS)', () {
      test('does not match — requires 3-digit milliseconds', () {
        // PXL without the 3-digit ms suffix should NOT match the Pixel regex
        // but SHOULD match the generic YYYYMMDD_HHMMSS pattern
        final result = parseRecordingStartFromFilename(
          'PXL_20260315_143025.mp4',
          samsungUtcOffset: '+0000',
        );
        // Falls through to local-time format since Pixel regex requires mmm
        expect(result, DateTime.utc(2026, 3, 15, 14, 30, 25));
      });
    });
  });

  group('VideoMetadata.isIOSRecording', () {
    test('true when hasAppleQuicktimeCreationDate is set', () {
      final meta = VideoMetadata(
        sourceUri: 'test://file',
        originalFilename: 'video.mp4', // NOT .mov
        ftypBrand: 'isom', // NOT qt
        hasAppleQuicktimeCreationDate: true,
      );
      expect(meta.isIOSRecording, isTrue);
    });

    test('true when ftyp brand is qt', () {
      final meta = VideoMetadata(
        sourceUri: 'test://file',
        originalFilename: 'video.mp4',
        ftypBrand: 'qt  ',
      );
      expect(meta.isIOSRecording, isTrue);
    });

    test('true when file extension is .mov', () {
      final meta = VideoMetadata(
        sourceUri: 'test://file',
        originalFilename: 'video.MOV',
      );
      expect(meta.isIOSRecording, isTrue);
    });

    test('false for standard Android mp4', () {
      final meta = VideoMetadata(
        sourceUri: 'test://file',
        originalFilename: 'video.mp4',
        ftypBrand: 'isom',
      );
      expect(meta.isIOSRecording, isFalse);
    });
  });

  group('VideoMetadata.recordingStartTime', () {
    test('iOS recording returns date as-is', () {
      final date = DateTime.utc(2026, 3, 15, 14, 30, 25);
      final meta = VideoMetadata(
        sourceUri: 'test://file',
        originalFilename: 'video.MOV',
        date: date,
        durationMs: 60000,
        ftypBrand: 'qt  ',
      );
      expect(meta.recordingStartTime, date);
    });

    test('Android Pixel filename uses parsed start time', () {
      // Pixel filename encodes UTC start time
      // creation_time (date) = end = start + duration + finalization
      final endTime = DateTime.utc(2026, 3, 15, 14, 31, 25, 823);
      final meta = VideoMetadata(
        sourceUri: 'test://file',
        originalFilename: 'PXL_20260315_143025123.mp4',
        date: endTime,
        durationMs: 60000,
        ftypBrand: 'isom',
      );
      // Should use filename-parsed start, not date - duration
      expect(
        meta.recordingStartTime,
        DateTime.utc(2026, 3, 15, 14, 30, 25, 123),
      );
    });

    test('Android VID_ with Samsung offset uses parsed start time', () {
      final endTime = DateTime.utc(2026, 3, 15, 19, 31, 25);
      final meta = VideoMetadata(
        sourceUri: 'test://file',
        originalFilename: 'VID_20260315_143025.mp4',
        date: endTime,
        durationMs: 60000,
        ftypBrand: 'isom',
        samsungUtcOffset: '-0500',
      );
      // 14:30:25 local at -05:00 = 19:30:25 UTC
      expect(
        meta.recordingStartTime,
        DateTime.utc(2026, 3, 15, 19, 30, 25),
      );
    });

    test('Android VID_ without offset infers from creation_time', () {
      // creation_time = 19:31:25 UTC (end time)
      // duration = 60s
      // approx start = 19:31:25 - 60s = 19:30:25 UTC
      // filename says 14:30:25 local → offset = local - UTC = -5h
      // result = 14:30:25 - (-5h) = 19:30:25 UTC
      final endTime = DateTime.utc(2026, 3, 15, 19, 31, 25);
      final meta = VideoMetadata(
        sourceUri: 'test://file',
        originalFilename: 'VID_20260315_143025.mp4',
        date: endTime,
        durationMs: 60000,
        ftypBrand: 'isom',
      );
      expect(
        meta.recordingStartTime,
        DateTime.utc(2026, 3, 15, 19, 30, 25),
      );
    });

    test('Android fallback subtracts duration (no finalization offset)', () {
      final endTime = DateTime.utc(2026, 3, 15, 14, 31, 25);
      final meta = VideoMetadata(
        sourceUri: 'test://file',
        originalFilename: 'random_video.mp4',
        date: endTime,
        durationMs: 60000,
        ftypBrand: 'isom',
      );
      // Should be: endTime - 60s (no finalization offset)
      expect(
        meta.recordingStartTime,
        DateTime.utc(2026, 3, 15, 14, 30, 25),
      );
    });

    test('Android without duration returns null (not end time)', () {
      final endTime = DateTime.utc(2026, 3, 15, 14, 31, 25);
      final meta = VideoMetadata(
        sourceUri: 'test://file',
        originalFilename: 'random_video.mp4',
        date: endTime,
        ftypBrand: 'isom',
      );
      // Must NOT return endTime — that's the Android END time, not start.
      // Without duration we can't compute start, so return null.
      expect(meta.recordingStartTime, isNull);
    });

    test('returns null when date is null and no filename match', () {
      final meta = VideoMetadata(
        sourceUri: 'test://file',
        originalFilename: 'random_video.mp4',
        ftypBrand: 'isom',
      );
      expect(meta.recordingStartTime, isNull);
    });

    test('iOS returns null when date is null', () {
      final meta = VideoMetadata(
        sourceUri: 'test://file',
        originalFilename: 'video.MOV',
        ftypBrand: 'qt  ',
      );
      expect(meta.recordingStartTime, isNull);
    });

    test('priority: filename wins over fallback for Android', () {
      // Even though date and duration are available, Pixel filename should win
      final endTime = DateTime.utc(2026, 3, 15, 15, 0, 0);
      final meta = VideoMetadata(
        sourceUri: 'test://file',
        originalFilename: 'PXL_20260315_143025123.mp4',
        date: endTime,
        durationMs: 60000,
        ftypBrand: 'isom',
      );
      expect(
        meta.recordingStartTime,
        DateTime.utc(2026, 3, 15, 14, 30, 25, 123),
      );
    });
  });

  group('_parseSamsungUtcOffset (via parseRecordingStartFromFilename)', () {
    test('+0000 is zero offset', () {
      final result = parseRecordingStartFromFilename(
        'VID_20260315_143025.mp4',
        samsungUtcOffset: '+0000',
      );
      expect(result, DateTime.utc(2026, 3, 15, 14, 30, 25));
    });

    test('+0530 (India) subtracts 5:30', () {
      final result = parseRecordingStartFromFilename(
        'VID_20260315_143025.mp4',
        samsungUtcOffset: '+0530',
      );
      expect(result, DateTime.utc(2026, 3, 15, 9, 0, 25));
    });

    test('-0800 (PST) adds 8:00', () {
      final result = parseRecordingStartFromFilename(
        'VID_20260315_143025.mp4',
        samsungUtcOffset: '-0800',
      );
      expect(result, DateTime.utc(2026, 3, 15, 22, 30, 25));
    });

    test('invalid format returns null (falls through)', () {
      final result = parseRecordingStartFromFilename(
        'VID_20260315_143025.mp4',
        samsungUtcOffset: 'invalid',
      );
      // Invalid offset, no creationTime → null
      expect(result, isNull);
    });

    test('+0545 (Nepal) non-standard 45min offset', () {
      final result = parseRecordingStartFromFilename(
        'VID_20260315_143025.mp4',
        samsungUtcOffset: '+0545',
      );
      // 14:30:25 - 5:45 = 08:45:25 UTC
      expect(result, DateTime.utc(2026, 3, 15, 8, 45, 25));
    });
  });

  group('VideoMetadataService._parseMetadataDate', () {
    // _parseMetadataDate is static — we test it via getMetadata with a mock channel

    test('parses ISO 8601 format', () {
      final result = VideoMetadataService.parseMetadataDate('2026-03-15T14:30:25Z');
      expect(result, DateTime.utc(2026, 3, 15, 14, 30, 25));
    });

    test('parses compact MediaMetadataRetriever format preserving milliseconds', () {
      final result = VideoMetadataService.parseMetadataDate('20260315T143025.000Z');
      expect(result, DateTime.utc(2026, 3, 15, 14, 30, 25, 0));
    });

    test('parses compact format with non-zero milliseconds', () {
      final result = VideoMetadataService.parseMetadataDate('20260315T143025.500Z');
      expect(result, DateTime.utc(2026, 3, 15, 14, 30, 25, 500));
    });

    test('parses compact format with microsecond precision', () {
      final result = VideoMetadataService.parseMetadataDate('20260315T143025.123456Z');
      expect(result, DateTime.utc(2026, 3, 15, 14, 30, 25, 123, 456));
    });

    test('parses compact format without fractional seconds', () {
      final result = VideoMetadataService.parseMetadataDate('20260315T143025');
      expect(result, DateTime.utc(2026, 3, 15, 14, 30, 25));
    });

    test('parses compact format without trailing Z', () {
      final result = VideoMetadataService.parseMetadataDate('20260315T143025.750');
      expect(result, DateTime.utc(2026, 3, 15, 14, 30, 25, 750));
    });

    test('returns null for garbage', () {
      expect(VideoMetadataService.parseMetadataDate('not a date'), isNull);
    });

    test('returns null for empty string', () {
      expect(VideoMetadataService.parseMetadataDate(''), isNull);
    });
  });

  group('VideoMetadataService.getMetadata', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    final testFile = DriveFile(
      uri: '/storage/USB/video.mp4',
      name: 'video.mp4',
      sizeBytes: 50000000,
      lastModified: DateTime.utc(2026, 3, 15),
    );

    test('uses platform channel data when available', () async {
      final binding = TestDefaultBinaryMessengerBinding.instance;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.feds201.match_record/native'),
        (call) async {
          if (call.method == 'getVideoMetadata') {
            return {
              'durationMs': 150000,
              'date': '20260315T143025.000Z',
              'mimetype': 'video/mp4',
              'width': 3840,
              'height': 2160,
              'orientation': 90,
              'framerate': 60.0,
              'ftypBrand': 'isom',
              'fileSize': 50000000,
            };
          }
          return null;
        },
      );

      try {
        final service = VideoMetadataService();
        final meta = await service.getMetadata(testFile);

        expect(meta.durationMs, 150000);
        expect(meta.date, DateTime.utc(2026, 3, 15, 14, 30, 25));
        expect(meta.width, 3840);
        expect(meta.height, 2160);
        expect(meta.orientation, 90);
        expect(meta.framerate, 60.0);
        expect(meta.ftypBrand, 'isom');
        expect(meta.fileSize, 50000000);
        expect(meta.originalFilename, 'video.mp4');
        expect(meta.sourceUri, '/storage/USB/video.mp4');
      } finally {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('com.feds201.match_record/native'),
          null,
        );
      }
    });

    test('uses platform channel data for iOS video', () async {
      final iosFile = DriveFile(
        uri: '/storage/USB/IMG_1234.MOV',
        name: 'IMG_1234.MOV',
        sizeBytes: 80000000,
      );

      final binding = TestDefaultBinaryMessengerBinding.instance;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.feds201.match_record/native'),
        (call) async {
          if (call.method == 'getVideoMetadata') {
            return {
              'durationMs': 180000,
              'date': '2026-03-15T14:30:25.000Z',
              'mimetype': 'video/quicktime',
              'width': 1920,
              'height': 1080,
              'orientation': 0,
              'framerate': 30.0,
              'ftypBrand': 'qt  ',
              'fileSize': 80000000,
            };
          }
          return null;
        },
      );

      try {
        final service = VideoMetadataService();
        final meta = await service.getMetadata(iosFile);

        expect(meta.ftypBrand, 'qt  ');
        expect(meta.isIOSRecording, isTrue);
        expect(meta.durationMs, 180000);
        // iOS: recordingStartTime = date directly (with sub-second precision)
        expect(meta.recordingStartTime, DateTime.utc(2026, 3, 15, 14, 30, 25, 0));
      } finally {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('com.feds201.match_record/native'),
          null,
        );
      }
    });

    test('falls back to synthetic when channel throws PlatformException', () async {
      final binding = TestDefaultBinaryMessengerBinding.instance;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.feds201.match_record/native'),
        (call) async {
          throw PlatformException(code: 'ERROR', message: 'native failed');
        },
      );

      try {
        final service = VideoMetadataService();
        final meta = await service.getMetadata(testFile);

        // Should get synthetic data, not crash
        expect(meta.originalFilename, 'video.mp4');
        expect(meta.sourceUri, '/storage/USB/video.mp4');
        expect(meta.durationMs, isNotNull);
        expect(meta.fileSize, 50000000);
      } finally {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('com.feds201.match_record/native'),
          null,
        );
      }
    });

    test('falls back to synthetic when channel is not available', () async {
      // Don't register any mock — simulates MissingPluginException
      final binding = TestDefaultBinaryMessengerBinding.instance;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.feds201.match_record/native'),
        null,
      );

      final service = VideoMetadataService();
      final meta = await service.getMetadata(testFile);

      // Should get synthetic data
      expect(meta.originalFilename, 'video.mp4');
      expect(meta.durationMs, isNotNull);
    });

    test('handles partial channel results gracefully', () async {
      final binding = TestDefaultBinaryMessengerBinding.instance;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.feds201.match_record/native'),
        (call) async {
          if (call.method == 'getVideoMetadata') {
            // Only duration and ftyp, everything else null
            return {
              'durationMs': 120000,
              'date': null,
              'mimetype': null,
              'width': null,
              'height': null,
              'orientation': null,
              'framerate': null,
              'ftypBrand': 'mp42',
              'fileSize': null,
            };
          }
          return null;
        },
      );

      try {
        final service = VideoMetadataService();
        final meta = await service.getMetadata(testFile);

        expect(meta.durationMs, 120000);
        expect(meta.ftypBrand, 'mp42');
        expect(meta.date, isNull);
        expect(meta.width, isNull);
        // fileSize should fall back to DriveFile.sizeBytes
        expect(meta.fileSize, 50000000);
      } finally {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('com.feds201.match_record/native'),
          null,
        );
      }
    });
  });
}
