import '../util/result.dart';

/// A file on the drive, with metadata from the listing.
class DriveFile {
  final String uri;
  final String name;
  final int sizeBytes;
  final DateTime? lastModified;

  const DriveFile({
    required this.uri,
    required this.name,
    required this.sizeBytes,
    this.lastModified,
  });
}

/// Abstraction over USB drive access. Hides SAF details.
abstract class DriveAccess {
  /// Prompt user to pick a drive folder. Returns the drive URI
  /// (persisted permission) or null if cancelled.
  Future<String?> pickDrive();

  /// Check if a previously-persisted drive URI still has permission.
  Future<bool> hasPermission(String driveUri);

  /// List all files in the drive root (non-recursive). Filters to video
  /// files by extension (.mp4, .mov, .avi, .mkv, .3gp).
  Future<Result<List<DriveFile>>> listVideoFiles(String driveUri);

  /// Read a small file from the drive root by name. Used for config.json.
  /// Returns null if the file doesn't exist.
  Future<Result<String?>> readTextFile(String driveUri, String filename);

  /// Get the drive's display name / volume label.
  Future<Result<String>> getDriveLabel(String driveUri);

  /// Copy a drive file to a local path. Reports progress via callback.
  Future<Result<void>> copyToLocal(
    String sourceUri,
    String destPath,
    void Function(int bytesCopied)? onProgress,
  );

  /// Delete a file from the drive.
  Future<Result<void>> deleteFile(String fileUri);
}
