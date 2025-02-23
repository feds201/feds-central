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
  Defense,
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

class QualitativeDataBase {
  static final Map<String, dynamic> _storage = {};

  static void PutData(dynamic key, dynamic value) {
    if (key == null) {
      throw Exception('Both keys cannot be null');
    }

    if (!_storage.containsKey(key.toString())) {
      _storage[key.toString()] = {};
    }

    _storage[key.toString()] = value;
  }

  static dynamic GetData(dynamic key) {
    return _storage[key.toString()];
  }

  static void DeleteData(String key) {
    // print('Deleting $key');
    _storage.remove(key);
  }

  static void ClearData() {
    // print('Clearing all data');
    Hive.box('qualitative').put('data', null);
    _storage.clear();
  }

  static void SaveAll() {
    Hive.box('qualitative').put('data', jsonEncode(_storage));
  }

  static void LoadAll() {
    var dd = Hive.box('qualitative').get('data');
    if (dd != null) {
      _storage.addAll(json.decode(dd));
    }
  }

  static void PrintAll() {
    print(_storage);
  }

  static List<String> GetRecorderTeam() {
    List<String> teams = [];
    _storage.forEach((key, value) {
      teams.add(value['teamNumber']);
    });
    return teams;
  }

  static dynamic Export() {
    return _storage;
  }
}

class QualitativeRecord {
  final String scouterName;
  final String matchKey;
  final String q1;
  final String q2;
  final String q3;
  final String q4;

  QualitativeRecord(
      {required this.scouterName,
      required this.matchKey,
      required this.q1,
      required this.q2,
      required this.q3,
      required this.q4});

  Map<String, dynamic> toJson() {
    return {
      "Scouter_Name": scouterName,
      "Match_Key": matchKey,
      "Q1": q1,
      "Q2": q2,
      "Q3": q3,
      "Q4": q4,
    };
  }
}

class Team {
  final int teamNumber;
  final String nickname;
  final String? city;
  final String? stateProv;
  final String? country;
  final String? website;

  Team({
    required this.teamNumber,
    required this.nickname,
    this.city,
    this.stateProv,
    this.country,
    this.website,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      teamNumber: json['team_number'],
      nickname: json['nickname'],
      city: json['city'],
      stateProv: json['state_prov'],
      country: json['country'],
      website: json['website'],
    );
  }
}
