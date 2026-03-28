import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'data/data_store.dart';
import 'data/json_persistence.dart';
import 'import/integrity_checker.dart';
import 'notifications/notification_service.dart';
import 'tba/tba_config.dart';
import 'util/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await TbaConfig.loadDotenv();

  final persistence = JsonPersistence();
  final dataStore = DataStore(persistence);
  await dataStore.init();

  // Run startup integrity check
  final docsDir = await getApplicationDocumentsDirectory();
  final recordingsDir =
      '${docsDir.path}/${AppConstants.recordingsDirName}';

  // Ensure recordings directory exists
  await Directory(recordingsDir).create(recursive: true);

  final checker = IntegrityChecker();
  final cleanedUp = await checker.reconcile(
    recordingsDir: recordingsDir,
    dataStore: dataStore,
  );

  // Initialize match notifications
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermission();

  runApp(MatchRecordApp(
    dataStore: dataStore,
    integrityCleanupCount: cleanedUp,
    notificationService: notificationService,
  ));
}
