class ScoutOpsData {
  final int moduleBattery;
  final int targetBattery;
  final String serialNumber;
  final String? lastScannedCode;
  final DateTime? lastScanTime;

  ScoutOpsData({
    required this.moduleBattery,
    required this.targetBattery,
    required this.serialNumber,
    this.lastScannedCode,
    this.lastScanTime,
  });

  ScoutOpsData copyWith({
    int? moduleBattery,
    int? targetBattery,
    String? serialNumber,
    String? lastScannedCode,
    DateTime? lastScanTime,
  }) {
    return ScoutOpsData(
      moduleBattery: moduleBattery ?? this.moduleBattery,
      targetBattery: targetBattery ?? this.targetBattery,
      serialNumber: serialNumber ?? this.serialNumber,
      lastScannedCode: lastScannedCode ?? this.lastScannedCode,
      lastScanTime: lastScanTime ?? this.lastScanTime,
    );
  }
}
