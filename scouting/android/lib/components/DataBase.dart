import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'compactifier.dart';

class LocalDataBase {
  static Map<String, dynamic> _storage = {};

  static void putData(dynamic key, dynamic value) {
    if (key == null) {
      throw Exception('Key cannot be null');
    }

    // print(' Storing $key as $value');
    _storage[key.toString()] = value;
  }

  static dynamic getData(dynamic key) {
    // print('Retrieving $key as ${_storage[key.toString()]}');
    return _storage[key.toString()];
  }

  static void deleteData(String key) {
    // print('Deleting $key');
    _storage.remove(key);
  }

  static void clearData() {
    // print('Clearing all data');
    _storage.clear();
  }

  static void incrementCounter(String key, int incrementBy) {
    if (_storage.containsKey(key)) {
      _storage[key] += incrementBy;
    } else {
      _storage[key] = incrementBy;
    }
  }

  static void decrementCounter(String key, int decrementBy) {
    if (_storage.containsKey(key)) {
      _storage[key] -= decrementBy;
    } else {
      _storage[key] = -decrementBy;
    }
  }

  static Map<String, dynamic> getMatchData() {
    Map<String, dynamic> dataMap = {};
    _storage.forEach((key, value) {
      if (value is Offset) {
        dataMap[key] = {'dx': value.dx.floor(), 'dy': value.dy.floor()};
      } else {
        dataMap[key] = value;
      }
    });
    // Avoid Types.eventFile
    dataMap.remove('Types.eventFile');
    dataMap.remove('Types.matchFile');
    return jsonDecode(correctJsonFormat(dataMap.toString()));
  }

  static void clearMatchData() {
    _storage.remove('Types.eventFile');
    _storage.remove('Types.matchFile');
  }

  static void setPitMatchKey(String key) {
    _storage['PitData.EventKey'] = key;
  }

  static getPitMatchKey() {
    return _storage['PitData.EventKey'];
  }

  static List<String> getPitScoutedTeam() {
    if (_storage['PitData.ScoutedTeam'] == null) {
      _storage['PitData.ScoutedTeam'] = [];
    }
    return List<String>.from(_storage['PitData.ScoutedTeam']);
  }

  static void setPitScoutedTeam(String team) {
    if (_storage['PitData.ScoutedTeam'] == null) {
      _storage['PitData.ScoutedTeam'] = [];
    }
    List<String> scoutedTeams =
        List<String>.from(_storage['PitData.ScoutedTeam']);
    scoutedTeams.add(team);
    _storage['PitData.ScoutedTeam'] = scoutedTeams;
  }

}

class MatchLogs {
  static List<String> _logs = [];
  static void addLog(String log) {
    // print(_logs);
    _logs.add(log);
  }

  static List<String> getLogs() {
    // print(_logs);
    return _logs;
  }

  static void clearLogs() {
    _logs.clear();
    print('Logs Cleared');
  }
}

enum AutoType {
  CoralScoringLevel1,
  CoralScoringLevel2,
  CoralScoringLevel3,
  CoralScoringLevel4,
  LeftBarge,
}

enum EndgameType {
  Deep_Climb,
  Shallow_Climb,
  Park,
  Comments,
}

enum TeleType {
  CoralScoringLevel1,
  CoralScoringLevel2,
  CoralScoringLevel3,
  CoralScoringLevel4,
  AlgaeScoringBarge,
  AlgaeScoringProcessor,
}

enum PitData {
  EventKey,
  ScoutedTeam,
}

class Settings {
  static void setApiKey(String key) {
    LocalDataBase.putData('Settings.apiKey', key);
  }

  static String getApiKey() {
    return LocalDataBase.getData('Settings.apiKey');
  }
}