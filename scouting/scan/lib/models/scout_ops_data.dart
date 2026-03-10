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

  ScoutOpsData copyWith({
    int? moduleBattery,
    int? targetBattery,
    String? serialNumber,
    String? lastScannedCode,
    DateTime? lastScanTime,
    String? currentMatchNumber,
    String? currentStation,
    String? currentAlliance,
    List<String>? scannedRecords,
  }) {
    return ScoutOpsData(
      moduleBattery: moduleBattery ?? this.moduleBattery,
      targetBattery: targetBattery ?? this.targetBattery,
      serialNumber: serialNumber ?? this.serialNumber,
      lastScannedCode: lastScannedCode ?? this.lastScannedCode,
      lastScanTime: lastScanTime ?? this.lastScanTime,
      currentMatchNumber: currentMatchNumber ?? this.currentMatchNumber,
      currentStation: currentStation ?? this.currentStation,
      currentAlliance: currentAlliance ?? this.currentAlliance,
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
