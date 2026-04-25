import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/data/models.dart';
import 'package:match_record/tabs/search_tab.dart';
import 'package:match_record/widgets/app_search_bar.dart';

void main() {
  Match _makeMatch({
    required String key,
    required List<String> redTeamKeys,
    required List<String> blueTeamKeys,
  }) {
    return Match(
      matchKey: key,
      eventKey: '2026mimid',
      compLevel: 'qm',
      setNumber: 1,
      matchNumber: int.tryParse(key.split('qm').last) ?? 1,
      redTeamKeys: redTeamKeys,
      blueTeamKeys: blueTeamKeys,
    );
  }

  MatchWithVideos _mwv(Match m) {
    return MatchWithVideos(match: m);
  }

  group('SearchTab.matchesUnion', () {
    final m1 = _makeMatch(
      key: '2026mimid_qm1',
      redTeamKeys: ['frc201', 'frc100', 'frc101'],
      blueTeamKeys: ['frc254', 'frc200', 'frc202'],
    );
    final m2 = _makeMatch(
      key: '2026mimid_qm2',
      redTeamKeys: ['frc254', 'frc300', 'frc301'],
      blueTeamKeys: ['frc400', 'frc401', 'frc402'],
    );
    final m3 = _makeMatch(
      key: '2026mimid_qm3',
      redTeamKeys: ['frc500', 'frc501', 'frc502'],
      blueTeamKeys: ['frc600', 'frc601', 'frc602'],
    );
    final m4 = _makeMatch(
      key: '2026mimid_qm4',
      redTeamKeys: ['frc201', 'frc100', 'frc101'],
      blueTeamKeys: ['frc254', 'frc200', 'frc202'],
    );

    test('returns matches containing ANY of the searched teams', () {
      final teamNumbers = {201, 254};
      final matches = [_mwv(m1), _mwv(m2), _mwv(m3)];
      final filtered = matches
          .where((mwv) => SearchTab.matchesUnion(mwv, teamNumbers))
          .toList();
      expect(filtered.length, 2);
      expect(filtered[0].match.matchKey, '2026mimid_qm1');
      expect(filtered[1].match.matchKey, '2026mimid_qm2');
    });

    test('returns empty when no teams match', () {
      final teamNumbers = {999};
      final matches = [_mwv(m1), _mwv(m2), _mwv(m3)];
      final filtered = matches
          .where((mwv) => SearchTab.matchesUnion(mwv, teamNumbers))
          .toList();
      expect(filtered, isEmpty);
    });

    test('single team finds all its matches', () {
      final teamNumbers = {201};
      final matches = [_mwv(m1), _mwv(m2), _mwv(m3), _mwv(m4)];
      final filtered = matches
          .where((mwv) => SearchTab.matchesUnion(mwv, teamNumbers))
          .toList();
      expect(filtered.length, 2);
    });

    test('finds team on blue alliance', () {
      final teamNumbers = {254};
      expect(SearchTab.matchesUnion(_mwv(m1), teamNumbers), true);
    });

    test('finds team on red alliance', () {
      final teamNumbers = {201};
      expect(SearchTab.matchesUnion(_mwv(m1), teamNumbers), true);
    });

    test('empty team numbers matches nothing', () {
      final teamNumbers = <int>{};
      expect(SearchTab.matchesUnion(_mwv(m1), teamNumbers), false);
    });
  });

  group('SearchTab.matchesIntersect', () {
    final m1 = _makeMatch(
      key: '2026mimid_qm1',
      redTeamKeys: ['frc201', 'frc100', 'frc101'],
      blueTeamKeys: ['frc254', 'frc200', 'frc202'],
    );
    final m2 = _makeMatch(
      key: '2026mimid_qm2',
      redTeamKeys: ['frc254', 'frc300', 'frc301'],
      blueTeamKeys: ['frc400', 'frc401', 'frc402'],
    );
    final m3 = _makeMatch(
      key: '2026mimid_qm3',
      redTeamKeys: ['frc201', 'frc501', 'frc502'],
      blueTeamKeys: ['frc600', 'frc601', 'frc602'],
    );

    test('returns only matches containing ALL searched teams', () {
      final teamNumbers = {201, 254};
      final matches = [_mwv(m1), _mwv(m2), _mwv(m3)];
      final filtered = matches
          .where((mwv) => SearchTab.matchesIntersect(mwv, teamNumbers))
          .toList();
      expect(filtered.length, 1);
      expect(filtered[0].match.matchKey, '2026mimid_qm1');
    });

    test('returns all matches when searching single team', () {
      final teamNumbers = {201};
      final matches = [_mwv(m1), _mwv(m3)];
      final filtered = matches
          .where((mwv) => SearchTab.matchesIntersect(mwv, teamNumbers))
          .toList();
      expect(filtered.length, 2);
    });

    test('returns empty when no match has all teams', () {
      final teamNumbers = {201, 254, 500};
      final matches = [_mwv(m1), _mwv(m2), _mwv(m3)];
      final filtered = matches
          .where((mwv) => SearchTab.matchesIntersect(mwv, teamNumbers))
          .toList();
      expect(filtered, isEmpty);
    });

    test('works with teams on same alliance side', () {
      final mSameRed = _makeMatch(
        key: '2026mimid_qm10',
        redTeamKeys: ['frc201', 'frc254', 'frc100'],
        blueTeamKeys: ['frc400', 'frc401', 'frc402'],
      );
      final teamNumbers = {201, 254};
      expect(SearchTab.matchesIntersect(_mwv(mSameRed), teamNumbers), true);
    });

    test('works with teams on opposite alliance sides', () {
      final mOpposite = _makeMatch(
        key: '2026mimid_qm11',
        redTeamKeys: ['frc201', 'frc100', 'frc101'],
        blueTeamKeys: ['frc254', 'frc200', 'frc202'],
      );
      final teamNumbers = {201, 254};
      expect(SearchTab.matchesIntersect(_mwv(mOpposite), teamNumbers), true);
    });

    test('empty team numbers matches all matches (vacuous truth)', () {
      final teamNumbers = <int>{};
      expect(SearchTab.matchesIntersect(_mwv(m1), teamNumbers), true);
    });
  });

  group('SearchFilterMode', () {
    test('has union and intersect values', () {
      expect(SearchFilterMode.values.length, 2);
      expect(SearchFilterMode.values, contains(SearchFilterMode.union));
      expect(SearchFilterMode.values, contains(SearchFilterMode.intersect));
    });
  });
}
