import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'models.dart';

class JsonPersistence {
  static const String _fileName = 'app_data.json';
  static const String _tmpSuffix = '.tmp';

  final String? _directoryPath;

  JsonPersistence({String? directoryPath}) : _directoryPath = directoryPath;

  Future<String> _getFilePath() async {
    if (_directoryPath != null) {
      return '$_directoryPath/$_fileName';
    }
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_fileName';
  }

  Future<AppData> load() async {
    final filePath = await _getFilePath();
    final file = File(filePath);

    if (!await file.exists()) {
      return AppData.empty();
    }

    final jsonString = await file.readAsString();
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    var data = AppData.fromJson(json);

    data = _migrate(data);

    return data;
  }

  Future<void> save(AppData data) async {
    final filePath = await _getFilePath();
    final tmpPath = '$filePath$_tmpSuffix';

    final jsonString =
        const JsonEncoder.withIndent('  ').convert(data.toJson());

    final tmpFile = File(tmpPath);
    await tmpFile.writeAsString(jsonString);
    await tmpFile.rename(filePath);
  }

  AppData _migrate(AppData data) {
    var migrated = data;

    // Version 0 -> 1: initial migration placeholder
    // Add future migrations here as cascading if blocks:
    // if (migrated.version < 2) { ... migrated = migrated.copyWith(version: 2); }

    return migrated;
  }
}
