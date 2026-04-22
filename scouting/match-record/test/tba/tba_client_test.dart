import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:match_record/tba/tba_client.dart';
import 'package:match_record/data/models.dart';
import 'package:match_record/util/result.dart';

class MockDio extends Mock implements Dio {}

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

void main() {
  late MockDio mockDio;
  late TbaClient client;

  setUp(() {
    mockDio = MockDio();
    client = TbaClient(dio: mockDio);
  });

  group('getEvents', () {
    test('parses event list correctly', () async {
      final responseData = [
        {
          'key': '2026mimid',
          'name': 'FIM District Midland Event',
          'short_name': 'Midland',
          'start_date': '2026-03-20',
          'end_date': '2026-03-22',
          'playoff_type': 10,
          'timezone': 'America/Detroit',
        },
        {
          'key': '2026mifor',
          'name': 'FIM District Forest Hills Event',
          'short_name': 'Forest Hills',
          'start_date': '2026-04-02',
          'end_date': '2026-04-04',
          'playoff_type': 10,
          'timezone': 'America/Detroit',
        },
      ];

      when(() => mockDio.get<List<dynamic>>('/events/2026')).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/events/2026'),
        ),
      );

      final result = await client.getEvents(2026);
      expect(result, isA<Ok<List<Event>>>());
      final events = (result as Ok<List<Event>>).value;
      expect(events.length, 2);
      expect(events[0].eventKey, '2026mimid');
      expect(events[0].name, 'FIM District Midland Event');
      expect(events[0].shortName, 'Midland');
      expect(events[0].startDate, DateTime(2026, 3, 20));
      expect(events[0].endDate, DateTime(2026, 3, 22));
      expect(events[0].playoffType, 10);
      expect(events[0].timezone, 'America/Detroit');
      expect(events[1].eventKey, '2026mifor');
    });

    test('uses name as shortName fallback when short_name is null', () async {
      final responseData = [
        {
          'key': '2026cmptx',
          'name': 'FIRST Championship - Houston',
          'short_name': null,
          'start_date': '2026-04-15',
          'end_date': '2026-04-18',
          'playoff_type': 10,
          'timezone': 'America/Chicago',
        },
      ];

      when(() => mockDio.get<List<dynamic>>('/events/2026')).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/events/2026'),
        ),
      );

      final result = await client.getEvents(2026);
      final events = (result as Ok<List<Event>>).value;
      expect(events[0].shortName, 'FIRST Championship - Houston');
    });

    test('returns Err on network error', () async {
      when(() => mockDio.get<List<dynamic>>('/events/2026')).thenThrow(
        DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: '/events/2026'),
        ),
      );

      final result = await client.getEvents(2026);
      expect(result, isA<Err<List<Event>>>());
      expect(
        (result as Err).message,
        contains('Could not connect'),
      );
    });
  });

  group('getEvent', () {
    test('parses single event correctly', () async {
      final responseData = {
        'key': '2026mimid',
        'name': 'FIM District Midland Event',
        'short_name': 'Midland',
        'start_date': '2026-03-20',
        'end_date': '2026-03-22',
        'playoff_type': 10,
        'timezone': 'America/Detroit',
      };

      when(() => mockDio.get<Map<String, dynamic>>('/event/2026mimid'))
          .thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/event/2026mimid'),
        ),
      );

      final result = await client.getEvent('2026mimid');
      expect(result, isA<Ok<Event>>());
      final event = (result as Ok<Event>).value;
      expect(event.eventKey, '2026mimid');
      expect(event.shortName, 'Midland');
    });
  });

  group('getTeams', () {
    test('parses team list with eventKey attached', () async {
      final responseData = [
        {
          'team_number': 201,
          'nickname': 'The FEDS',
          'key': 'frc201',
        },
        {
          'team_number': 5166,
          'nickname': 'Steel Dragons',
          'key': 'frc5166',
        },
      ];

      when(() => mockDio.get<List<dynamic>>('/event/2026mimid/teams'))
          .thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/event/2026mimid/teams'),
        ),
      );

      final result = await client.getTeams('2026mimid');
      expect(result, isA<Ok<List<Team>>>());
      final teams = (result as Ok<List<Team>>).value;
      expect(teams.length, 2);
      expect(teams[0].eventKey, '2026mimid');
      expect(teams[0].teamNumber, 201);
      expect(teams[0].nickname, 'The FEDS');
      expect(teams[1].teamNumber, 5166);
    });
  });

  group('getMatches', () {
    test('parses match with all fields', () async {
      final responseData = [
        {
          'key': '2026mimid_qm1',
          'event_key': '2026mimid',
          'comp_level': 'qm',
          'set_number': 1,
          'match_number': 1,
          'time': 1711000000,
          'actual_time': 1711000120,
          'predicted_time': 1711000060,
          'alliances': {
            'red': {
              'team_keys': ['frc201', 'frc5166', 'frc5712'],
              'score': 42,
            },
            'blue': {
              'team_keys': ['frc8873', 'frc5424', 'frc5216'],
              'score': 38,
            },
          },
          'winning_alliance': 'red',
          'videos': [
            {'type': 'youtube', 'key': 'dQw4w9WgXcQ'},
            {'type': 'tba', 'key': 'some_other_video'},
          ],
        },
      ];

      when(() => mockDio.get<List<dynamic>>('/event/2026mimid/matches'))
          .thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/event/2026mimid/matches'),
        ),
      );

      final result = await client.getMatches('2026mimid');
      expect(result, isA<Ok<List<Match>>>());
      final matches = (result as Ok<List<Match>>).value;
      expect(matches.length, 1);

      final m = matches[0];
      expect(m.matchKey, '2026mimid_qm1');
      expect(m.eventKey, '2026mimid');
      expect(m.compLevel, 'qm');
      expect(m.setNumber, 1);
      expect(m.matchNumber, 1);
      expect(m.time, 1711000000);
      expect(m.actualTime, 1711000120);
      expect(m.predictedTime, 1711000060);
      expect(m.redTeamKeys, ['frc201', 'frc5166', 'frc5712']);
      expect(m.blueTeamKeys, ['frc8873', 'frc5424', 'frc5216']);
      expect(m.redScore, 42);
      expect(m.blueScore, 38);
      expect(m.winningAlliance, 'red');
      expect(m.youtubeKey, 'dQw4w9WgXcQ');
    });

    test('parses unplayed match correctly', () async {
      final responseData = [
        {
          'key': '2026mimid_qm32',
          'event_key': '2026mimid',
          'comp_level': 'qm',
          'set_number': 1,
          'match_number': 32,
          'time': 1711100000,
          'actual_time': null,
          'predicted_time': null,
          'alliances': {
            'red': {
              'team_keys': ['frc201', 'frc100', 'frc200'],
              'score': -1,
            },
            'blue': {
              'team_keys': ['frc300', 'frc400', 'frc500'],
              'score': -1,
            },
          },
          'winning_alliance': '',
          'videos': [],
        },
      ];

      when(() => mockDio.get<List<dynamic>>('/event/2026mimid/matches'))
          .thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/event/2026mimid/matches'),
        ),
      );

      final result = await client.getMatches('2026mimid');
      final m = (result as Ok<List<Match>>).value[0];
      expect(m.actualTime, isNull);
      expect(m.predictedTime, isNull);
      expect(m.redScore, -1);
      expect(m.blueScore, -1);
      expect(m.winningAlliance, '');
      expect(m.youtubeKey, isNull);
    });

    test('extracts first youtube video key from videos array', () async {
      final responseData = [
        {
          'key': '2026mimid_qm5',
          'event_key': '2026mimid',
          'comp_level': 'qm',
          'set_number': 1,
          'match_number': 5,
          'time': 1711050000,
          'alliances': {
            'red': {
              'team_keys': ['frc1', 'frc2', 'frc3'],
              'score': 50,
            },
            'blue': {
              'team_keys': ['frc4', 'frc5', 'frc6'],
              'score': 30,
            },
          },
          'winning_alliance': 'red',
          'videos': [
            {'type': 'tba', 'key': 'tba_video_1'},
            {'type': 'youtube', 'key': 'first_yt_key'},
            {'type': 'youtube', 'key': 'second_yt_key'},
          ],
        },
      ];

      when(() => mockDio.get<List<dynamic>>('/event/2026mimid/matches'))
          .thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/event/2026mimid/matches'),
        ),
      );

      final result = await client.getMatches('2026mimid');
      final m = (result as Ok<List<Match>>).value[0];
      expect(m.youtubeKey, 'first_yt_key');
    });

    test('handles match with no videos array', () async {
      final responseData = [
        {
          'key': '2026mimid_qm10',
          'event_key': '2026mimid',
          'comp_level': 'qm',
          'set_number': 1,
          'match_number': 10,
          'alliances': {
            'red': {
              'team_keys': ['frc1', 'frc2', 'frc3'],
              'score': -1,
            },
            'blue': {
              'team_keys': ['frc4', 'frc5', 'frc6'],
              'score': -1,
            },
          },
          'winning_alliance': '',
        },
      ];

      when(() => mockDio.get<List<dynamic>>('/event/2026mimid/matches'))
          .thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/event/2026mimid/matches'),
        ),
      );

      final result = await client.getMatches('2026mimid');
      final m = (result as Ok<List<Match>>).value[0];
      expect(m.youtubeKey, isNull);
      expect(m.time, isNull);
    });

    test('parses double-elim semifinal match', () async {
      final responseData = [
        {
          'key': '2026mimid_sf3m1',
          'event_key': '2026mimid',
          'comp_level': 'sf',
          'set_number': 3,
          'match_number': 1,
          'time': 1711200000,
          'alliances': {
            'red': {
              'team_keys': ['frc201', 'frc100', 'frc200'],
              'score': 55,
            },
            'blue': {
              'team_keys': ['frc300', 'frc400', 'frc500'],
              'score': 60,
            },
          },
          'winning_alliance': 'blue',
          'videos': [],
        },
      ];

      when(() => mockDio.get<List<dynamic>>('/event/2026mimid/matches'))
          .thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/event/2026mimid/matches'),
        ),
      );

      final result = await client.getMatches('2026mimid');
      final m = (result as Ok<List<Match>>).value[0];
      expect(m.compLevel, 'sf');
      expect(m.setNumber, 3);
      expect(m.matchNumber, 1);
      expect(m.displayName, 'SF 3');
    });
  });

  group('getAlliances', () {
    test('parses alliance list correctly', () async {
      final responseData = [
        {
          'name': 'Alliance 1',
          'picks': ['frc201', 'frc5166', 'frc5712'],
          'status': {},
        },
        {
          'name': 'Alliance 2',
          'picks': ['frc8873', 'frc5424', 'frc5216', 'frc999'],
          'status': {},
        },
      ];

      when(() => mockDio.get<dynamic>('/event/2026mimid/alliances'))
          .thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/event/2026mimid/alliances'),
        ),
      );

      final result = await client.getAlliances('2026mimid');
      expect(result, isA<Ok<List<Alliance>?>>());
      final alliances = (result as Ok<List<Alliance>?>).value!;
      expect(alliances.length, 2);
      expect(alliances[0].eventKey, '2026mimid');
      expect(alliances[0].allianceNumber, 1);
      expect(alliances[0].name, 'Alliance 1');
      expect(alliances[0].picks, ['frc201', 'frc5166', 'frc5712']);
      expect(alliances[1].allianceNumber, 2);
      expect(alliances[1].picks.length, 4);
    });

    test('returns null when TBA returns null (before alliance selection)',
        () async {
      when(() => mockDio.get<dynamic>('/event/2026mimid/alliances'))
          .thenAnswer(
        (_) async => Response(
          data: null,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/event/2026mimid/alliances'),
        ),
      );

      final result = await client.getAlliances('2026mimid');
      expect(result, isA<Ok<List<Alliance>?>>());
      expect((result as Ok<List<Alliance>?>).value, isNull);
    });

    test('returns null when TBA returns empty list', () async {
      when(() => mockDio.get<dynamic>('/event/2026mimid/alliances'))
          .thenAnswer(
        (_) async => Response(
          data: <dynamic>[],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/event/2026mimid/alliances'),
        ),
      );

      final result = await client.getAlliances('2026mimid');
      expect(result, isA<Ok<List<Alliance>?>>());
      expect((result as Ok<List<Alliance>?>).value, isNull);
    });

    test('handles named alliances at Worlds', () async {
      final responseData = [
        {
          'name': 'Newton',
          'picks': ['frc201', 'frc100', 'frc200'],
          'status': {},
        },
      ];

      when(() => mockDio.get<dynamic>('/event/2025cmptx/alliances'))
          .thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/event/2025cmptx/alliances'),
        ),
      );

      final result = await client.getAlliances('2025cmptx');
      final alliances = (result as Ok<List<Alliance>?>).value!;
      expect(alliances[0].name, 'Newton');
      expect(alliances[0].allianceNumber, 1);
    });
  });

  group('error handling', () {
    test('timeout error returns user-readable message', () async {
      when(() => mockDio.get<List<dynamic>>('/events/2026')).thenThrow(
        DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/events/2026'),
        ),
      );

      final result = await client.getEvents(2026);
      expect(result, isA<Err<List<Event>>>());
      expect((result as Err).message, contains('timed out'));
    });

    test('404 returns data not found message', () async {
      when(() => mockDio.get<List<dynamic>>('/event/bad_key/teams')).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(path: '/event/bad_key/teams'),
          ),
          requestOptions: RequestOptions(path: '/event/bad_key/teams'),
        ),
      );

      final result = await client.getTeams('bad_key');
      expect(result, isA<Err<List<Team>>>());
      expect((result as Err).message, contains('not found'));
    });

    test('401 returns invalid API key message', () async {
      when(() => mockDio.get<List<dynamic>>('/events/2026')).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/events/2026'),
          ),
          requestOptions: RequestOptions(path: '/events/2026'),
        ),
      );

      final result = await client.getEvents(2026);
      expect(result, isA<Err<List<Event>>>());
      expect((result as Err).message, contains('API key'));
    });

    test('non-DioException returns generic message', () async {
      when(() => mockDio.get<List<dynamic>>('/events/2026')).thenThrow(
        FormatException('bad json'),
      );

      final result = await client.getEvents(2026);
      expect(result, isA<Err<List<Event>>>());
      expect((result as Err).message, contains('Failed to load'));
    });
  });
}
