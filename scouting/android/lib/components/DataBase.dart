import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'compactifier.dart';

class LocalDataBase {
  static final Map<String, dynamic> _storage = {};

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
    var api = getData('Settings.apiKey');
    // print('Clearing all data');
    _storage.clear();
    putData('Settings.apiKey', api);
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
  static final List<String> _logs = [];
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
  AlgaeScoringProcessor,
  AlgaeScoringBarge,
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

class PitRecord {
  final int teamNumber;
  final String scouterName;
  final String eventKey;
  final String keyStrengths;
  final String keyWeaknesses;
  final String defensiveStratigiy;
  final String defensePlan;

  PitRecord(
      {required this.teamNumber,
      required this.scouterName,
      required this.eventKey,
      required this.keyStrengths,
      required this.keyWeaknesses,
      required this.defensiveStratigiy,
      required this.defensePlan});

  Map<String, dynamic> toJson() {
    return {
      "teamNumber": teamNumber,
      "scouterName": scouterName,
      "eventKey": eventKey,
      "keyStrengths": keyStrengths,
      "keyWeaknesses": keyWeaknesses,
      "defensiveStratigiy": defensiveStratigiy,
      "defensePlan": defensePlan
    };
  }
}

class Settings {
  static void setApiKey(String key) {
    LocalDataBase.putData('Settings.apiKey', key);
  }

  static String getApiKey() {
    return LocalDataBase.getData('Settings.apiKey');
  }
}

class PitDataBase {
  static final Map<String, dynamic> _storage = {};

  static void PutData(dynamic key, PitRecord value) {
    if (key == null) {
      throw Exception('Key cannot be null');
    }

    // print(' Storing $key as $value');
    _storage[key.toString()] = value.toJson();
  }

  static dynamic GetData(dynamic key) {
    // print('Retrieving $key as ${_storage[key.toString()]}');
    return jsonDecode(jsonEncode(_storage[key.toString()]));
  }

  static void DeleteData(String key) {
    // print('Deleting $key');
    _storage.remove(key);
  }

  static void ClearData() {
    // print('Clearing all data');
    Hive.box('pitData').put('data', null);
    _storage.clear();
  }

  static void SaveAll() {
    Hive.box('pitData').put('data', jsonEncode(_storage));
  }

  static void LoadAll() {
    var dd = Hive.box('pitData').get('data');
    if (dd != null) {
      _storage.addAll(json.decode(dd));
    }
  }

  static void PrintAll() {
    print(_storage);
  }

  static List<int> GetRecorderTeam() {
    List<int> teams = [];
    _storage.forEach((key, value) {
      teams.add(value['teamNumber']);
    });
    return teams;
  }

  static dynamic Export() {
    return _storage;
  }
}
