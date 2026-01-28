import 'package:hive/hive.dart';

class PluginStateManager {
  static const String _boxName = 'pluginSettings';

  Future<void> _initializeBox() async {
    await Hive.openBox(_boxName);
  }

  Future<void> savePluginState(String pluginKey, bool value) async {
    await _initializeBox();
    var box = Hive.box(_boxName);
    await box.put(pluginKey, value);
  }
  Future<bool> getPluginState(String pluginKey) async {
    await _initializeBox();
    var box = Hive.box(_boxName);
    return box.get(pluginKey, defaultValue: false);
  }

  Future<void> saveAllPluginStates(Map<String, bool> states) async {
    await _initializeBox();
    var box = Hive.box(_boxName);
    for (var entry in states.entries) {
      await box.put(entry.key, entry.value);
    }
  }

  Future<Map<String, bool>> loadAllPluginStates(List<String> pluginKeys) async {
    await _initializeBox();
    var box = Hive.box(_boxName);
    Map<String, bool> states = {};
    for (var key in pluginKeys) {
      states[key] = box.get(key, defaultValue: false);
    }
    return states;
  }
}
