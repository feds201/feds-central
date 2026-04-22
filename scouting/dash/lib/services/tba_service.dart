import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetches OPR (Offensive Power Rating) data from The Blue Alliance API.
///
/// Docs: https://www.thebluealliance.com/apidocs/v3
class TbaService {
  TbaService(this.apiKey);

  final String apiKey;

  static const _base = 'https://www.thebluealliance.com/api/v3';

  /// Returns a map of team number (int) → OPR (double) for the given event.
  Future<Map<int, double>> fetchOprs(String eventKey) async {
    final uri = Uri.parse('$_base/event/$eventKey/oprs');
    final resp = await http.get(uri, headers: {'X-TBA-Auth-Key': apiKey});

    if (resp.statusCode != 200) {
      throw TbaException('TBA ${resp.statusCode}: ${resp.body}');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final oprs = body['oprs'] as Map<String, dynamic>? ?? {};

    // Keys are "frcNNNN".  Strip prefix and parse to int.
    final result = <int, double>{};
    oprs.forEach((key, value) {
      final teamNum = int.tryParse(key.replaceFirst('frc', ''));
      if (teamNum != null && value is num) {
        result[teamNum] = value.toDouble();
      }
    });
    return result;
  }

  /// Fetch basic event info (name, location) for display.
  Future<Map<String, dynamic>> fetchEventInfo(String eventKey) async {
    final uri = Uri.parse('$_base/event/$eventKey');
    final resp = await http.get(uri, headers: {'X-TBA-Auth-Key': apiKey});

    if (resp.statusCode != 200) {
      throw TbaException('TBA ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Fetch all matches for an event (raw JSON list).
  Future<List<dynamic>> fetchMatches(String eventKey) async {
    final uri = Uri.parse('$_base/event/$eventKey/matches');
    final resp = await http.get(uri, headers: {'X-TBA-Auth-Key': apiKey});

    if (resp.statusCode != 200) {
      throw TbaException('TBA ${resp.statusCode}: ${resp.body}');
    }

    return jsonDecode(resp.body) as List<dynamic>;
  }

  /// Fetch the team list for an event (returns list of team numbers).
  Future<List<int>> fetchTeamNumbers(String eventKey) async {
    final uri = Uri.parse('$_base/event/$eventKey/teams/keys');
    final resp = await http.get(uri, headers: {'X-TBA-Auth-Key': apiKey});

    if (resp.statusCode != 200) {
      throw TbaException('TBA ${resp.statusCode}: ${resp.body}');
    }

    final keys = (jsonDecode(resp.body) as List<dynamic>).cast<String>();
    return keys
        .map((k) => int.tryParse(k.replaceFirst('frc', '')))
        .whereType<int>()
        .toList()
      ..sort();
  }

  /// Fetch playoff alliances for an event.
  /// Returns raw JSON list. Events without elims return `null` from TBA —
  /// this method normalizes that to `[]`.
  Future<List<dynamic>> fetchPlayoffAlliances(String eventKey) async {
    final uri = Uri.parse('$_base/event/$eventKey/alliances');
    final resp = await http.get(uri, headers: {'X-TBA-Auth-Key': apiKey});

    if (resp.statusCode == 404) return const [];
    if (resp.statusCode != 200) {
      throw TbaException('TBA ${resp.statusCode}: ${resp.body}');
    }

    final body = resp.body.isEmpty ? null : jsonDecode(resp.body);
    if (body is! List) return const [];
    return body;
  }

  /// Fetch team number → nickname for every team at an event.
  /// Returns `{}` on error or empty response.
  Future<Map<int, String>> fetchTeamNames(String eventKey) async {
    final uri = Uri.parse('$_base/event/$eventKey/teams/simple');
    final resp = await http.get(uri, headers: {'X-TBA-Auth-Key': apiKey});

    if (resp.statusCode != 200) {
      throw TbaException('TBA ${resp.statusCode}: ${resp.body}');
    }

    final list = jsonDecode(resp.body);
    if (list is! List) return const {};

    final result = <int, String>{};
    for (final item in list) {
      if (item is! Map) continue;
      final num = item['team_number'];
      final nick = item['nickname'];
      if (num is int && nick is String && nick.isNotEmpty) {
        result[num] = nick;
      }
    }
    return result;
  }
}

class TbaException implements Exception {
  final String message;
  TbaException(this.message);
  @override
  String toString() => 'TbaException: $message';
}
