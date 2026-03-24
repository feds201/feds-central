import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service to connect to Neon PostgreSQL via their serverless HTTP API.
///
/// The /sql endpoint only works on the DIRECT endpoint (not pooler).
/// This service automatically strips '-pooler' from the hostname and
/// removes 'channel_binding=require' which isn't supported over HTTP.
class NeonService {
  final String connectionString;
  late final String _directHost;
  late final String _database;
  late final String _user;
  late final String _password;
  late final String _cleanedConnString;

  NeonService({required this.connectionString}) {
    _parseConnectionString();
  }

  void _parseConnectionString() {
    final uri = Uri.parse(connectionString);

    // Strip '-pooler' from host — the /sql API only works on direct endpoints
    _directHost = uri.host.replaceAll('-pooler', '');

    _database =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'neondb';

    // Dart's Uri decodes userInfo; extract user and password manually
    final userInfo = uri.userInfo;
    final colonIdx = userInfo.indexOf(':');
    if (colonIdx >= 0) {
      _user = Uri.decodeComponent(userInfo.substring(0, colonIdx));
      _password = Uri.decodeComponent(userInfo.substring(colonIdx + 1));
    } else {
      _user = Uri.decodeComponent(userInfo);
      _password = '';
    }

    // Manually rebuild the connection string so we're certain the
    // password is present and the host is the direct (non-pooler) one.
    // Remove channel_binding since it's not supported over HTTP.
    final params = Map<String, String>.from(uri.queryParameters)
      ..remove('channel_binding');

    final paramStr = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    _cleanedConnString =
        'postgresql://${Uri.encodeComponent(_user)}:${Uri.encodeComponent(_password)}'
        '@$_directHost/$_database'
        '${paramStr.isNotEmpty ? '?$paramStr' : ''}';
  }

  /// Execute a SQL query via Neon's serverless HTTP API.
  Future<NeonQueryResult> query(String sql, {List<dynamic>? params}) async {
    final url = Uri.parse('https://$_directHost/sql');

    final body = jsonEncode({
      'query': sql,
      'params': params ?? [],
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Neon-Connection-String': _cleanedConnString,
          'Neon-Raw-Text-Output': 'false',
          'Neon-Array-Mode': 'false',
        },
        body: body,
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw NeonException(
          'Authentication failed. Check your username and password.',
        );
      }

      if (response.statusCode != 200) {
        String errorMsg;
        try {
          final errorData = jsonDecode(response.body);
          errorMsg = errorData['message']?.toString() ??
              errorData['error']?.toString() ??
              response.body;
        } catch (_) {
          errorMsg = response.body;
        }
        throw NeonException(
          'Query failed (HTTP ${response.statusCode}): $errorMsg',
        );
      }

      final data = jsonDecode(response.body);
      return _parseResponse(data);
    } on http.ClientException catch (e) {
      throw NeonException(
        'Network error: ${e.message}\n\n'
        'Tips:\n'
        '• Run with --web-browser-flag "--disable-web-security" to fix CORS\n'
        '• Your Neon project may be sleeping — open console.neon.tech\n'
        '• Connecting to: $_directHost',
      );
    }
  }

  NeonQueryResult _parseResponse(dynamic data) {
    if (data is Map) {
      final fields = (data['fields'] as List?)
              ?.map((f) => f['name']?.toString() ?? '')
              .toList() ??
          [];
      final rows = (data['rows'] as List?)?.map((row) {
            if (row is Map) {
              return Map<String, dynamic>.from(row);
            } else if (row is List) {
              final map = <String, dynamic>{};
              for (var i = 0; i < fields.length && i < row.length; i++) {
                map[fields[i]] = row[i];
              }
              return map;
            }
            return <String, dynamic>{};
          }).toList() ??
          [];

      return NeonQueryResult(columns: fields, rows: rows);
    }

    return NeonQueryResult(columns: [], rows: []);
  }

  /// Fetches all tables in the public schema.
  Future<List<String>> listTables() async {
    final result = await query(
      "SELECT table_name FROM information_schema.tables "
      "WHERE table_schema = 'public' ORDER BY table_name",
    );
    return result.rows.map((r) => r['table_name']?.toString() ?? '').toList();
  }

  /// Fetches all rows from a given table (with optional limit).
  Future<NeonQueryResult> fetchTable(String tableName,
      {int limit = 500}) async {
    final safe = tableName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    return query('SELECT * FROM "$safe" LIMIT $limit');
  }

  /// Fetches column info for a table.
  Future<List<ColumnInfo>> describeTable(String tableName) async {
    final safe = tableName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    final result = await query(
      "SELECT column_name, data_type, is_nullable "
      "FROM information_schema.columns "
      "WHERE table_schema = 'public' AND table_name = '$safe' "
      "ORDER BY ordinal_position",
    );
    return result.rows
        .map((r) => ColumnInfo(
              name: r['column_name']?.toString() ?? '',
              dataType: r['data_type']?.toString() ?? '',
              isNullable: r['is_nullable']?.toString() == 'YES',
            ))
        .toList();
  }
}

class NeonQueryResult {
  final List<String> columns;
  final List<Map<String, dynamic>> rows;

  NeonQueryResult({required this.columns, required this.rows});

  bool get isEmpty => rows.isEmpty;
  int get rowCount => rows.length;
}

class ColumnInfo {
  final String name;
  final String dataType;
  final bool isNullable;

  ColumnInfo({
    required this.name,
    required this.dataType,
    required this.isNullable,
  });
}

class NeonException implements Exception {
  final String message;
  NeonException(this.message);

  @override
  String toString() => 'NeonException: $message';
}
