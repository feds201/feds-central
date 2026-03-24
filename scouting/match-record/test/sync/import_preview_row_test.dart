import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/data/data_store.dart';
import 'package:match_record/data/json_persistence.dart';
import 'package:match_record/data/models.dart';
import 'package:match_record/import/import_pipeline.dart';
import 'package:match_record/import/video_metadata_service.dart';
import 'package:match_record/sync/import_preview_row.dart';

class FakeJsonPersistence extends JsonPersistence {
  AppData _data = AppData.empty();

  FakeJsonPersistence() : super(directoryPath: '/fake');

  @override
  Future<AppData> load() async => _data;

  @override
  Future<void> save(AppData data) async {
    _data = data;
  }
}

Match _makeMatch({
  required String matchKey,
  required int matchNumber,
  List<String> redTeamKeys = const ['frc100', 'frc200', 'frc300'],
  List<String> blueTeamKeys = const ['frc400', 'frc500', 'frc600'],
}) {
  return Match(
    matchKey: matchKey,
    eventKey: '2026mimid',
    compLevel: 'qm',
    setNumber: 1,
    matchNumber: matchNumber,
    redTeamKeys: redTeamKeys,
    blueTeamKeys: blueTeamKeys,
  );
}

ImportPreviewRow _makeRow() {
  return ImportPreviewRow(
    metadata: const VideoMetadata(
      sourceUri: 'test://video.mp4',
      originalFilename: 'video.mp4',
      durationMs: 60000,
    ),
    matchKey: '2026mimid_qm1',
    allianceSide: 'red',
    teams: [100, 200, 300],
  );
}

void main() {
  group('ImportPreviewRowWidget match dropdown highlighting', () {
    late DataStore dataStore;
    late FakeJsonPersistence persistence;

    setUp(() async {
      persistence = FakeJsonPersistence();
      dataStore = DataStore(persistence);
      await dataStore.init();
    });

    testWidgets('our matches show star prefix and bold text when team number is set',
        (tester) async {
      // Set our team number to 201
      await dataStore.updateSettings(
        dataStore.settings.copyWith(teamNumber: () => 201),
      );

      final matches = [
        _makeMatch(
          matchKey: '2026mimid_qm1',
          matchNumber: 1,
          redTeamKeys: ['frc201', 'frc100', 'frc300'],
          blueTeamKeys: ['frc400', 'frc500', 'frc600'],
        ),
        _makeMatch(
          matchKey: '2026mimid_qm2',
          matchNumber: 2,
          redTeamKeys: ['frc100', 'frc200', 'frc300'],
          blueTeamKeys: ['frc400', 'frc500', 'frc600'],
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ImportPreviewRowWidget(
            row: _makeRow(),
            rowIndex: 0,
            allMatches: matches,
            dataStore: dataStore,
            onMatchChanged: (_) {},
            onAllianceSideChanged: (_) {},
            onSelectionChanged: (_) {},
            onTeamsChanged: (_) {},
          ),
        ),
      ));

      // Open the dropdown
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Q1 has our team (201) — should show star prefix
      expect(find.text('\u2605 Q1'), findsWidgets);
      // Q2 does not have our team — no star
      expect(find.text('Q2'), findsWidgets);
      expect(find.text('\u2605 Q2'), findsNothing);
    });

    testWidgets('our matches on blue alliance also get star prefix',
        (tester) async {
      await dataStore.updateSettings(
        dataStore.settings.copyWith(teamNumber: () => 500),
      );

      final matches = [
        _makeMatch(
          matchKey: '2026mimid_qm1',
          matchNumber: 1,
          redTeamKeys: ['frc100', 'frc200', 'frc300'],
          blueTeamKeys: ['frc400', 'frc500', 'frc600'],
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ImportPreviewRowWidget(
            row: _makeRow(),
            rowIndex: 0,
            allMatches: matches,
            dataStore: dataStore,
            onMatchChanged: (_) {},
            onAllianceSideChanged: (_) {},
            onSelectionChanged: (_) {},
            onTeamsChanged: (_) {},
          ),
        ),
      ));

      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('\u2605 Q1'), findsWidgets);
    });

    testWidgets('no star prefix when team number is not set', (tester) async {
      // teamNumber is null by default

      final matches = [
        _makeMatch(
          matchKey: '2026mimid_qm1',
          matchNumber: 1,
          redTeamKeys: ['frc201', 'frc100', 'frc300'],
          blueTeamKeys: ['frc400', 'frc500', 'frc600'],
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ImportPreviewRowWidget(
            row: _makeRow(),
            rowIndex: 0,
            allMatches: matches,
            dataStore: dataStore,
            onMatchChanged: (_) {},
            onAllianceSideChanged: (_) {},
            onSelectionChanged: (_) {},
            onTeamsChanged: (_) {},
          ),
        ),
      ));

      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // No star because team number is null
      expect(find.text('\u2605 Q1'), findsNothing);
      expect(find.text('Q1'), findsWidgets);
    });

    testWidgets('no star prefix when our team is not in the match',
        (tester) async {
      await dataStore.updateSettings(
        dataStore.settings.copyWith(teamNumber: () => 999),
      );

      final matches = [
        _makeMatch(
          matchKey: '2026mimid_qm1',
          matchNumber: 1,
          redTeamKeys: ['frc100', 'frc200', 'frc300'],
          blueTeamKeys: ['frc400', 'frc500', 'frc600'],
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ImportPreviewRowWidget(
            row: _makeRow(),
            rowIndex: 0,
            allMatches: matches,
            dataStore: dataStore,
            onMatchChanged: (_) {},
            onAllianceSideChanged: (_) {},
            onSelectionChanged: (_) {},
            onTeamsChanged: (_) {},
          ),
        ),
      ));

      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('\u2605 Q1'), findsNothing);
      expect(find.text('Q1'), findsWidgets);
    });
  });
}
