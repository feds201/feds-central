import 'package:flutter/services.dart';

import 'drive_access.dart';

/// Metadata extracted from a video file.
///
/// All filename-dependent inference (iOS detection, recording start time,
/// file extension) is computed once at construction in the factory constructor.
/// No downstream code should parse [originalFilename] for semantic data.
class VideoMetadata {
  final String sourceUri;
  final String originalFilename;
  final int? durationMs;
  final DateTime? date;
  final String? mimetype;
  final int? width;
  final int? height;
  final int? orientation;
  final double? framerate;
  /// ftyp major brand from the file header.
  /// "qt  " (with trailing spaces) = Apple QuickTime = iOS recording.
  /// "isom" / "mp42" = generic MP4 = Android recording.
  final String? ftypBrand;
  final int? fileSize;
  /// True if the video container has `com.apple.quicktime.creationdate` metadata.
  /// This is the definitive iOS signal — when present, creation_time = recording START.
  final bool hasAppleQuicktimeCreationDate;
  /// Samsung UTC offset tag (`com.samsung.android.utc_offset`), e.g. "+0900".
  /// Used to convert local-time filenames (VID_/YYYYMMDD_HHMMSS) to UTC.
  final String? samsungUtcOffset;

  // --- Derived fields, computed once at construction ---

  /// iOS detection: Apple QuickTime creationdate tag is the definitive signal,
  /// then ftyp brand, then file extension as fallback.
  final bool isIOSRecording;

  /// Platform-aware recording start time, computed using a priority chain:
  ///
  /// 1. iOS (has QuickTime creationdate or ftyp "qt"): creation_time IS the start.
  /// 2. Filename parsing (PXL_, VID_, YYYYMMDD_HHMMSS): extract start directly.
  /// 3. Fallback: creation_time - duration.
  ///
  /// Null when start time cannot be determined.
  final DateTime? recordingStartTime;

  /// File extension extracted from the original filename (e.g. ".mp4", ".mov").
  /// Defaults to ".mp4" if the filename has no extension.
  final String fileExtension;

  const VideoMetadata._({
    required this.sourceUri,
    required this.originalFilename,
    this.durationMs,
    this.date,
    this.mimetype,
    this.width,
    this.height,
    this.orientation,
    this.framerate,
    this.ftypBrand,
    this.fileSize,
    this.hasAppleQuicktimeCreationDate = false,
    this.samsungUtcOffset,
    required this.isIOSRecording,
    required this.recordingStartTime,
    required this.fileExtension,
  });

  /// Factory constructor — THE ONE PLACE where all filename-dependent
  /// inference happens (iOS detection, recording start time, file extension).
  factory VideoMetadata({
    required String sourceUri,
    required String originalFilename,
    int? durationMs,
    DateTime? date,
    String? mimetype,
    int? width,
    int? height,
    int? orientation,
    double? framerate,
    String? ftypBrand,
    int? fileSize,
    bool hasAppleQuicktimeCreationDate = false,
    String? samsungUtcOffset,
  }) {
    // 1. Extract file extension
    final dotIndex = originalFilename.lastIndexOf('.');
    final fileExtension = dotIndex < 0
        ? '.mp4'
        : originalFilename.substring(dotIndex).toLowerCase();

    // 2. Determine iOS vs Android
    final isIOS = hasAppleQuicktimeCreationDate ||
        (ftypBrand != null && ftypBrand.trim() == 'qt') ||
        fileExtension == '.mov';

    // 3. Compute recording start time
    DateTime? recordingStartTime;
    if (isIOS) {
      // iOS — creation_time is already the start time
      recordingStartTime = date;
    } else {
      // Try filename parsing (PXL_, VID_, YYYYMMDD_HHMMSS)
      recordingStartTime = parseRecordingStartFromFilename(
        originalFilename,
        samsungUtcOffset: samsungUtcOffset,
        creationTime: date,
        durationMs: durationMs,
      );
      // Fallback — creation_time - duration (Android creation_time = end time)
      if (recordingStartTime == null &&
          date != null && durationMs != null && durationMs > 0) {
        recordingStartTime = date.subtract(Duration(milliseconds: durationMs));
      }
    }

    return VideoMetadata._(
      sourceUri: sourceUri,
      originalFilename: originalFilename,
      durationMs: durationMs,
      date: date,
      mimetype: mimetype,
      width: width,
      height: height,
      orientation: orientation,
      framerate: framerate,
      ftypBrand: ftypBrand,
      fileSize: fileSize,
      hasAppleQuicktimeCreationDate: hasAppleQuicktimeCreationDate,
      samsungUtcOffset: samsungUtcOffset,
      isIOSRecording: isIOS,
      recordingStartTime: recordingStartTime,
      fileExtension: fileExtension,
    );
  }
}

/// Parse recording start time from a video filename.
///
/// Tries formats in order (stops at first match):
/// 1. `PXL_YYYYMMDD_HHMMSSmmm` → UTC, millisecond precision (Google Pixel)
/// 2. `VID_YYYYMMDD_HHMMSS` or `YYYYMMDD_HHMMSS` → local time, needs UTC conversion
///
/// For local-time formats, UTC conversion uses (in priority order):
/// - [samsungUtcOffset] metadata tag if available (e.g. "+0530", "-0800")
/// - Inferred offset from [creationTime] - [durationMs] if both available
/// - Falls back to returning null (caller uses fallback logic)
DateTime? parseRecordingStartFromFilename(
  String filename, {
  String? samsungUtcOffset,
  DateTime? creationTime,
  int? durationMs,
}) {
  // Format 1: Google Pixel — PXL_YYYYMMDD_HHMMSSmmm (UTC)
  final pixelMatch = RegExp(
    r'PXL_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})(\d{3})',
  ).firstMatch(filename);
  if (pixelMatch != null) {
    return DateTime.utc(
      int.parse(pixelMatch.group(1)!),
      int.parse(pixelMatch.group(2)!),
      int.parse(pixelMatch.group(3)!),
      int.parse(pixelMatch.group(4)!),
      int.parse(pixelMatch.group(5)!),
      int.parse(pixelMatch.group(6)!),
      int.parse(pixelMatch.group(7)!),
    );
  }

  // Format 2: VID_YYYYMMDD_HHMMSS or bare YYYYMMDD_HHMMSS (local time)
  final localMatch = RegExp(
    r'(?:VID_)?(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})',
  ).firstMatch(filename);
  if (localMatch != null) {
    final year = int.parse(localMatch.group(1)!);
    final month = int.parse(localMatch.group(2)!);
    final day = int.parse(localMatch.group(3)!);
    final hour = int.parse(localMatch.group(4)!);
    final minute = int.parse(localMatch.group(5)!);
    final second = int.parse(localMatch.group(6)!);

    // Try Samsung UTC offset tag first
    if (samsungUtcOffset != null) {
      final offset = _parseSamsungUtcOffset(samsungUtcOffset);
      if (offset != null) {
        return DateTime.utc(year, month, day, hour, minute, second)
            .subtract(offset);
      }
    }

    // Infer UTC offset from creation_time - duration
    if (creationTime != null && durationMs != null && durationMs > 0) {
      final approxStartUtc = creationTime.toUtc()
          .subtract(Duration(milliseconds: durationMs));
      // Treat filename values as if they were UTC to get a comparable reference
      final filenameAsUtc = DateTime.utc(year, month, day, hour, minute, second);
      // The difference = UTC offset (how far ahead local is from UTC)
      final offsetDuration = filenameAsUtc.difference(approxStartUtc);
      // Round to nearest 15 minutes (standard timezone offsets)
      final offsetMinutes =
          (offsetDuration.inMinutes / 15).round() * 15;
      return filenameAsUtc.subtract(Duration(minutes: offsetMinutes));
    }

    // Cannot determine UTC offset — return null so caller uses fallback
    return null;
  }

  return null;
}

/// Parse a Samsung UTC offset string like "+0530" or "-0800" into a Duration.
Duration? _parseSamsungUtcOffset(String offset) {
  final match = RegExp(r'^([+-])(\d{2})(\d{2})$').firstMatch(offset);
  if (match == null) return null;
  final sign = match.group(1)! == '+' ? 1 : -1;
  final hours = int.parse(match.group(2)!);
  final minutes = int.parse(match.group(3)!);
  return Duration(hours: hours * sign, minutes: minutes * sign);
}

/// Service for extracting video metadata.
/// On Android: uses platform channel with MediaMetadataRetriever + ftyp header reading.
/// Falls back to synthetic estimation when the platform channel is unavailable (e.g. tests).
class VideoMetadataService {
  static const _channel = MethodChannel('com.feds201.match_record/native');

  /// Extract metadata from a single video file. Never throws.
  Future<VideoMetadata> getMetadata(DriveFile file) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getVideoMetadata',
        {'filePath': file.uri},
      );
      if (result != null) {
        return _fromChannelResult(result, file);
      }
    } on MissingPluginException {
      // Platform channel not available (running on desktop or in tests)
    } on PlatformException {
      // Native side failed
    } catch (_) {
      // Any other error
    }
    return _generateSyntheticMetadata(file);
  }

  /// Batch extraction. Returns list in same order as input.
  Future<List<VideoMetadata>> getMetadataBatch(List<DriveFile> files) async {
    final results = <VideoMetadata>[];
    for (final file in files) {
      results.add(await getMetadata(file));
    }
    return results;
  }

  /// Parse the platform channel result into a VideoMetadata.
  VideoMetadata _fromChannelResult(Map<dynamic, dynamic> result, DriveFile file) {
    // Parse creation date from MediaMetadataRetriever's METADATA_KEY_DATE.
    // Format is typically "YYYYMMDDTHHMMSS.000Z" or similar ISO-ish format.
    DateTime? date;
    final dateStr = result['date'] as String?;
    if (dateStr != null) {
      date = parseMetadataDate(dateStr);
    }

    return VideoMetadata(
      sourceUri: file.uri,
      originalFilename: file.name,
      durationMs: (result['durationMs'] as num?)?.toInt(),
      date: date,
      mimetype: result['mimetype'] as String?,
      width: (result['width'] as num?)?.toInt(),
      height: (result['height'] as num?)?.toInt(),
      orientation: (result['orientation'] as num?)?.toInt(),
      framerate: (result['framerate'] as num?)?.toDouble(),
      ftypBrand: result['ftypBrand'] as String?,
      fileSize: (result['fileSize'] as num?)?.toInt() ?? file.sizeBytes,
    );
  }

  /// Parse the date string from MediaMetadataRetriever.
  /// Handles formats: "20260315T143025.000Z", "2026-03-15T14:30:25Z",
  /// "2026-03-15 14:30:25", "20260315T143025", etc.
  /// MediaMetadataRetriever always stores UTC, so all results are UTC.
  /// Preserves sub-second precision when available.
  static DateTime? parseMetadataDate(String dateStr) {
    // Try compact format first: "YYYYMMDDTHHMMSS" (with optional .ffffffZ).
    // MediaMetadataRetriever uses this format. Must check before DateTime.tryParse
    // because tryParse would treat "20260315T143025" as local time, not UTC.
    final compact = RegExp(
      r'(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})(?:\.(\d+))?',
    ).firstMatch(dateStr);
    if (compact != null) {
      int ms = 0;
      int us = 0;
      final fracStr = compact.group(7);
      if (fracStr != null) {
        // Pad/truncate to 6 digits for microsecond precision
        final padded = fracStr.padRight(6, '0').substring(0, 6);
        ms = int.parse(padded.substring(0, 3));
        us = int.parse(padded.substring(3, 6));
      }
      return DateTime.utc(
        int.parse(compact.group(1)!),
        int.parse(compact.group(2)!),
        int.parse(compact.group(3)!),
        int.parse(compact.group(4)!),
        int.parse(compact.group(5)!),
        int.parse(compact.group(6)!),
        ms,
        us,
      );
    }

    // Fall back to standard ISO parse for other formats
    final parsed = DateTime.tryParse(dateStr);
    if (parsed != null) return parsed.toUtc();

    return null;
  }

  /// Fallback: generate synthetic metadata from filename and file size.
  /// Used when platform channel is unavailable (desktop/tests).
  /// Passes raw/estimated data to the VideoMetadata factory, which handles
  /// all filename-dependent inference (iOS detection, start time, extension).
  VideoMetadata _generateSyntheticMetadata(DriveFile file) {
    final durationMs = _estimateDuration(file);
    final date = _syntheticDate(file, durationMs);

    return VideoMetadata(
      sourceUri: file.uri,
      originalFilename: file.name,
      durationMs: durationMs,
      date: date,
      width: 1920,
      height: 1080,
      orientation: 0,
      framerate: 30.0,
      fileSize: file.sizeBytes,
    );
  }

  /// Estimate duration from file size (~200KB/s for compressed video).
  int _estimateDuration(DriveFile file) {
    final seconds = (file.sizeBytes / (200 * 1024)).round();
    return (seconds.clamp(10, 120)) * 1000;
  }

  /// Build a synthetic creation_time for the VideoMetadata factory.
  /// For Android filenames with parseable timestamps, constructs an end-time
  /// (start + duration) so the factory's start-time logic can work backwards.
  /// For iOS (.mov) files, uses lastModified as the creation_time (= start).
  DateTime? _syntheticDate(DriveFile file, int durationMs) {
    // For non-.mov files, try to parse a start time from the filename and
    // convert to an end-time (creation_time) by adding duration.
    if (!file.name.toLowerCase().endsWith('.mov')) {
      final startTime = parseRecordingStartFromFilename(file.name);
      if (startTime != null) {
        return startTime.add(Duration(milliseconds: durationMs));
      }
    }

    return file.lastModified;
  }
}
