import 'drive_access.dart';

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
  });

  /// iOS detection: ftyp brand is primary signal, file extension is fallback.
  bool get isIOSRecording {
    if (ftypBrand != null && ftypBrand!.trim() == 'qt') return true;
    return originalFilename.toLowerCase().endsWith('.mov');
  }

  /// Platform-aware recording start time.
  /// iOS creation_time = start of recording.
  /// Android creation_time = end of recording (subtract duration for start).
  DateTime? get recordingStartTime {
    if (date == null) return null;
    if (isIOSRecording) return date;
    // Android: creation_time = END. Subtract duration for approximate start.
    if (durationMs != null && durationMs! > 0) {
      return date!.subtract(Duration(milliseconds: durationMs!));
    }
    return date;
  }
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

  /// Extract or generate a realistic recording date.
  DateTime? _extractDate(DriveFile file, bool isIOS, int durationMs) {
    if (!isIOS) {
      // Try to parse Android Pixel filename format: PXL_YYYYMMDD_HHmmssSSS.mp4
      final androidMatch = RegExp(
        r'PXL_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})',
      ).firstMatch(file.name);

      if (androidMatch != null) {
        final startTime = DateTime.utc(
          int.parse(androidMatch.group(1)!),
          int.parse(androidMatch.group(2)!),
          int.parse(androidMatch.group(3)!),
          int.parse(androidMatch.group(4)!),
          int.parse(androidMatch.group(5)!),
          int.parse(androidMatch.group(6)!),
        );
        // Android creation_time = end time, so add duration to start
        return startTime.add(Duration(milliseconds: durationMs));
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
