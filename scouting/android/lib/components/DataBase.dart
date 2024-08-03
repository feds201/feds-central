import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../Match_Pages/actions/compactifier.dart';

class LocalDataBase {
  static Map<String, dynamic> _storage = {};

  static void putData(dynamic key, dynamic value) {
    if (key == null) {
      throw Exception('Key cannot be null');
    }

    print(' Storing $key as $value');
      _storage[key.toString()] = value;
  }

  static dynamic getData(dynamic key) {
    print('Retrieving $key as ${_storage[key.toString()]}');
    return _storage[key.toString()];
  }

  static void deleteData(String key) {
    print('Deleting $key');
    _storage.remove(key);
  }

  static void clearData() {
    print('Clearing all data');
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
        dataMap[key] = {'dx': value.dx, 'dy': value.dy};
      } else {
        dataMap[key] = value;
      }
    });
    // Avoid Types.eventFile
    dataMap.remove('Types.eventFile');
    dataMap.remove('Types.matchFile');
    return jsonDecode(correctJsonFormat(dataMap.toString()));
  }
}

class MatchLogs {
  static List<String> _logs = [];
  static void addLog(String log) {
    print(_logs);
    _logs.add(log);
  }

  static List<String> getLogs() {
    print(_logs);
    return _logs;
  }

  static void clearLogs() {
    _logs.clear();
    print('Logs Cleared');
  }
}

enum AutoType {
  AmpPlacement,
  Speaker,
  Trap,
  StartPosition,
  AutonRating,
  Chip1,
  Chip2,
  Chip3
}
enum EndgameType { endLocation, climbed, harmony, attempted, spotlight }

enum TeleType {
  GroundPickUp,
  SourcePickUp,
  SpeakerNotes,
  AmpPlacement,
  TrapPlacement,
  AmplifiedSpeakerNotes,
  CoOpBonus,
  Assists
}