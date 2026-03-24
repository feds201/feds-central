import 'drive_access.dart';

/// Estimated delay between Android stopping recording and writing creation_time.
/// Tested across devices: most are under 1s, some outliers at 3s+ but rare.
const kAndroidFinalizationOffset = Duration(milliseconds: 700);

/// Metadata extracted from a video file.
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

  const VideoMetadata({
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
  });

  /// iOS detection: Apple QuickTime creationdate tag is the definitive signal,
  /// then ftyp brand, then file extension as fallback.
  bool get isIOSRecording {
    if (hasAppleQuicktimeCreationDate) return true;
    if (ftypBrand != null && ftypBrand!.trim() == 'qt') return true;
    return originalFilename.toLowerCase().endsWith('.mov');
  }

  /// Platform-aware recording start time, computed using a priority chain:
  ///
  /// 1. iOS (has QuickTime creationdate or ftyp "qt"): creation_time IS the start.
  /// 2. Filename parsing (PXL_, VID_, YYYYMMDD_HHMMSS): extract start directly.
  /// 3. Fallback: creation_time - duration - finalization offset (0.7s).
  DateTime? get recordingStartTime {
    // Priority 1: iOS — creation_time is already the start time
    if (isIOSRecording) return date;

    // Priority 2: Parse recording start from filename
    final fromFilename = parseRecordingStartFromFilename(
      originalFilename,
      samsungUtcOffset: samsungUtcOffset,
      creationTime: date,
      durationMs: durationMs,
    );
    if (fromFilename != null) return fromFilename;

    // Priority 3: Fallback — creation_time - duration - finalization offset
    if (date == null) return null;
    if (durationMs != null && durationMs! > 0) {
      return date!
          .subtract(Duration(milliseconds: durationMs!))
          .subtract(kAndroidFinalizationOffset);
    }
    return date;
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
          .subtract(Duration(milliseconds: durationMs))
          .subtract(kAndroidFinalizationOffset);
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
/// On real Android: uses platform channel with MediaMetadataRetriever.
/// Currently: generates synthetic metadata based on filenames (see TODO for platform channel).
class VideoMetadataService {
  /// Extract metadata from a single video file. Never throws.
  Future<VideoMetadata> getMetadata(DriveFile file) async {
    return _generateSyntheticMetadata(file);
  }

  /// Batch extraction. Returns list in same order as input.
  Future<List<VideoMetadata>> getMetadataBatch(List<DriveFile> files) async {
    return files.map(_generateSyntheticMetadata).toList();
  }

  /// Generate synthetic but realistic metadata until platform channel is implemented.
  /// For iOS files (.MOV): set ftypBrand to "qt  ", date = recording start time.
  /// For Android files (.mp4): set ftypBrand to "isom", date = end time.
  VideoMetadata _generateSyntheticMetadata(DriveFile file) {
    final isIOS = file.name.toLowerCase().endsWith('.mov');
    final durationMs = _estimateDuration(file);
    final date = _extractDate(file, isIOS, durationMs);

    return VideoMetadata(
      sourceUri: file.uri,
      originalFilename: file.name,
      durationMs: durationMs,
      date: date,
      mimetype: isIOS ? 'video/quicktime' : 'video/mp4',
      width: 1920,
      height: 1080,
      orientation: 0,
      framerate: 30.0,
      ftypBrand: isIOS ? 'qt  ' : 'isom',
      fileSize: file.sizeBytes,
    );
  }

  /// Estimate a realistic duration based on file size.
  /// ~2MB per 10 seconds at 1080p is a reasonable approximation.
  int _estimateDuration(DriveFile file) {
    // Roughly 200KB/s for compressed video
    final seconds = (file.sizeBytes / (200 * 1024)).round();
    // Clamp to reasonable range (10-120 seconds for sample videos)
    return (seconds.clamp(10, 120)) * 1000;
  }

  /// Extract or generate a synthetic creation_time.
  /// For Android files with Pixel filenames, simulates creation_time = end of recording
  /// by parsing the start time from the filename and adding duration + finalization offset.
  /// For iOS or unrecognized filenames, falls back to file's lastModified.
  DateTime? _extractDate(DriveFile file, bool isIOS, int durationMs) {
    if (!isIOS) {
      // Try to parse start time from filename (Pixel, Samsung, generic Android)
      final startTime = parseRecordingStartFromFilename(file.name);
      if (startTime != null) {
        // Simulate Android creation_time = end of recording
        return startTime
            .add(Duration(milliseconds: durationMs))
            .add(kAndroidFinalizationOffset);
      }
    }

    // For iOS files or files without parseable timestamps, use the file's
    // last modified time if available
    if (file.lastModified != null) {
      return file.lastModified;
    }

    return null;
  }
}
