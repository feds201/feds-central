import 'dart:convert';
import 'package:postgres/postgres.dart';

/// Queries a Neon PostgreSQL database using a native Dart Postgres client.
class NeonService {
  NeonService(this.connectionString);
  final String connectionString;

  // ── Public API ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> query(String sql,
      [List<dynamic> params = const []]) async {
    final parsed = _parseConnectionString(connectionString);
    if (parsed == null) {
      throw NeonException(
          'Could not parse connection string. Expected format:\n'
              'postgresql://user:password@host/database');
    }

    print('[Neon] Connecting to ${parsed.host} as ${parsed.user}');

    final conn = await Connection.open(
      Endpoint(
        host: parsed.host,
        port: parsed.port,
        database: parsed.database,
        username: parsed.user,
        password: parsed.password,
      ),
      settings: const ConnectionSettings(
        sslMode: SslMode.require,
      ),
    );

    try {
      final result = await conn.execute(
        Sql.named(sql),
        parameters: params.isEmpty
            ? {}
            : {for (var i = 0; i < params.length; i++) '${i + 1}': params[i]},
      );

      return result.map((row) => row.toColumnMap()).toList();
    } finally {
      await conn.close();
    }
  }

  Future<List<Map<String, dynamic>>> fetchAll(String table) async {
    return query('SELECT * FROM "$table"');
  }

  Future<List<String>> columns(String table) async {
    final rows = await query(
      "SELECT column_name FROM information_schema.columns "
          "WHERE table_name = @1 ORDER BY ordinal_position",
      [table],
    );
    return rows.map((r) => r['column_name'] as String).toList();
  }

  // ── Connection string parser ────────────────────────────────────────

  _NeonConfig? _parseConnectionString(String connStr) {
    try {
      connStr = connStr.trim();

      String rest = connStr;
      if (rest.startsWith('postgresql://')) {
        rest = rest.substring('postgresql://'.length);
      } else if (rest.startsWith('postgres://')) {
        rest = rest.substring('postgres://'.length);
      }

      // Strip query params (?sslmode=require&...)
      final queryIndex = rest.indexOf('?');
      if (queryIndex != -1) {
        rest = rest.substring(0, queryIndex);
      }

      // Split credentials from host: user:password@host/database
      final atIndex = rest.lastIndexOf('@');
      if (atIndex == -1) throw Exception('No @ found');

      final credentials = rest.substring(0, atIndex);
      final hostAndDb = rest.substring(atIndex + 1);

      // Extract user and password
      final colonIndex = credentials.indexOf(':');
      final user = colonIndex != -1
          ? credentials.substring(0, colonIndex)
          : credentials;
      final password = colonIndex != -1
          ? Uri.decodeComponent(credentials.substring(colonIndex + 1))
          : '';

      // Extract host, port, database
      final slashIndex = hostAndDb.indexOf('/');
      final hostPart = slashIndex != -1
          ? hostAndDb.substring(0, slashIndex)
          : hostAndDb;
      final database = slashIndex != -1
          ? hostAndDb.substring(slashIndex + 1)
          : 'postgres';

      // Check for port
      final portColon = hostPart.lastIndexOf(':');
      final host = portColon != -1
          ? hostPart.substring(0, portColon)
          : hostPart;
      final port = portColon != -1
          ? int.tryParse(hostPart.substring(portColon + 1)) ?? 5432
          : 5432;

      print('[Neon] Parsed — host: $host, port: $port, db: $database, user: $user, pass length: ${password.length}');
      return _NeonConfig(
          host: host,
          port: port,
          database: database,
          user: user,
          password: password);
    } catch (e) {
      print('[Neon] Failed to parse connection string: $e');
      return null;
    }
  }
}

class _NeonConfig {
  final String host;
  final int port;
  final String database;
  final String user;
  final String password;
  _NeonConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.user,
    required this.password,
  });
}

class NeonException implements Exception {
  final String message;
  NeonException(this.message);
  @override
  String toString() => 'NeonException: $message';
}