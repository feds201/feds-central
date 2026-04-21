import 'dart:convert';
import 'dart:async';
import 'package:postgres/postgres.dart';
import 'package:scout_ops_android/services/DataBase.dart';

// Service to insert match scouting data into Neon Postgres.
// Mirrors NeonService (pit scouting) but targets the MatchRecord schema.

class NeonMatchService {
  // Build table name from event key
  static String _tableNameForEvent(dynamic eventKey) {
    final key = (eventKey == null) ? 'event' : eventKey.toString();
    final sanitized = key.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    return '${sanitized}_match_scouting';
  }

  // Open a Postgres connection from the stored connection string
  static Future<Connection> _openConnection(String connectionString) async {
    final uri = Uri.parse(connectionString);
    final endpoint = Endpoint(
      host: uri.host,
      database:
      uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'neondb',
      username: uri.userInfo.split(':').first,
      password:
      uri.userInfo.contains(':') ? uri.userInfo.split(':').last : '',
      port: uri.hasPort ? uri.port : 5432,
    );

    return await Connection.open(
      endpoint,
      settings: ConnectionSettings(
          sslMode: SslMode.require, typeRegistry: TypeRegistry()),
    ).timeout(const Duration(seconds: 15));
  }

  // Public insert: Direct Postgres connection using Connection String
  static Future<bool> insert(
      dynamic eventKey, Map<String, dynamic> payload) async {
    final connectionString = Settings.getNeonRestUrl();
    if (connectionString.isEmpty || !connectionString.startsWith('postgres')) {
      print(
          'NeonMatchService: A valid Postgres Connection String is not configured.');
      return false;
    }

    final table = _tableNameForEvent(eventKey);
    Connection? conn;

    try {
      print('NeonMatchService: Opening Postgres connection...');
      conn = await _openConnection(connectionString);

      final data = payload['data'] as Map<String, dynamic>;
      final teamNumber = data['teamNumber']?.toString() ?? '';
      final matchKey = data['matchKey']?.toString() ?? '';

      // Extract nested auton, teleop, endgame maps
      final auton = data['autonPoints'] as Map<String, dynamic>? ?? {};
      final teleOp = data['teleOpPoints'] as Map<String, dynamic>? ?? {};
      final end = data['endPoints'] as Map<String, dynamic>? ?? {};

      // Create table if it doesn't exist
      // Uses (team, matchKey) as composite primary key so the same team
      // can have entries for different matches.
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS "$table" (
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
          created_at TIMESTAMPTZ,
          PRIMARY KEY (team, matchKey)
        );
      ''');

      // Execute upsert logic
      print('NeonMatchService: Writing data into table $table...');
      final stmt = await conn.prepare('''
        INSERT INTO "$table" (
          team, matchKey, matchNumber, scouterName, allianceColor,
          eventKey, station, batteryPercentage,
          auton_total_shooting_time, auton_amount_of_shooting,
          auton_climb, auton_passing,
          teleop_total_shooting_time, teleop_total_amount,
          teleop_defense, teleop_neutral_trips,
          teleop_push_balls, teleop_passing,
          end_climb_status, end_park, end_push_balls,
          end_passing, end_robot_broken, end_neutral_trips,
          end_shooting_accuracy, end_endgame_time,
          end_shooting_cycles, end_comments,
          id, created_at
        ) VALUES (
          \$1,  \$2,  \$3,  \$4,  \$5,
          \$6,  \$7,  \$8,
          \$9,  \$10, \$11, \$12,
          \$13, \$14, \$15, \$16,
          \$17, \$18,
          \$19, \$20, \$21, \$22,
          \$23, \$24, \$25, \$26,
          \$27, \$28,
          \$29, \$30
        )
        ON CONFLICT (team, matchKey) DO UPDATE SET
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
          created_at = EXCLUDED.created_at;
      ''');

      await stmt.run([
        // Match info
        teamNumber,                                           // $1
        matchKey,                                             // $2
        data['matchNumber'] ?? 0,                             // $3
        data['scouterName']?.toString() ?? '',                // $4
        data['allianceColor']?.toString() ?? '',              // $5
        data['eventKey']?.toString() ?? '',                   // $6
        data['station'] ?? 0,                                 // $7
        data['batteryPercentage'] ?? 0,                       // $8

        // Auton fields
        (auton['TotalShootingTime'] ?? 0).toDouble(),         // $9
        auton['AmountOfShooting'] ?? 0,                       // $10
        auton['Climb'] ?? false,                              // $11
        auton['passing'] ?? 0,                                // $12

        // TeleOp fields
        (teleOp['TotalShootingTime1'] ?? 0).toDouble(),       // $13
        teleOp['TotalAmount1'] ?? 0,                          // $14
        teleOp['Defense'] ?? false,                            // $15
        teleOp['NeutralTrips'] ?? 0,                          // $16
        teleOp['PushBalls'] ?? 0,                             // $17
        teleOp['passing'] ?? 0,                               // $18

        // Endgame fields
        end['ClimbStatus'] ?? 0,                              // $19
        end['Park'] ?? false,                                 // $20
        end['PushBallsEnd'] ?? 0,                                 // $21
        end['Passing'] ?? 0,                                  // $22
        end['robotBroken'] ?? false,                          // $23
        end['EndNeutralTrips'] ?? 0,                          // $24
        end['ShootingAccuracy'] ?? 3,                         // $25
        (end['endgameTime'] ?? 0.0).toDouble(),               // $26
        end['endgameshootingCycles'] ?? 0,                    // $27
        end['Comments']?.toString() ?? '',                    // $28

        // Metadata
        payload['id'].toString(),                             // $29
        DateTime.parse(payload['created_at'].toString()),     // $30
      ]).timeout(const Duration(seconds: 10));

      print('NeonMatchService: Successfully inserted ${payload['id']}');
      return true;
    } catch (e) {
      print('NeonMatchService Postgres connection or insert error: $e');
      return false;
    } finally {
      if (conn != null && conn.isOpen) {
        await conn.close();
      }
    }
  }
}