import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class NeonConfig {
  static const String _boxName = 'neon_config';
  static const String _hostKey = 'neon_host';
  static const String _databaseKey = 'neon_database';
  static const String _usernameKey = 'neon_username';
  static const String _passwordKey = 'neon_password';
  static const String _tableKey = 'neon_table';
  static const String _defaultConnectionString =
      'postgresql://data_owner:npg_qu3HCrEX8eFk@ep-weathered-base-a5ilny8n-pooler.us-east-2.aws.neon.tech/data?sslmode=require&channel_binding=require';

  static NeonConfig? _instance;
  late Box _box;

  NeonConfig._();

  static Future<NeonConfig> getInstance() async {
    if (_instance == null) {
      _instance = NeonConfig._();
      final dir = await getApplicationDocumentsDirectory();
      Hive.init(dir.path);
      _instance!._box = await Hive.openBox(_boxName);
      if (!_instance!.isConfigured) {
        _instance!.parseConnectionString(_defaultConnectionString);
      }
    }
    return _instance!;
  }

  String get host => _box.get(_hostKey, defaultValue: '') as String;
  set host(String value) => _box.put(_hostKey, value);

  String get database => _box.get(_databaseKey, defaultValue: 'data') as String;
  set database(String value) => _box.put(_databaseKey, value);

  String get username => _box.get(_usernameKey, defaultValue: '') as String;
  set username(String value) => _box.put(_usernameKey, value);

  String get password => _box.get(_passwordKey, defaultValue: '') as String;
  set password(String value) => _box.put(_passwordKey, value);

  String get tableName =>
      _box.get(_tableKey, defaultValue: 'scouting_data') as String;
  set tableName(String value) => _box.put(_tableKey, value);

  bool get isConfigured =>
      host.isNotEmpty && username.isNotEmpty && password.isNotEmpty;

  /// Builds the Neon SQL-over-HTTP endpoint URL.
  /// Neon format: https://<host>/sql
  String get sqlEndpoint => 'https://$host/sql';

  /// Builds a Basic auth header from username:password
  String get authHeader {
    final credentials = '$username:$password';
    return 'Basic ${_base64Encode(credentials)}';
  }

  String _base64Encode(String input) {
    final bytes = input.codeUnits;
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final buffer = StringBuffer();
    for (int i = 0; i < bytes.length; i += 3) {
      final b0 = bytes[i];
      final b1 = (i + 1 < bytes.length) ? bytes[i + 1] : 0;
      final b2 = (i + 2 < bytes.length) ? bytes[i + 2] : 0;
      buffer.write(chars[(b0 >> 2) & 0x3F]);
      buffer.write(chars[((b0 << 4) | (b1 >> 4)) & 0x3F]);
      if (i + 1 < bytes.length) {
        buffer.write(chars[((b1 << 2) | (b2 >> 6)) & 0x3F]);
      } else {
        buffer.write('=');
      }
      if (i + 2 < bytes.length) {
        buffer.write(chars[b2 & 0x3F]);
      } else {
        buffer.write('=');
      }
    }
    return buffer.toString();
  }

  /// Parses a full Neon connection string like:
  /// postgresql://user:pass@ep-xxx.us-east-2.aws.neon.tech/neondb?sslmode=require
  void parseConnectionString(String connString) {
    try {
      final uri =
          Uri.parse(connString.replaceFirst('postgresql://', 'https://'));
      username = uri.userInfo.split(':').first;
      if (uri.userInfo.contains(':')) {
        password = uri.userInfo.split(':').sublist(1).join(':');
      }
      host = uri.host;
      if (uri.pathSegments.isNotEmpty) {
        database = uri.pathSegments.first;
      }
    } catch (_) {
      // Invalid connection string
    }
  }
}
