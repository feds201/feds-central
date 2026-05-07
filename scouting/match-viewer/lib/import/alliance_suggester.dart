import 'dart:convert';

/// Result of alliance suggestion from drive config.
class AllianceSuggestion {
  /// "red", "blue", "full", or null if no suggestion possible.
  final String? side;

  const AllianceSuggestion({this.side});
}

/// Pure function: suggest alliance side based on config.json content.
class AllianceSuggester {
  /// Parse config.json content for alliance side.
  ///
  /// Expected format: {"type": "red"} | {"type": "blue"} | {"type": "full"}
  ///
  /// Returns null side if config is null, empty, malformed,
  /// or doesn't contain a valid type value.
  static AllianceSuggestion suggest({required String? configJsonContent}) {
    if (configJsonContent == null || configJsonContent.isEmpty) {
      return const AllianceSuggestion();
    }

    try {
      final json = jsonDecode(configJsonContent);
      if (json is! Map<String, dynamic>) {
        return const AllianceSuggestion();
      }

      final type = json['type'];
      if (type is! String) {
        return const AllianceSuggestion();
      }

      final normalized = type.toLowerCase().trim();
      if (normalized == 'red' || normalized == 'blue' || normalized == 'full') {
        return AllianceSuggestion(side: normalized);
      }

      return const AllianceSuggestion();
    } catch (_) {
      return const AllianceSuggestion();
    }
  }
}
