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

    try {
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
        // Helpful debug output for failures
        print('Neon query failed. SQL: $sql');
        print('Params: $params');
        print('Response (${response.statusCode}): ${response.body}');
        throw Exception(
            'Neon query failed (${response.statusCode}): ${response.body}');
      }
    } catch (e, st) {
      print('Neon query exception. SQL: $sql');
      print('Params: $params');
      print('Error: $e');
      print(st);
      rethrow;
    }
  }

  /// Create the scouting_data table if it doesn't exist.
  Future<void> ensureTable() async {
    final table = config.tableName;

    // Define columns matching the CSV headers used by the scanner.
    final sql = '''
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
        left_starting_pos TEXT,
        fuel_depot TEXT,
        fuel_outpost TEXT,
        fuel_neutral_zone TEXT,
        auton_shooting_time TEXT,
        auton_shots TEXT,
        auton_climb TEXT,
        auton_win_after_auton TEXT,
        bot_pos_x TEXT,
        bot_pos_y TEXT,
        bot_size_w TEXT,
        bot_size_h TEXT,
        bot_angle TEXT,
        auton_passing TEXT,
        teleop_shooting_time_1 TEXT,
        teleop_shooting_time_a1 TEXT,
        teleop_shooting_time_a2 TEXT,
        shooting_i1 TEXT,
        shooting_i2 TEXT,
        teleop_total_1 TEXT,
        teleop_total_a1 TEXT,
        teleop_total_a2 TEXT,
        teleop_total_i1 TEXT,
        teleop_total_i2 TEXT,
        trip_amount_1 TEXT,
        defense TEXT,
        defense_a1 TEXT,
        defense_a2 TEXT,
        defense_i1 TEXT,
        defense_i2 TEXT,
        neutral_trips TEXT,
        neutral_trips_a1 TEXT,
        neutral_trips_a2 TEXT,
        neutral_trips_i1 TEXT,
        neutral_trips_i2 TEXT,
        feed_to_hp_station TEXT,
        feed_to_hp_a1 TEXT,
        feed_to_hp_a2 TEXT,
        feed_to_hp_i1 TEXT,
        feed_to_hp_i2 TEXT,
        passing TEXT,
        passing_a1 TEXT,
        passing_a2 TEXT,
        passing_i1 TEXT,
        passing_i2 TEXT,
        climb_status TEXT,
        park TEXT,
        feed_to_hp TEXT,
        passing_end TEXT,
        end_neutral_trips TEXT,
        shooting_accuracy TEXT,
        endgame_time TEXT,
        endgame_shooting_cycles TEXT,
        robot_broken TEXT,
        drawing_data TEXT,
        raw_csv TEXT,
        UNIQUE(match_key, alliance, station, match_number)
      )
    ''';

    await query(sql);
  }

  /// Insert a batch of scanned CSV records into Neon.
  /// Returns how many rows were inserted.
  Future<int> insertRecords(
      List<String> csvRecords, List<String> headersList) async {
    if (csvRecords.isEmpty) return 0;

    final table = config.tableName;
    int inserted = 0;

    // Columns in the same order as ensureTable (except raw_csv which we'll append)
    final columns = [
      'battery_pct',
      'team',
      'scout',
      'match_key',
      'alliance',
      'event',
      'station',
      'match_number',
      'left_starting_pos',
      'fuel_depot',
      'fuel_outpost',
      'fuel_neutral_zone',
      'auton_shooting_time',
      'auton_shots',
      'auton_climb',
      'auton_win_after_auton',
      'bot_pos_x',
      'bot_pos_y',
      'bot_size_w',
      'bot_size_h',
      'bot_angle',
      'auton_passing',
      'teleop_shooting_time_1',
      'teleop_shooting_time_a1',
      'teleop_shooting_time_a2',
      'shooting_i1',
      'shooting_i2',
      'teleop_total_1',
      'teleop_total_a1',
      'teleop_total_a2',
      'teleop_total_i1',
      'teleop_total_i2',
      'trip_amount_1',
      'defense',
      'defense_a1',
      'defense_a2',
      'defense_i1',
      'defense_i2',
      'neutral_trips',
      'neutral_trips_a1',
      'neutral_trips_a2',
      'neutral_trips_i1',
      'neutral_trips_i2',
      'feed_to_hp_station',
      'feed_to_hp_a1',
      'feed_to_hp_a2',
      'feed_to_hp_i1',
      'feed_to_hp_i2',
      'passing',
      'passing_a1',
      'passing_a2',
      'passing_i1',
      'passing_i2',
      'climb_status',
      'park',
      'feed_to_hp',
      'passing_end',
      'end_neutral_trips',
      'shooting_accuracy',
      'endgame_time',
      'endgame_shooting_cycles',
      'robot_broken',
      'drawing_data',
      'raw_csv',
    ];

    for (final record in csvRecords) {
      try {
        final cols = record.split(',');

        // Build values list according to columns (except raw_csv which is full record)
        final values = <String>[];
        for (int i = 0; i < columns.length - 1; i++) {
          if (i < cols.length) {
            values.add(cols[i].trim());
          } else {
            values.add('');
          }
        }

        // drawing_data may include commas; if there are extra parts, join them into drawing_data
        if (cols.length > columns.length - 1) {
          final extra = cols.sublist(columns.length - 1).join(',').trim();
          // replace the drawing_data (which is second-last) with combined extra if present
          if (columns.length >= 2) {
            values[values.length - 2] = extra;
          }
        }

        // Append raw CSV as last param
        values.add(record);

        // Build placeholders dynamically
        final placeholders =
            List.generate(values.length, (i) => '\$${i + 1}').join(', ');

        final sql = '''INSERT INTO $table (${columns.join(', ')})
          VALUES ($placeholders)
          ON CONFLICT (match_key, alliance, station, match_number) DO UPDATE SET
            raw_csv = EXCLUDED.raw_csv,
            battery_pct = EXCLUDED.battery_pct,
            scanned_at = NOW()''';

        await query(sql, params: values);
        inserted++;
      } catch (e, st) {
        print('Insert failed for record: $record');
        print('Error: $e');
        print(st);
        // continue
      }
    }

    return inserted;
  }

  /// Fetch all records from the DB (for verification).
  Future<List<Map<String, dynamic>>> fetchAll() async {
    final table = config.tableName;
    try {
      final result = await query(
          'SELECT * FROM $table ORDER BY scanned_at DESC LIMIT 100');
      if (result.containsKey('rows')) {
        final rows = result['rows'] as List;
        return rows.cast<Map<String, dynamic>>();
      }
    } catch (e, st) {
      print('fetchAll failed: $e');
      print(st);
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
