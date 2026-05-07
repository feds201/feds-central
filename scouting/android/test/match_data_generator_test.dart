import 'package:flutter_test/flutter_test.dart';
import 'package:scout_ops_android/services/DataBase.dart';
import 'dart:math';
import 'dart:io';

void main() {
  group('Realistic Match Data Generator', () {
    test('Generate configurable realistic match data - CSV export', () async {
      // Change this number to generate different amounts of data
      const int numMatches = 100; // <-- CHANGE THIS NUMBER HERE

      final generator = RealisticMatchDataGenerator();
      final matches = generator.generateMatches(numMatches);
      final csvContent = generator.exportToCSV(matches);

      print('\n=== Generated $numMatches Realistic Matches (CSV Format) ===');
      print('First 5 rows:');
      final lines = csvContent.split('\n');
      for (int i = 0; i < 5 && i < lines.length; i++) {
        print(lines[i]);
      }
      print('... (${lines.length - 6} more rows)');

      // Save to dev directory with timestamp
      final devDir = Directory('test_output/dev_data');
      await devDir.create(recursive: true);

      final timestamp =
          DateTime.now().toString().replaceAll(':', '-').split('.')[0];
      final file = File(
          'test_output/dev_data/match_data_$numMatches matches_$timestamp.csv');
      await file.writeAsString(csvContent);

      print('\n✅ Saved to: ${file.path}');
      print('Total size: ${(csvContent.length / 1024).toStringAsFixed(2)} KB');

      expect(matches.length, numMatches);
      expect(csvContent.isNotEmpty, true);
    });

    test('Generate 50 realistic matches for dashboard testing', () async {
      final generator = RealisticMatchDataGenerator();
      final matches = generator.generateMatches(50);
      final csvContent = generator.exportToCSV(matches);

      print('\n=== Generated 50 Realistic Matches ===');
      print('First 10 rows:');
      final lines = csvContent.split('\n');
      for (int i = 0; i < 11 && i < lines.length; i++) {
        print(lines[i]);
      }
      print('... (${lines.length - 12} more rows)');

      final devDir = Directory('test_output/dev_data');
      await devDir.create(recursive: true);

      final file = File('test_output/dev_data/match_data_50matches.csv');
      await file.writeAsString(csvContent);

      print('\n✅ Saved to: ${file.path}');

      expect(matches.length, 50);
    });
  });
}

class RealisticMatchDataGenerator {
  final Random _random = Random();
  final List<String> _teams = [
    '2026mibg',
    '2026frc254',
    '2026frc1690',
    '2026frc2202',
    '2026frc3476',
    '2026frc1836',
    '2026frc3407',
    '2026frc4414',
  ];
  final List<String> _scouts = [
    'Alex',
    'Jordan',
    'Casey',
    'Morgan',
    'Taylor',
    'Riley',
    'Sam',
  ];
  final List<String> _events = [
    '2026mibg',
    '2026midmi',
    '2026mimel',
  ];

  List<MatchRecord> generateMatches(int count) {
    final matches = <MatchRecord>[];
    int matchNumber = 1;
    int stationIndex = 0;
    String currentAlliance = 'Red';

    for (int i = 0; i < count; i++) {
      final station = (stationIndex % 3) + 1;
      if (stationIndex % 3 == 2) {
        currentAlliance = currentAlliance == 'Red' ? 'Blue' : 'Red';
      }
      stationIndex++;

      final match = _generateSingleMatch(
        matchNumber: matchNumber,
        station: station,
        alliance: currentAlliance,
      );
      matches.add(match);

      // Increment match number every 6 teams (3 red, 3 blue)
      if ((i + 1) % 6 == 0) {
        matchNumber++;
      }
    }

    return matches;
  }

  MatchRecord _generateSingleMatch({
    required int matchNumber,
    required int station,
    required String alliance,
  }) {
    final team = _teams[_random.nextInt(_teams.length)];
    final scout = _scouts[_random.nextInt(_scouts.length)];
    final event = _events[_random.nextInt(_events.length)];

    // Generate correlated data - performance level (0-1) affects everything
    final performanceLevel = _random.nextDouble();

    // Auton data (correlates with overall performance)
    final autonShootingTime = performanceLevel > 0.7
        ? _randomDouble(18, 28) // Good teams spend more time
        : performanceLevel > 0.4
            ? _randomDouble(10, 18) // Medium teams
            : _randomDouble(2, 10); // Lower performance teams

    final autonShots =
        ((performanceLevel * 16) + _random.nextInt(6)).toInt().clamp(0, 20);
    final autonClimb = performanceLevel > 0.7 && _random.nextDouble() > 0.4;

    // TeleOp data (correlates with auton performance)
    final teleOpShootingTime = autonShootingTime * _randomDouble(1.2, 2.5);
    final teleOpShots =
        (autonShots * _randomDouble(2.0, 4.5)).toInt().clamp(0, 150);
    final teleOpDefense = performanceLevel > 0.6 && _random.nextDouble() > 0.3;
    final teleOpNeutralTrips =
        ((performanceLevel * 5).toInt() + _random.nextInt(3)).clamp(0, 8);
    final teleOpPushBalls = _random.nextInt(4);

    // Endgame data
    final climbStatus = performanceLevel > 0.75 ? _random.nextInt(3) + 1 : 0;
    final endgamePark = performanceLevel > 0.5 && _random.nextDouble() > 0.3;
    final endgameTime = endgamePark ? _randomDouble(5, 25) : 0.0;
    final shootingAccuracy =
        ((performanceLevel * 100).toInt() + _random.nextInt(20)).clamp(0, 100);

    final autonPoints = AutonPoints(
      autonShootingTime,
      autonShots,
      autonClimb,
      _random.nextInt(3),
    );

    final teleOpPoints = TeleOpPoints(
      teleOpShootingTime,
      teleOpShots,
      teleOpDefense,
      teleOpNeutralTrips,
      teleOpPushBalls,
      _random.nextInt(3),
    );

    final comments = [
      'Good driver',
      'Slow intake',
      'Solid all around',
      'Needs work on climb',
      'Fast cycles',
      '',
      '',
      '',
    ];

    final endPoints = EndPoints(
      climbStatus,
      endgamePark,
      _random.nextInt(3),
      _random.nextInt(3),
      _random.nextBool(),
      (teleOpNeutralTrips / 2).toInt(),
      shootingAccuracy,
      endgameTime,
      _random.nextInt(3),
      comments[_random.nextInt(comments.length)],
    );

    return MatchRecord(
      autonPoints,
      teleOpPoints,
      endPoints,
      teamNumber: team,
      scouterName: scout,
      matchKey: '${event}_qm$matchNumber',
      allianceColor: alliance,
      eventKey: event,
      station: station,
      matchNumber: matchNumber,
      batteryPercentage: 75 + _random.nextInt(25),
    );
  }

  String exportToCSV(List<MatchRecord> matches) {
    StringBuffer csv = StringBuffer();

    // Headers match the toCsv() output order from MatchRecord + nested classes
    const String headers =
        'Team,MatchKey,MatchNumber,ScouterName,AllianceColor,EventKey,Station,BatteryPercentage,'
        'AutonTotalShootingTime,AutonAmountOfShooting,AutonClimb,AutonPassing,'
        'TeleOpTotalShootingTime,TeleOpTotalAmount,TeleOpDefense,TeleOpNeutralTrips,TeleOpPushBalls,TeleOpPassing,'
        'EndClimbStatus,EndPark,EndPushBalls,EndPassing,EndRobotBroken,EndNeutralTrips,EndShootingAccuracy,EndEndgameTime,EndShootingCycles,EndComments';

    csv.writeln(headers);

    for (var match in matches) {
      csv.writeln(match.toCsv());
    }

    return csv.toString();
  }

  double _randomDouble(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }
}
