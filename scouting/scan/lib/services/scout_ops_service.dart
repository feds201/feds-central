import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/scout_ops_data.dart';
import 'neon_config.dart';
import 'neon_database.dart';

class SyncResult {
  final bool success;
  final String message;
  SyncResult({required this.success, required this.message});
}

class ScoutOpsService {
  static final ScoutOpsService _instance = ScoutOpsService._internal();
  factory ScoutOpsService() => _instance;
  ScoutOpsService._internal();

  final StreamController<ScoutOpsData> _dataController =
      StreamController<ScoutOpsData>.broadcast();
  Stream<ScoutOpsData> get dataStream => _dataController.stream;

  ScoutOpsData _currentData = ScoutOpsData(
    moduleBattery: 76,
    targetBattery: 90,
    serialNumber: "#123456",
  );

  ScoutOpsData get currentData => _currentData;

  static const String csvHeaders =
      'Battery%,Team,Scout,MatchKey,Alliance,Event,Station,MatchNumber,LeftStartingPos,FuelDepot,FuelOutpost,FuelNeutralZone,AutonShootingTime,AutonShots,AutonClimb,AutonWinAfterAuton,BotPosX,BotPosY,BotSizeW,BotSizeH,BotAngle,TeleOpShootingTime1,TeleOpShootingTimeA1,TeleOpShootingTimeA2,ShootingI1,ShootingI2,TeleOpTotal1,TeleOpTotalA1,TeleOpTotalA2,TeleOpTotalI1,TeleOpTotalI2,TripAmount1,Defense,DefenseA1,DefenseA2,DefenseI1,DefenseI2,NeutralTrips,NeutralTripsA1,NeutralTripsA2,NeutralTripsI1,NeutralTripsI2,FeedToHPStation,FeedToHPA1,FeedToHPA2,FeedToHPI1,FeedToHPI2,Passing,PassingA1,PassingA2,PassingI1,PassingI2,ClimbStatus,Park,FeedToHP,PassingEnd,EndNeutralTrips,ShootingAccuracy,EndgameTime,Comments,DrawingData';

  void updateBatteryLevels(int moduleBattery, int targetBattery) {
    _currentData = _currentData.copyWith(
      moduleBattery: moduleBattery,
      targetBattery: targetBattery,
    );
    _dataController.add(_currentData);
  }

  void updateSerialNumber(String serialNumber) {
    _currentData = _currentData.copyWith(serialNumber: serialNumber);
    _dataController.add(_currentData);
  }

  void updateLastScan(String scannedCode, {Uint8List? rawBytes}) {
    String dataRow = scannedCode;
    bool decoded = false;

    // Try to decode assuming it's Base64 GZIP encoded
    try {
      // Decode Base64 (handle padding if missing)
      String b64 = scannedCode.trim();
      b64 = b64.replaceAll(' ', '+');
      while (b64.length % 4 != 0) {
        b64 += '=';
      }
      List<int> decodedBase64 = base64.decode(b64);
      // Decode GZIP
      List<int> unzipped = GZipCodec().decode(decodedBase64);
      // Decode to UTF8 string
      dataRow = utf8.decode(unzipped);
      print("Successfully parsed GZIP + Base64 data: $dataRow");
      decoded = true;
    } catch (e) {
      // If it wasn't Base64 GZIP, perhaps it was just raw bytes GZIP
      if (rawBytes != null && rawBytes.isNotEmpty) {
        try {
          List<int> unzipped = GZipCodec().decode(rawBytes);
          dataRow = utf8.decode(unzipped);
          print("Successfully parsed raw GZIP data");
          decoded = true;
        } catch (e2) {
          // Fallback to plain text
        }
      }
    }

    if (!decoded) {
      print("Using plain text or failed decode: $dataRow");
    }

    // In case the QR code contains headers or multiple lines, let's just take the last line assuming it's the data
    if (dataRow.contains('\n')) {
      var lines = dataRow.split('\n');
      dataRow = lines.lastWhere((line) => line.trim().isNotEmpty,
          orElse: () => dataRow);
    }

    List<String> columns = dataRow.split(',');

    int targetBattery = _currentData.targetBattery;
    String? matchNumber;
    String? station;
    String? alliance;

    // As per user provided headers:
    // 0: Battery%
    // 4: Alliance
    // 6: Station
    // 7: MatchNumber
    if (columns.length > 7) {
      if (int.tryParse(columns[0]) != null) {
        targetBattery = int.parse(columns[0]);
      } else {
        // sometimes it might have a % sign, e.g. "80%"
        String battStr = columns[0].replaceAll('%', '').trim();
        targetBattery = int.tryParse(battStr) ?? _currentData.targetBattery;
      }
      alliance = columns[4].trim();
      station = columns[6].trim();
      matchNumber = columns[7].trim();
    }

    // prevent duplicate scans
    List<String> newRecords = List.from(_currentData.scannedRecords);
    if (!newRecords.contains(dataRow)) {
      newRecords.add(dataRow);
    }

    _currentData = _currentData.copyWith(
      lastScannedCode: scannedCode,
      lastScanTime: DateTime.now(),
      targetBattery: targetBattery,
      currentMatchNumber: matchNumber,
      currentStation: station,
      currentAlliance: alliance,
      scannedRecords: newRecords,
    );
    _dataController.add(_currentData);
  }

  Future<SyncResult> syncToNeon() async {
    if (_currentData.scannedRecords.isEmpty) {
      return SyncResult(success: false, message: 'No records to sync');
    }

    try {
      final config = await NeonConfig.getInstance();
      if (!config.isConfigured) {
        return SyncResult(
          success: false,
          message:
              'Database not configured. Open Settings to add your Neon connection string.',
        );
      }

      final db = NeonDatabase(config);
      await db.ensureTable();

      final headers = csvHeaders.split(',');
      final count =
          await db.insertRecords(_currentData.scannedRecords, headers);

      return SyncResult(
        success: true,
        message: 'Synced $count record${count == 1 ? "" : "s"} to Neon',
      );
    } catch (e) {
      return SyncResult(success: false, message: 'Sync failed: $e');
    }
  }

  Future<void> exportData() async {
    if (_currentData.scannedRecords.isEmpty) return;

    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/scanned_data_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);

    StringBuffer sb = StringBuffer();
    sb.writeln(csvHeaders);
    for (String record in _currentData.scannedRecords) {
      sb.writeln(record);
    }

    await file.writeAsString(sb.toString());

    // Share the file
    await Share.shareXFiles(
      [XFile(path)],
      text: 'Scout Ops Scanned Data Export',
    );
  }

  void resetData() {
    _currentData = _currentData.copyWith(
      lastScannedCode: null,
      lastScanTime: null,
      currentMatchNumber: null,
      currentStation: null,
      currentAlliance: null,
      // We don't reset scannedRecords unless explicitly cleared, but the user asked to "reset". Let's assume reset clears current scan display.
      // User says "I can export the entirly with a single click", so we shouldn't wipe the DB on reset.
    );
    _dataController.add(_currentData);
  }

  void clearAllRecords() {
    _currentData = _currentData.copyWith(
      scannedRecords: [],
      lastScannedCode: null,
      lastScanTime: null,
    );
    _dataController.add(_currentData);
  }

  // Simulate battery drain for demo purposes
  void startBatterySimulation() {
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_currentData.moduleBattery > 0) {
        _currentData = _currentData.copyWith(
          moduleBattery: _currentData.moduleBattery - 1,
        );
      }
      _dataController.add(_currentData);
    });
  }

  void dispose() {
    _dataController.close();
  }
}
