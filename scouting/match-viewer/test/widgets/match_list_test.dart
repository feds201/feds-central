import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/data/models.dart';
import 'package:match_record/widgets/match_list.dart';
import 'package:match_record/widgets/match_row.dart';

Match _makeMatch({
  required String matchKey,
  required String compLevel,
  int matchNumber = 1,
  int setNumber = 1,
  int? time,
  List<String> redTeamKeys = const ['frc100', 'frc200', 'frc300'],
  List<String> blueTeamKeys = const ['frc400', 'frc500', 'frc600'],
}) {
  return Match(
    matchKey: matchKey,
    eventKey: '2026mimid',
    compLevel: compLevel,
    setNumber: setNumber,
    matchNumber: matchNumber,
    time: time,
    redTeamKeys: redTeamKeys,
    blueTeamKeys: blueTeamKeys,
  );
}

MatchWithVideos _mwv(Match m) => MatchWithVideos(match: m);

void main() {
  group('MatchList sections (showYourMatchesSection=true)', () {
    testWidgets('shows Our Matches, Quals, Playoffs headers', (tester) async {
      final matches = [
        _mwv(_makeMatch(
          matchKey: '2026mimid_qm1',
          compLevel: 'qm',
          matchNumber: 1,
          time: 1000,
          redTeamKeys: ['frc201', 'frc100', 'frc200'],
          blueTeamKeys: ['frc300', 'frc400', 'frc500'],
        )),
        _mwv(_makeMatch(
          matchKey: '2026mimid_qm2',
          compLevel: 'qm',
          matchNumber: 2,
          time: 2000,
        )),
        _mwv(_makeMatch(
          matchKey: '2026mimid_sf1',
          compLevel: 'sf',
          setNumber: 1,
          time: 3000,
          redTeamKeys: ['frc201', 'frc100', 'frc200'],
          blueTeamKeys: ['frc300', 'frc400', 'frc500'],
        )),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MatchList(
            matches: matches,
            yourTeamNumber: 201,
            showYourMatchesSection: true,
            onMatchTap: (_) {},
          ),
        ),
      ));

      // Should have all three section headers
      expect(find.text('Our Matches'), findsOneWidget);
      expect(find.text('Quals'), findsOneWidget);
      expect(find.text('Playoffs'), findsOneWidget);
    });

    testWidgets('no Our Matches section when team has no matches', (tester) async {
      final matches = [
        _mwv(_makeMatch(
          matchKey: '2026mimid_qm1',
          compLevel: 'qm',
          matchNumber: 1,
          time: 1000,
        )),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MatchList(
            matches: matches,
            yourTeamNumber: 201,
            showYourMatchesSection: true,
            onMatchTap: (_) {},
          ),
        ),
      ));

      expect(find.text('Our Matches'), findsNothing);
      expect(find.text('Quals'), findsOneWidget);
    });

    testWidgets('no Playoffs section when only quals exist', (tester) async {
      final matches = [
        _mwv(_makeMatch(
          matchKey: '2026mimid_qm1',
          compLevel: 'qm',
          matchNumber: 1,
          time: 1000,
        )),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MatchList(
            matches: matches,
            yourTeamNumber: 201,
            showYourMatchesSection: true,
            onMatchTap: (_) {},
          ),
        ),
      ));

      expect(find.text('Playoffs'), findsNothing);
    });

    testWidgets('your match rows get isYourMatch=true', (tester) async {
      final matches = [
        _mwv(_makeMatch(
          matchKey: '2026mimid_qm1',
          compLevel: 'qm',
          matchNumber: 1,
          time: 1000,
          redTeamKeys: ['frc201', 'frc100', 'frc200'],
          blueTeamKeys: ['frc300', 'frc400', 'frc500'],
        )),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MatchList(
            matches: matches,
            yourTeamNumber: 201,
            showYourMatchesSection: true,
            onMatchTap: (_) {},
          ),
        ),
      ));

      // Find MatchRow widgets and check isYourMatch
      final matchRows = tester.widgetList<MatchRow>(find.byType(MatchRow));
      // Should have 2 rows: one in "Our Matches" and one in "Quals"
      expect(matchRows.length, 2);
      for (final row in matchRows) {
        expect(row.isYourMatch, true);
      }
    });

    testWidgets('non-your match rows get isYourMatch=false', (tester) async {
      final matches = [
        _mwv(_makeMatch(
          matchKey: '2026mimid_qm1',
          compLevel: 'qm',
          matchNumber: 1,
          time: 1000,
        )),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MatchList(
            matches: matches,
            yourTeamNumber: 201,
            showYourMatchesSection: true,
            onMatchTap: (_) {},
          ),
        ),
      ));

      final matchRows = tester.widgetList<MatchRow>(find.byType(MatchRow));
      expect(matchRows.length, 1);
      expect(matchRows.first.isYourMatch, false);
    });

    testWidgets('alliances are passed to MatchRow', (tester) async {
      final alliances = [
        const Alliance(
          eventKey: '2026mimid',
          allianceNumber: 1,
          name: 'Alliance 1',
          picks: ['frc201', 'frc100', 'frc200'],
        ),
      ];

      final matches = [
        _mwv(_makeMatch(
          matchKey: '2026mimid_sf1',
          compLevel: 'sf',
          setNumber: 1,
          time: 1000,
          redTeamKeys: ['frc201', 'frc100', 'frc200'],
          blueTeamKeys: ['frc300', 'frc400', 'frc500'],
        )),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MatchList(
            matches: matches,
            yourTeamNumber: 201,
            showYourMatchesSection: true,
            alliances: alliances,
            onMatchTap: (_) {},
          ),
        ),
      ));

      final matchRows = tester.widgetList<MatchRow>(find.byType(MatchRow));
      for (final row in matchRows) {
        expect(row.alliances, alliances);
      }
    });
  });

  group('MatchList without sections', () {
    testWidgets('shows plain list when showYourMatchesSection=false', (tester) async {
      final matches = [
        _mwv(_makeMatch(
          matchKey: '2026mimid_qm1',
          compLevel: 'qm',
          matchNumber: 1,
          time: 1000,
        )),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MatchList(
            matches: matches,
            showYourMatchesSection: false,
            onMatchTap: (_) {},
          ),
        ),
      ));

      expect(find.text('Our Matches'), findsNothing);
      expect(find.text('Quals'), findsNothing);
      expect(find.text('Playoffs'), findsNothing);
      expect(find.byType(MatchRow), findsOneWidget);
    });

    testWidgets('shows empty state for no matches', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MatchList(
            matches: const [],
            onMatchTap: (_) {},
          ),
        ),
      ));

      expect(find.text('No matches'), findsOneWidget);
    });
  });
}
