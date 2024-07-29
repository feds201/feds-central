import 'package:flutter_test/flutter_test.dart';
import 'package:scouting_app/pages/components/DataBase.dart';
import 'dart:developer' as developer;
void main() {
  List<String> logs = [];
  logs = MatchLogs.getLogs();
  developer.log(logs.toString());
}