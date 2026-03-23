import 'package:dio/dio.dart';

import '../data/models.dart';
import '../util/result.dart';

class TbaClient {
  final Dio _dio;
  static const _baseUrl = 'https://www.thebluealliance.com/api/v3';
  static const _apiKey =
      'nfgL68cGRgoKXYWT0D4JcGxv6lPYuWkWVz4TcYPN9VlFQ6vHoLrQjJRwjFKRcJu8';

  TbaClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              headers: {'X-TBA-Auth-Key': _apiKey},
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  Future<Result<List<Event>>> getEvents(int year) async {
    try {
      final response = await _dio.get<List<dynamic>>('/events/$year');
      final events = (response.data ?? []).map((json) {
        final map = json as Map<String, dynamic>;
        return _parseEvent(map);
      }).toList();
      return Ok(events);
    } catch (e) {
      return Err(_errorMessage(e));
    }
  }

  Future<Result<Event>> getEvent(String eventKey) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/event/$eventKey');
      final map = response.data!;
      return Ok(_parseEvent(map));
    } catch (e) {
      return Err(_errorMessage(e));
    }
  }

  Future<Result<List<Team>>> getTeams(String eventKey) async {
    try {
      final response =
          await _dio.get<List<dynamic>>('/event/$eventKey/teams');
      final teams = (response.data ?? []).map((json) {
        final map = json as Map<String, dynamic>;
        return Team(
          eventKey: eventKey,
          teamNumber: map['team_number'] as int? ?? 0,
          nickname: map['nickname'] as String? ?? '',
        );
      }).toList();
      return Ok(teams);
    } catch (e) {
      return Err(_errorMessage(e));
    }
  }

  Future<Result<List<Match>>> getMatches(String eventKey) async {
    try {
      final response =
          await _dio.get<List<dynamic>>('/event/$eventKey/matches');
      final matches = (response.data ?? []).map((json) {
        final map = json as Map<String, dynamic>;
        return _parseMatch(map);
      }).toList();
      return Ok(matches);
    } catch (e) {
      return Err(_errorMessage(e));
    }
  }

  Future<Result<List<Alliance>?>> getAlliances(String eventKey) async {
    try {
      final response =
          await _dio.get<dynamic>('/event/$eventKey/alliances');
      final data = response.data;
      if (data == null || (data is List && data.isEmpty)) {
        return const Ok(null);
      }
      final list = data as List<dynamic>;
      final alliances = <Alliance>[];
      for (var i = 0; i < list.length; i++) {
        final map = list[i] as Map<String, dynamic>;
        final name = map['name'] as String? ?? 'Alliance ${i + 1}';
        final allianceNumber = _parseAllianceNumber(name, i + 1);
        final picks = (map['picks'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [];
        alliances.add(Alliance(
          eventKey: eventKey,
          allianceNumber: allianceNumber,
          name: name,
          picks: picks,
        ));
      }
      return Ok(alliances);
    } catch (e) {
      return Err(_errorMessage(e));
    }
  }

  Event _parseEvent(Map<String, dynamic> map) {
    final startDateStr = map['start_date'] as String? ?? '2000-01-01';
    final endDateStr = map['end_date'] as String? ?? '2000-01-01';
    return Event(
      eventKey: map['key'] as String? ?? '',
      name: map['name'] as String? ?? '',
      shortName: map['short_name'] as String? ?? map['name'] as String? ?? '',
      startDate: DateTime.parse(startDateStr),
      endDate: DateTime.parse(endDateStr),
      playoffType: map['playoff_type'] as int? ?? 0,
      timezone: map['timezone'] as String? ?? '',
    );
  }

  Match _parseMatch(Map<String, dynamic> map) {
    final alliances = map['alliances'] as Map<String, dynamic>? ?? {};
    final red = alliances['red'] as Map<String, dynamic>? ?? {};
    final blue = alliances['blue'] as Map<String, dynamic>? ?? {};

    final redTeamKeys = (red['team_keys'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];
    final blueTeamKeys = (blue['team_keys'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];

    final redScore = red['score'] as int? ?? -1;
    final blueScore = blue['score'] as int? ?? -1;

    String? youtubeKey;
    final videos = map['videos'] as List<dynamic>? ?? [];
    for (final video in videos) {
      final videoMap = video as Map<String, dynamic>;
      if (videoMap['type'] == 'youtube') {
        youtubeKey = videoMap['key'] as String?;
        break;
      }
    }

    return Match(
      matchKey: map['key'] as String? ?? '',
      eventKey: map['event_key'] as String? ?? '',
      compLevel: map['comp_level'] as String? ?? 'qm',
      setNumber: map['set_number'] as int? ?? 1,
      matchNumber: map['match_number'] as int? ?? 0,
      time: map['time'] as int?,
      actualTime: map['actual_time'] as int?,
      predictedTime: map['predicted_time'] as int?,
      redTeamKeys: redTeamKeys,
      blueTeamKeys: blueTeamKeys,
      redScore: redScore,
      blueScore: blueScore,
      winningAlliance: map['winning_alliance'] as String? ?? '',
      youtubeKey: youtubeKey,
    );
  }

  int _parseAllianceNumber(String name, int fallback) {
    final match = RegExp(r'(\d+)').firstMatch(name);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return fallback;
  }

  String _errorMessage(Object e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return 'Connection timed out. Check your internet connection.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Could not connect to The Blue Alliance. Check your internet connection.';
      }
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        if (statusCode == 401) {
          return 'TBA API key is invalid.';
        }
        if (statusCode == 404) {
          return 'Data not found on The Blue Alliance.';
        }
        return 'TBA returned error $statusCode.';
      }
      return 'Network error: ${e.message}';
    }
    return 'Failed to load data: $e';
  }
}
