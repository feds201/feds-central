import 'dart:convert';
import 'package:http/http.dart' as http;

/// Queries Neon via the Neon serverless HTTP API.
/// Docs: https://neon.tech/docs/serverless/serverless-driver#fetch-function
///
/// POST https://<host>/sql
/// Headers:
///   Content-Type: application/json
///   Neon-Connection-String: postgresql://user:pass@host/db
/// Body: { "query": "SELECT ...", "params": [] }
class NeonService {
  NeonService(this.connectionString);
  final String connectionString;

  // ── Public API ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> query(String sql,
      [List<dynamic> params = const []]) async {
    final host = _extractHost(connectionString);
    if (host == null) {
      throw NeonException('Could not parse host from connection string');
    }

    print('[Neon] POST https://$host/sql — $sql');

    final response = await http
        .post(
      Uri.parse('https://$host/sql'),
      headers: {
        'Content-Type': 'application/json',
        'Neon-Connection-String': connectionString.trim(),
      },
      body: jsonEncode({'query': sql, 'params': params}),
    )
        .timeout(const Duration(seconds: 20));

    print('[Neon] Status: ${response.statusCode}');

    if (response.statusCode != 200) {
      print('[Neon] Error body: ${response.body}');
      throw NeonException('HTTP ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (decoded.containsKey('error')) {
      throw NeonException(decoded['error'].toString());
    }

    // Neon HTTP API returns { fields: [{name, dataTypeID}], rows: [...] }
    final rawFields = decoded['fields'] as List<dynamic>? ?? [];
    final fields = rawFields
        .map((f) => f is Map ? (f['name'] ?? f.toString()) : f.toString())
        .toList();

    final rows = decoded['rows'] as List<dynamic>? ?? [];

    if (fields.isEmpty) return [];

    return rows.map<Map<String, dynamic>>((row) {
      final map = <String, dynamic>{};
      if (row is Map) {
        // Neon HTTP returns rows as objects keyed by column name
        for (final col in fields) {
          map[col.toString()] = row[col];
        }
      } else if (row is List) {
        for (int i = 0; i < fields.length && i < row.length; i++) {
          map[fields[i].toString()] = row[i];
        }
      }
      return map;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> fetchAll(String table) async {
    return query('SELECT * FROM "$table"');
  }

  Future<List<String>> columns(String table) async {
    final rows = await query(
      "SELECT column_name FROM information_schema.columns "
          "WHERE table_name = '$table' ORDER BY ordinal_position",
    );
    return rows.map((r) => r['column_name'].toString()).toList();
  }

  // ── Host extraction ─────────────────────────────────────────────────

  String? _extractHost(String connStr) {
    try {
      connStr = connStr.trim();
      // Remove scheme
      var rest = connStr;
      if (rest.startsWith('postgresql://')) rest = rest.substring(13);
      else if (rest.startsWith('postgres://')) rest = rest.substring(11);

      // Strip query params
      final qi = rest.indexOf('?');
      if (qi != -1) rest = rest.substring(0, qi);

      // Find @ to split credentials from host
      final ai = rest.lastIndexOf('@');
      if (ai == -1) return null;
      final hostAndDb = rest.substring(ai + 1);

      // Strip database path
      final si = hostAndDb.indexOf('/');
      final host = si != -1 ? hostAndDb.substring(0, si) : hostAndDb;

      print('[Neon] Host: $host');
      return host.isEmpty ? null : host;
    } catch (e) {
      print('[Neon] _extractHost failed: $e');
      return null;
    }
  }
}

class NeonException implements Exception {
  final String message;
  NeonException(this.message);
  @override
  String toString() => 'NeonException: $message';
}