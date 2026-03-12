class ScoutOpsData {
  final int moduleBattery;
  final int targetBattery;
  final String serialNumber;
  final String? lastScannedCode;
  final DateTime? lastScanTime;

  // New fields from the CSV parsing
  final String? currentMatchNumber;
  final String? currentStation;
  final String? currentAlliance;
  final List<String> scannedRecords;

  ScoutOpsData({
    required this.moduleBattery,
    required this.targetBattery,
    required this.serialNumber,
    this.lastScannedCode,
    this.lastScanTime,
    this.currentMatchNumber,
    this.currentStation,
    this.currentAlliance,
    this.scannedRecords = const [],
  });

  // Sentinel to distinguish "not passed" from "explicitly set to null"
  static const _unset = Object();

  ScoutOpsData copyWith({
    int? moduleBattery,
    int? targetBattery,
    String? serialNumber,
    Object? lastScannedCode = _unset,
    Object? lastScanTime = _unset,
    Object? currentMatchNumber = _unset,
    Object? currentStation = _unset,
    Object? currentAlliance = _unset,
    List<String>? scannedRecords,
  }) {
    return ScoutOpsData(
      moduleBattery: moduleBattery ?? this.moduleBattery,
      targetBattery: targetBattery ?? this.targetBattery,
      serialNumber: serialNumber ?? this.serialNumber,
      lastScannedCode: lastScannedCode == _unset
          ? this.lastScannedCode
          : lastScannedCode as String?,
      lastScanTime: lastScanTime == _unset
          ? this.lastScanTime
          : lastScanTime as DateTime?,
      currentMatchNumber: currentMatchNumber == _unset
          ? this.currentMatchNumber
          : currentMatchNumber as String?,
      currentStation: currentStation == _unset
          ? this.currentStation
          : currentStation as String?,
      currentAlliance: currentAlliance == _unset
          ? this.currentAlliance
          : currentAlliance as String?,
      scannedRecords: scannedRecords ?? this.scannedRecords,
    );
  }

  Set<String> get filledStationsForCurrentMatch {
    final set = <String>{};
    if (currentMatchNumber == null) return set;
    for (final record in scannedRecords) {
      final columns = record.split(',');
      if (columns.length > 7) {
        final alliance = columns[4].trim();
        final station = columns[6].trim();
        final matchNum = columns[7].trim();
        if (matchNum == currentMatchNumber) {
          set.add('$alliance $station');
        }
      }
    }
    return set;
  }
}
