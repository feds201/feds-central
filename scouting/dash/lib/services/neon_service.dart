import 'dart:convert';
import 'dart:js_interop';

/// Queries a Neon PostgreSQL database by calling the `@neondatabase/serverless`
/// JavaScript driver that's loaded in `index.html`.
///
/// This avoids CORS issues because the JS driver uses the correct fetch mode
/// natively — it was designed for browser use.
class NeonService {
  NeonService(this.connectionString);
  final String connectionString;

  // ── Public API ─────────────────────────────────────────────────────

  /// Run [sql] with optional [params] and return a list of row maps.
  Future<List<Map<String, dynamic>>> query(String sql,
      [List<dynamic> params = const []]) async {

    final paramsJson = jsonEncode(params);

    // Call the global JS function: neonQuery(connStr, sql, paramsJson)
    final promise = _neonQuery(
      connectionString.toJS,
      sql.toJS,
      paramsJson.toJS,
    );

    final JSString jsResult = await promise.toDart as JSString;
    final resultStr = jsResult.toDart;
    final decoded = jsonDecode(resultStr) as Map<String, dynamic>;

    // Check for errors from the JS side.
    if (decoded.containsKey('error')) {
      throw NeonException(decoded['error'] as String);
    }

    final fields = (decoded['fields'] as List<dynamic>?)
            ?.map((f) => f.toString())
            .toList() ??
        [];
    final rows = decoded['rows'] as List<dynamic>? ?? [];

    if (fields.isEmpty) return [];

    return rows.map<Map<String, dynamic>>((row) {
      final map = <String, dynamic>{};
      if (row is List) {
        for (int i = 0; i < fields.length && i < row.length; i++) {
          map[fields[i]] = row[i];
        }
      } else if (row is Map) {
        for (final col in fields) {
          map[col] = row[col];
        }
      }
      return map;
    }).toList();
  }

  /// Fetch every row in [table].
  Future<List<Map<String, dynamic>>> fetchAll(String table) async {
    return query('SELECT * FROM "$table"');
  }

  /// Return the column names for [table].
  Future<List<String>> columns(String table) async {
    final rows = await query(
      "SELECT column_name FROM information_schema.columns "
      "WHERE table_name = \$1 ORDER BY ordinal_position",
      [table],
    );
    return rows.map((r) => r['column_name'] as String).toList();
  }
}

// ── JS interop binding ───────────────────────────────────────────────

@JS('neonQuery')
external JSPromise _neonQuery(JSString connString, JSString sql, JSString paramsJson);

// ── Exception ────────────────────────────────────────────────────────

class NeonException implements Exception {
  final String message;
  NeonException(this.message);
  @override
  String toString() => 'NeonException: $message';
}
