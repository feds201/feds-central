import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/data/models.dart';
import 'package:match_record/util/tba_status_warning.dart';

Match _match({String eventKey = '2026mimid', int n = 1}) => Match(
      matchKey: '${eventKey}_qm$n',
      eventKey: eventKey,
      compLevel: 'qm',
      setNumber: 1,
      matchNumber: n,
      redTeamKeys: const ['frc1', 'frc2', 'frc3'],
      blueTeamKeys: const ['frc4', 'frc5', 'frc6'],
    );

void main() {
  group('resolveTbaWarning', () {
    test('tier 1: no events selected returns events message', () {
      const settings = AppSettings();
      expect(
        resolveTbaWarning(settings, const []),
        'No events selected. Please enter an event in settings.',
      );
    });

    test('tier 1 takes precedence over missing api key and missing matches',
        () {
      const settings = AppSettings();
      expect(
        resolveTbaWarning(settings, [_match()]),
        'No events selected. Please enter an event in settings.',
      );
    });

    test('tier 2: events selected but null api key', () {
      const settings = AppSettings(selectedEventKeys: ['2026mimid']);
      expect(
        resolveTbaWarning(settings, const []),
        'No Blue Alliance API key entered. Please enter it in settings.',
      );
    });

    test('tier 2: events selected but empty-string api key', () {
      const settings =
          AppSettings(selectedEventKeys: ['2026mimid'], tbaApiKey: '');
      expect(
        resolveTbaWarning(settings, const []),
        'No Blue Alliance API key entered. Please enter it in settings.',
      );
    });

    test('tier 3: events + api key, but no matches for events', () {
      const settings =
          AppSettings(selectedEventKeys: ['2026mimid'], tbaApiKey: 'key');
      final message = resolveTbaWarning(settings, const []);
      expect(message, isNotNull);
      expect(message!, contains('No data from The Blue Alliance'));
    });

    test('returns null when events, api key, and matches are all present', () {
      const settings =
          AppSettings(selectedEventKeys: ['2026mimid'], tbaApiKey: 'key');
      expect(resolveTbaWarning(settings, [_match()]), isNull);
    });
  });
}
