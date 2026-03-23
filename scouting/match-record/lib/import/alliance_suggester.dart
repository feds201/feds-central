import 'dart:convert';

/// Result of alliance suggestion from drive config.
class AllianceSuggestion {
  /// "red", "blue", or null if no suggestion possible.
  final String? side;

  const AllianceSuggestion({this.side});
}

/// Pure function: suggest alliance side based on config.json content.
class AllianceSuggester {
  /// Parse config.json content for alliance side.
  /// Returns null side if config is null, empty, malformed,
  /// or doesn't contain a valid alliance value.
  static AllianceSuggestion suggest({required String? configJsonContent}) {
    if (configJsonContent == null || configJsonContent.isEmpty) {
      return const AllianceSuggestion();
    }

    try {
      final json = jsonDecode(configJsonContent);
      if (json is! Map<String, dynamic>) {
        return const AllianceSuggestion();
      }

      final alliance = json['alliance'];
      if (alliance is! String) {
        return const AllianceSuggestion();
      }

      final normalized = alliance.toLowerCase().trim();
      if (normalized == 'red' || normalized == 'blue') {
        return AllianceSuggestion(side: normalized);
      }

      return const AllianceSuggestion();
    } catch (_) {
      return const AllianceSuggestion();
    }
  }
}
