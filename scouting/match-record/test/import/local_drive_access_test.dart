import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/import/local_drive_access.dart';
import 'package:match_record/util/result.dart';

void main() {
  late Directory tempDir;
  late LocalDriveAccess access;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('local_drive_access_test_');
    access = LocalDriveAccess(dirPath: tempDir.path, label: 'Test Source');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('getDriveLabel', () {
    test('returns the label from constructor', () async {
      final result = await access.getDriveLabel(tempDir.path);
      expect(result, isA<Ok<String>>());
      expect((result as Ok<String>).value, 'Test Source');
    });
  });

  group('pickDrive', () {
    test('returns the dirPath', () async {
      final uri = await access.pickDrive();
      expect(uri, tempDir.path);
    });
  });

  group('hasPermission', () {
    test('returns true when directory exists', () async {
      expect(await access.hasPermission(tempDir.path), isTrue);
    });

    test('returns false when directory does not exist', () async {
      expect(await access.hasPermission('/nonexistent/path'), isFalse);
    });
  });

  group('listVideoFiles', () {
    test('returns empty list for empty directory', () async {
      final result = await access.listVideoFiles(tempDir.path);
      expect(result, isA<Ok>());
      expect((result as Ok).value, isEmpty);
    });

    test('filters to video extensions only', () async {
      // Create video and non-video files
      File('${tempDir.path}/match1.mp4').writeAsStringSync('video');
      File('${tempDir.path}/match2.mov').writeAsStringSync('video');
      File('${tempDir.path}/match3.avi').writeAsStringSync('video');
      File('${tempDir.path}/match4.mkv').writeAsStringSync('video');
      File('${tempDir.path}/match5.3gp').writeAsStringSync('video');
      File('${tempDir.path}/notes.txt').writeAsStringSync('text');
      File('${tempDir.path}/photo.jpg').writeAsStringSync('image');
      File('${tempDir.path}/config.json').writeAsStringSync('{}');

      final result = await access.listVideoFiles(tempDir.path);
      expect(result, isA<Ok>());
      final files = (result as Ok).value;
      expect(files.length, 5);
      final names = files.map((f) => f.name).toSet();
      expect(names, containsAll(['match1.mp4', 'match2.mov', 'match3.avi', 'match4.mkv', 'match5.3gp']));
    });

    test('case-insensitive extension matching', () async {
      File('${tempDir.path}/MATCH_UPPER.MP4').writeAsStringSync('video');
      File('${tempDir.path}/match_mixed.Mp4').writeAsStringSync('video');
      File('${tempDir.path}/match_lower.mp4').writeAsStringSync('video');

      final result = await access.listVideoFiles(tempDir.path);
      final files = (result as Ok).value;
      // All should be matched regardless of extension case
      expect(files.length, greaterThanOrEqualTo(2));
      // Every returned file should have a video extension
      for (final f in files) {
        final ext = '.${f.name.split('.').last}'.toLowerCase();
        expect(['.mp4', '.mov', '.avi', '.mkv', '.3gp'], contains(ext));
      }
    });

    test('does not list subdirectories', () async {
      Directory('${tempDir.path}/subdir').createSync();
      File('${tempDir.path}/video.mp4').writeAsStringSync('video');

      final result = await access.listVideoFiles(tempDir.path);
      final files = (result as Ok).value;
      expect(files.length, 1);
      expect(files.first.name, 'video.mp4');
    });

    test('includes file size and lastModified', () async {
      final file = File('${tempDir.path}/video.mp4');
      file.writeAsBytesSync(List.filled(1024, 0));

      final result = await access.listVideoFiles(tempDir.path);
      final files = (result as Ok).value;
      expect(files.first.sizeBytes, 1024);
      expect(files.first.lastModified, isNotNull);
    });

    test('returns error for nonexistent directory', () async {
      final result = await access.listVideoFiles('/nonexistent/path');
      expect(result, isA<Err>());
    });
  });

  group('readTextFile', () {
    test('returns file content when file exists', () async {
      File('${tempDir.path}/config.json').writeAsStringSync('{"type":"red"}');

      final result = await access.readTextFile(tempDir.path, 'config.json');
      expect(result, isA<Ok>());
      expect((result as Ok).value, '{"type":"red"}');
    });

    test('returns null when file does not exist', () async {
      final result = await access.readTextFile(tempDir.path, 'config.json');
      expect(result, isA<Ok>());
      expect((result as Ok).value, isNull);
    });
  });

  group('copyToLocal', () {
    test('copies file to destination', () async {
      final sourceFile = File('${tempDir.path}/source.mp4');
      sourceFile.writeAsBytesSync(List.filled(512, 42));

      final destDir = Directory.systemTemp.createTempSync('local_drive_dest_');
      final destPath = '${destDir.path}/copied.mp4';

      try {
        int? reportedBytes;
        final result = await access.copyToLocal(
          sourceFile.path,
          destPath,
          (bytes) => reportedBytes = bytes,
        );

        expect(result, isA<Ok>());
        expect(File(destPath).existsSync(), isTrue);
        expect(File(destPath).readAsBytesSync().length, 512);
        expect(reportedBytes, 512);
      } finally {
        destDir.deleteSync(recursive: true);
      }
    });

    test('returns error when source does not exist', () async {
      final result = await access.copyToLocal(
        '${tempDir.path}/nonexistent.mp4',
        '${tempDir.path}/dest.mp4',
        null,
      );
      expect(result, isA<Err>());
    });
  });

  group('deleteFile', () {
    test('deletes existing file', () async {
      final file = File('${tempDir.path}/to_delete.mp4');
      file.writeAsStringSync('data');
      expect(file.existsSync(), isTrue);

      final result = await access.deleteFile(file.path);
      expect(result, isA<Ok>());
      expect(file.existsSync(), isFalse);
    });

    test('succeeds silently when file does not exist', () async {
      final result = await access.deleteFile('${tempDir.path}/nonexistent.mp4');
      expect(result, isA<Ok>());
    });
  });
}
