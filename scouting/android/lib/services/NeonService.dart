import 'dart:convert';
import 'dart:async';
import 'package:postgres/postgres.dart';
import 'package:scout_ops_android/services/DataBase.dart';

// Service to use a direct secure Postgres connection string
// This allows bypassing the locked-down Data API by treating Neon just as a DB.

class NeonService {
  // Build table name from event key
  static String _tableNameForEvent(dynamic eventKey) {
    // ensure we have a string to operate on
    final key = (eventKey == null) ? 'event' : eventKey.toString();
    // sanitize simple: replace non-alphanum with underscore
    final sanitized = key.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    return '${sanitized}_pit_scouting';
  }

  // Public insert: Direct Postgres connection using Connection String
  static Future<bool> insert(
      dynamic eventKey, Map<String, dynamic> payload) async {
    final connectionString = Settings.getNeonRestUrl();
    if (connectionString.isEmpty || !connectionString.startsWith('postgres')) {
      print(
          'NeonService: A valid Postgres Connection String is not configured.');
      return false;
    }

    final table = _tableNameForEvent(eventKey);
    Connection? conn;

    try {
      // Connect to Postgres using the Database URL format (postgresql://...)
      print('NeonService: Opening Postgres connection...');

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

      conn = await Connection.open(
        endpoint,
        settings: ConnectionSettings(
            sslMode: SslMode.require, typeRegistry: TypeRegistry()),
      ).timeout(const Duration(seconds: 15));

      final data = payload['data'] as Map<String, dynamic>;
      final team =
          data['teamNumber']?.toString() ?? payload['team_number'].toString();

      await conn.execute('''
        CREATE TABLE IF NOT EXISTS "$table" (
          team TEXT PRIMARY KEY,
          scouterName TEXT,
          eventKey TEXT,
          driveTrain TEXT,
          auton TEXT,
          scoreObject TEXT,
          scoreType JSONB,
          climbType JSONB,
          intake JSONB,
          botImage1 TEXT,
          botImage2 TEXT,
          botImage3 TEXT,
          autoRoutes JSONB,
          autoFuel INTEGER,
          gameData BOOLEAN,
          weight DOUBLE PRECISION,
          speed DOUBLE PRECISION,
          driveMotorType TEXT,
          groundClearance DOUBLE PRECISION,
          maxFuelCapacity INTEGER,
          avgCycleTime DOUBLE PRECISION,
          climbSuccessProb DOUBLE PRECISION,
          batteries INTEGER,
          framePerimeter TEXT,
          shootingRate DOUBLE PRECISION,
          id TEXT,
          created_at TIMESTAMPTZ
        );
      ''');

      // Execute upsert logic
      print('NeonService: Writing data into table $table...');
      final stmt = await conn.prepare('''
        INSERT INTO "$table" (
          team, scouterName, eventKey, driveTrain, auton, scoreObject,
          scoreType, climbType, intake, botImage1, botImage2, botImage3,
          autoRoutes, autoFuel, gameData, weight, speed, driveMotorType,
          groundClearance, maxFuelCapacity, avgCycleTime, climbSuccessProb,
          batteries, framePerimeter, shootingRate, id, created_at
        ) VALUES (
          \$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12,
          \$13, \$14, \$15, \$16, \$17, \$18, \$19, \$20, \$21, \$22,
          \$23, \$24, \$25, \$26, \$27
        )
        ON CONFLICT (team) DO UPDATE SET
          scouterName = EXCLUDED.scouterName,
          eventKey = EXCLUDED.eventKey,
          driveTrain = EXCLUDED.driveTrain,
          auton = EXCLUDED.auton,
          scoreObject = EXCLUDED.scoreObject,
          scoreType = EXCLUDED.scoreType,
          climbType = EXCLUDED.climbType,
          intake = EXCLUDED.intake,
          botImage1 = EXCLUDED.botImage1,
          botImage2 = EXCLUDED.botImage2,
          botImage3 = EXCLUDED.botImage3,
          autoRoutes = EXCLUDED.autoRoutes,
          autoFuel = EXCLUDED.autoFuel,
          gameData = EXCLUDED.gameData,
          weight = EXCLUDED.weight,
          speed = EXCLUDED.speed,
          driveMotorType = EXCLUDED.driveMotorType,
          groundClearance = EXCLUDED.groundClearance,
          maxFuelCapacity = EXCLUDED.maxFuelCapacity,
          avgCycleTime = EXCLUDED.avgCycleTime,
          climbSuccessProb = EXCLUDED.climbSuccessProb,
          batteries = EXCLUDED.batteries,
          framePerimeter = EXCLUDED.framePerimeter,
          shootingRate = EXCLUDED.shootingRate,
          id = EXCLUDED.id,
          created_at = EXCLUDED.created_at;
      ''');

      await stmt.run([
        team,
        data['scouterName']?.toString() ?? '',
        data['eventKey']?.toString() ?? '',
        data['driveTrain']?.toString() ?? '',
        data['auton']?.toString() ?? '',
        data['scoreObject']?.toString() ?? '',
        jsonEncode(data['scoreType'] ?? []),
        jsonEncode(data['climbType'] ?? []),
        jsonEncode(data['intake'] ?? []),
        data['botImage1']?.toString() ?? '',
        data['botImage2']?.toString() ?? '',
        data['botImage3']?.toString() ?? '',
        jsonEncode(data['autoRoutes'] ?? []),
        data['autoFuel'] ?? 0,
        data['gameData'] ?? false,
        data['weight']?.toDouble() ?? 0.0,
        data['speed']?.toDouble() ?? 0.0,
        data['driveMotorType']?.toString() ?? '',
        data['groundClearance']?.toDouble() ?? 0.0,
        data['maxFuelCapacity'] ?? 0,
        data['avgCycleTime']?.toDouble() ?? 0.0,
        data['climbSuccessProb']?.toDouble() ?? 0.0,
        data['batteries'] ?? 0,
        data['framePerimeter']?.toString() ?? '',
        data['shootingRate']?.toDouble() ?? 0.0,
        payload['id'].toString(),
        DateTime.parse(payload['created_at'].toString()),
      ]).timeout(const Duration(seconds: 10));

      print('NeonService: Successfully inserted ${payload['id']}');
      return true;
    } catch (e) {
      print('NeonService Postgres connection or insert error: $e');
      return false;
    } finally {
      if (conn != null && conn.isOpen) {
        await conn.close();
      }
    }
  }
}
