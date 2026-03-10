import 'dart:convert';
import 'package:http/http.dart' as http;
import 'neon_config.dart';

class NeonDatabase {
  final NeonConfig config;

  NeonDatabase(this.config);

  /// Execute a SQL query against Neon's serverless HTTP API.
  /// Returns the response body as decoded JSON.
  Future<Map<String, dynamic>> query(
    String sql, {
    List<dynamic>? params,
  }) async {
    if (!config.isConfigured) {
      throw Exception(
          'Neon database is not configured. Go to Settings to add your connection string.');
    }

    final body = jsonEncode({
      'query': sql,
      if (params != null) 'params': params,
    });

    final response = await http.post(
      Uri.parse(config.sqlEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Neon-Connection-String':
            'postgresql://${config.username}:${Uri.encodeComponent(config.password)}@${config.host}/${config.database}?sslmode=require&channel_binding=require',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
          'Neon query failed (${response.statusCode}): ${response.body}');
    }
  }

  /// Create the scouting_data table if it doesn't exist.
  Future<void> ensureTable() async {
    final table = config.tableName;
    await query('''
      CREATE TABLE IF NOT EXISTS $table (
        id SERIAL PRIMARY KEY,
        scanned_at TIMESTAMPTZ DEFAULT NOW(),
        battery_pct TEXT,
        team TEXT,
        scout TEXT,
        match_key TEXT,
        alliance TEXT,
        event TEXT,
        station TEXT,
        match_number TEXT,
        raw_csv TEXT,
        UNIQUE(match_key, alliance, station, match_number)
      )
    ''');
  }

  /// Insert a batch of scanned CSV records into Neon.
  /// Returns how many rows were inserted.
  Future<int> insertRecords(
      List<String> csvRecords, List<String> headersList) async {
    if (csvRecords.isEmpty) return 0;

    final table = config.tableName;
    int inserted = 0;

    for (final record in csvRecords) {
      final cols = record.split(',');
      final battery = cols.isNotEmpty ? cols[0].trim() : '';
      final team = cols.length > 1 ? cols[1].trim() : '';
      final scout = cols.length > 2 ? cols[2].trim() : '';
      final matchKey = cols.length > 3 ? cols[3].trim() : '';
      final alliance = cols.length > 4 ? cols[4].trim() : '';
      final event = cols.length > 5 ? cols[5].trim() : '';
      final station = cols.length > 6 ? cols[6].trim() : '';
      final matchNumber = cols.length > 7 ? cols[7].trim() : '';

      try {
        await query(
          '''INSERT INTO $table (battery_pct, team, scout, match_key, alliance, event, station, match_number, raw_csv)
             VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9)
             ON CONFLICT (match_key, alliance, station, match_number) DO UPDATE SET
               raw_csv = EXCLUDED.raw_csv,
               battery_pct = EXCLUDED.battery_pct,
               scanned_at = NOW()''',
          params: [
            battery,
            team,
            scout,
            matchKey,
            alliance,
            event,
            station,
            matchNumber,
            record
          ],
        );
        inserted++;
      } catch (e) {
        // Skip individual failures, continue with rest
      }
    }
    return inserted;
  }

  /// Fetch all records from the DB (for verification).
  Future<List<Map<String, dynamic>>> fetchAll() async {
    final table = config.tableName;
    final result =
        await query('SELECT * FROM $table ORDER BY scanned_at DESC LIMIT 100');

    if (result.containsKey('rows')) {
      final rows = result['rows'] as List;
      return rows.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Test the connection by running a simple query.
  Future<bool> testConnection() async {
    try {
      await query('SELECT 1 as test');
      return true;
    } catch (_) {
      return false;
    }
  }
}
