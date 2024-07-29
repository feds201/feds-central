import '../match.dart';
import 'dart:developer' as developer;

class LocalDataBase {
  static Map<String, dynamic> _storage = {};

  static void putData(dynamic key, dynamic value) {
    if (key == null) {
      throw Exception('Key cannot be null');
    }
    if (key == AutoType.Comments) {
      print(' Storing $key as $value');
      // Make a array of comments
      if (_storage.containsKey(key.toString())) {
        _storage[key.toString()].add(value);
      } else {
        _storage[key.toString()] = [value];
      }
    } else {
      print(' Storing $key as $value');
      _storage[key.toString()] = value;
    }
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

  static String getMatchData() {
    String data = '';
    _storage.forEach((key, value) {
      if (key != Types.eventFile.toString() &&
          key != Types.matchFile.toString()) {
        data += '$key: $value\n';
      }
    });
    return String.fromCharCodes(data.runes.toList());
  }
}
class MatchLogs {
  static List<String> _logs = [];
  static void addLog(String log) {
    _logs.add(log);
    developer.log('Added log: $log');
  }

   static List<String> getLogs() {
    return _logs;
  }

  static void clearLogs() {
    _logs.clear();
  }
}

enum AutoType { AmpPlacement, Speaker, StartPosition, AutonRating, Comments }
