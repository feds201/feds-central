class LocalDataBase {
  static Map<String, dynamic> _storage = {};

  // static void putData(dynamic key, dynamic value) {
  //   if (key == null) {
  //     throw Exception('Key cannot be null');
  //   }
  //   if (key == AutoType.Comments) {
  //     print(' Storing $key as $value');
  //     // Make a array of comments
  //     if (_storage.containsKey(key.toString())) {
  //       _storage[key.toString()].add(value);
  //     } else {
  //       _storage[key.toString()] = [value];
  //     }
  //   }
  //   print(' Storing $key as $value');
  //   _storage[key.toString()] = value;
  // }

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
}


enum AutoType { AmpPlacement, Speaker, StartPosition, AutonRating, Comments }

