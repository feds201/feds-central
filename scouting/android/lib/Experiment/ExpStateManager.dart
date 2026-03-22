import 'package:hive/hive.dart';

class ExpStateManager {
  final Map<String, bool> _fallback = {};

  bool get _hasBox => Hive.isBoxOpen('experiments');

  Future<Map<String, bool>> loadAllPluginStates(List<String> pluginKeys) async {
    Map<String, bool> states = {};
    for (var key in pluginKeys) {
      if (_hasBox) {
        states[key] = Hive.box('experiments').get(key, defaultValue: false);
      } else {
        states[key] = _fallback[key] ?? false;
      }
    }
    return states;
  }

  Future<void> saveAllPluginStates(Map<String, bool> states) async {
    for (var entry in states.entries) {
      if (_hasBox) {
        await Hive.box('experiments').put(entry.key, entry.value);
      } else {
        _fallback[entry.key] = entry.value;
      }
    }
  }
}
