import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetches EPA (Expected Points Added) data from the Statbotics v3 API.
///
/// Docs: https://api.statbotics.io/v3/docs
class StatboticsService {
  static const _base = 'https://api.statbotics.io/v3';

  /// Returns a map of team number (int) → EPA (double) for the given event.
  Future<Map<int, double>> fetchEpas(String eventKey) async {
    final uri = Uri.parse('$_base/team_events?event=$eventKey&limit=100');
    final resp = await http.get(uri);

    if (resp.statusCode != 200) {
      throw StatboticsException(
          'Statbotics ${resp.statusCode}: ${resp.body}');
    }

    final body = jsonDecode(resp.body);

    // v3 returns a list of team-event objects.
    final List<dynamic> items;
    if (body is List) {
      items = body;
    } else if (body is Map && body.containsKey('data')) {
      items = body['data'] as List<dynamic>;
    } else {
      items = [];
    }

    final result = <int, double>{};
    for (final item in items) {
      final teamNum = _extractTeamNum(item);
      final epa = _extractEpa(item);
      if (teamNum != null && epa != null) {
        result[teamNum] = epa;
      }
    }
    return result;
  }

  // ── Helpers ────────────────────────────────────────────────────────

  static int? _extractTeamNum(dynamic item) {
    if (item is! Map) return null;
    // May be nested under "team" or flat.
    final raw = item['team'] ?? item['team_number'] ?? item['team_num'];
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw.replaceFirst('frc', ''));
    return null;
  }

  static double? _extractEpa(dynamic item) {
    if (item is! Map) return null;
    // EPA may be nested under an `epa` object or flat.
    final epaField = item['epa'] ?? item['epa_end'] ?? item['epa_mean'];
    if (epaField is num) return epaField.toDouble();
    if (epaField is Map) {
      final val = epaField['total_points'] ??
          epaField['mean'] ??
          epaField['end'] ??
          epaField['start'];
      if (val is num) return val.toDouble();
    }
    return null;
  }
}

class StatboticsException implements Exception {
  final String message;
  StatboticsException(this.message);
  @override
  String toString() => 'StatboticsException: $message';
}
