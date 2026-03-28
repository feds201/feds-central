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
        team TEXT NOT NULL,
        matchKey TEXT NOT NULL,
        matchNumber INTEGER,
        scouterName TEXT,
        allianceColor TEXT,
        eventKey TEXT,
        station INTEGER,
        batteryPercentage INTEGER,

        -- Auton fields
        auton_total_shooting_time DOUBLE PRECISION,
        auton_amount_of_shooting INTEGER,
        auton_climb BOOLEAN,
        auton_passing INTEGER,

        -- TeleOp fields
        teleop_total_shooting_time DOUBLE PRECISION,
        teleop_total_amount INTEGER,
        teleop_defense BOOLEAN,
        teleop_neutral_trips INTEGER,
        teleop_push_balls INTEGER,
        teleop_passing INTEGER,

        -- Endgame fields
        end_climb_status INTEGER,
        end_park BOOLEAN,
        end_push_balls INTEGER,
        end_passing INTEGER,
        end_robot_broken BOOLEAN,
        end_neutral_trips INTEGER,
        end_shooting_accuracy INTEGER,
        end_endgame_time DOUBLE PRECISION,
        end_shooting_cycles INTEGER,
        end_comments TEXT,

        id TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        raw_csv TEXT,
        PRIMARY KEY (team, matchKey)
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
      'team',
      'matchKey',
      'matchNumber',
      'scouterName',
      'allianceColor',
      'eventKey',
      'station',
      'batteryPercentage',
      'auton_total_shooting_time',
      'auton_amount_of_shooting',
      'auton_climb',
      'auton_passing',
      'teleop_total_shooting_time',
      'teleop_total_amount',
      'teleop_defense',
      'teleop_neutral_trips',
      'teleop_push_balls',
      'teleop_passing',
      'end_climb_status',
      'end_park',
      'end_push_balls',
      'end_passing',
      'end_robot_broken',
      'end_neutral_trips',
      'end_shooting_accuracy',
      'end_endgame_time',
      'end_shooting_cycles',
      'end_comments',
      'id',
      'raw_csv',
    ];

    for (final record in csvRecords) {
      try {
        // TODO: Properly handle commas in free-text fields (e.g. quoted CSV parsing) instead of replacing them
        final commentIndex = columns.indexOf('end_comments'); // 27
        final parts = record.split(',');
        // If extra commas exist (from end_comments), rejoin the comment portion with semicolons
        if (commentIndex >= 0 && parts.length > columns.length - 1) {
          final extraCount = parts.length - (columns.length - 1); // how many extra commas
          final commentParts = parts.sublist(commentIndex, commentIndex + extraCount + 1);
          parts.replaceRange(commentIndex, commentIndex + extraCount + 1, [commentParts.join(';')]);
        }
        final cols = parts;

        // Build values list according to columns (except raw_csv which is full record)
        final values = <String>[];
        for (int i = 0; i < columns.length - 1; i++) {
          if (i < cols.length) {
            var val = cols[i].trim();
            values.add(val);
          } else {
            values.add('');
          }
        }

        // Append raw CSV as last param
        values.add(record);

        // Build placeholders dynamically
        final placeholders =
        List.generate(values.length, (i) => '\$${i + 1}').join(', ');

        final sql = '''INSERT INTO $table (${columns.join(', ')})
          VALUES ($placeholders)
          ON CONFLICT (team, matchKey) DO UPDATE SET
            raw_csv = EXCLUDED.raw_csv,
            matchNumber = EXCLUDED.matchNumber,
            scouterName = EXCLUDED.scouterName,
            allianceColor = EXCLUDED.allianceColor,
            eventKey = EXCLUDED.eventKey,
            station = EXCLUDED.station,
            batteryPercentage = EXCLUDED.batteryPercentage,
            auton_total_shooting_time = EXCLUDED.auton_total_shooting_time,
            auton_amount_of_shooting = EXCLUDED.auton_amount_of_shooting,
            auton_climb = EXCLUDED.auton_climb,
            auton_passing = EXCLUDED.auton_passing,
            teleop_total_shooting_time = EXCLUDED.teleop_total_shooting_time,
            teleop_total_amount = EXCLUDED.teleop_total_amount,
            teleop_defense = EXCLUDED.teleop_defense,
            teleop_neutral_trips = EXCLUDED.teleop_neutral_trips,
            teleop_push_balls = EXCLUDED.teleop_push_balls,
            teleop_passing = EXCLUDED.teleop_passing,
            end_climb_status = EXCLUDED.end_climb_status,
            end_park = EXCLUDED.end_park,
            end_push_balls = EXCLUDED.end_push_balls,
            end_passing = EXCLUDED.end_passing,
            end_robot_broken = EXCLUDED.end_robot_broken,
            end_neutral_trips = EXCLUDED.end_neutral_trips,
            end_shooting_accuracy = EXCLUDED.end_shooting_accuracy,
            end_endgame_time = EXCLUDED.end_endgame_time,
            end_shooting_cycles = EXCLUDED.end_shooting_cycles,
            end_comments = EXCLUDED.end_comments,
            id = EXCLUDED.id,
            created_at = NOW()''';

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
          'SELECT * FROM $table ORDER BY created_at DESC LIMIT 100');
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
