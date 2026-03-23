import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'app.dart';
import 'data/data_store.dart';
import 'data/json_persistence.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  final persistence = JsonPersistence();
  final dataStore = DataStore(persistence);
  await dataStore.init();

  runApp(MatchRecordApp(dataStore: dataStore));
}
