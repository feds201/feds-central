import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/import/video_metadata_service.dart';

void main() {
  group('kAndroidFinalizationOffset', () {
    test('is 700 milliseconds', () {
      expect(kAndroidFinalizationOffset, const Duration(milliseconds: 700));
    });
  });

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
        // Expected: 14:30:25 local → 19:30:25 UTC
        final creationTime = DateTime.utc(2026, 3, 15, 19, 31, 25, 700);
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
      // creation_time = 19:31:25.700 UTC (end time)
      // duration = 60s, finalization = 0.7s
      // approx start = 19:31:25.700 - 60s - 0.7s = 19:30:25.000 UTC
      // filename says 14:30:25 local → offset = local - UTC = -5h
      // result = 14:30:25 - (-5h) = 19:30:25 UTC
      final endTime = DateTime.utc(2026, 3, 15, 19, 31, 25, 700);
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

    test('Android fallback subtracts duration and finalization offset', () {
      final endTime = DateTime.utc(2026, 3, 15, 14, 31, 25);
      final meta = VideoMetadata(
        sourceUri: 'test://file',
        originalFilename: 'random_video.mp4',
        date: endTime,
        durationMs: 60000,
        ftypBrand: 'isom',
      );
      // Should be: endTime - 60s - 0.7s
      expect(
        meta.recordingStartTime,
        DateTime.utc(2026, 3, 15, 14, 30, 24, 300),
      );
    });

    test('Android fallback without duration returns date as-is', () {
      final endTime = DateTime.utc(2026, 3, 15, 14, 31, 25);
      final meta = VideoMetadata(
        sourceUri: 'test://file',
        originalFilename: 'random_video.mp4',
        date: endTime,
        ftypBrand: 'isom',
      );
      expect(meta.recordingStartTime, endTime);
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
}
