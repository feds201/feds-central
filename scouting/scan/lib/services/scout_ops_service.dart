import 'dart:async';
import '../models/scout_ops_data.dart';

class ScoutOpsService {
  static final ScoutOpsService _instance = ScoutOpsService._internal();
  factory ScoutOpsService() => _instance;
  ScoutOpsService._internal();

  final StreamController<ScoutOpsData> _dataController = StreamController<ScoutOpsData>.broadcast();
  Stream<ScoutOpsData> get dataStream => _dataController.stream;

  ScoutOpsData _currentData = ScoutOpsData(
    moduleBattery: 76,
    targetBattery: 90,
    serialNumber: "#123456",
  );

  ScoutOpsData get currentData => _currentData;

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

  void updateLastScan(String scannedCode) {
    _currentData = _currentData.copyWith(
      lastScannedCode: scannedCode,
      lastScanTime: DateTime.now(),
    );
    _dataController.add(_currentData);
  }

  void resetData() {
    _currentData = _currentData.copyWith(
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
      if (_currentData.targetBattery > 0) {
        _currentData = _currentData.copyWith(
          targetBattery: _currentData.targetBattery - 1,
        );
      }
      _dataController.add(_currentData);
    });
  }

  void dispose() {
    _dataController.close();
  }
}
