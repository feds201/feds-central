import 'dart:convert';

/// Represents a single named auto route parsed from the `pathdraw` column.
///
/// The `pathdraw` column contains a JSON array like:
/// ```json
/// [
///   {"name": "left",   "path": "M0.351,0.336C...|0.00:0,0.00:234,..."},
///   {"name": "center", "path": "M0.335,0.375C...|0.00:0,0.00:541,..."}
/// ]
/// ```
class AutoRoute {
  final String name;
  final String pathData;

  AutoRoute({required this.name, required this.pathData});

  String displayName(int index) {
    if (name.trim().isEmpty) return 'Route ${index + 1}';
    return name[0].toUpperCase() + name.substring(1);
  }
}

/// Parse the `pathdraw` column value into a list of [AutoRoute]s.
///
/// Handles both a raw JSON string and an already-decoded [List] (which is
/// what Neon returns for `jsonb` columns).
List<AutoRoute> parsePathDraw(dynamic raw) {
  if (raw == null) return [];

  List<dynamic> decoded;

  if (raw is List) {
    decoded = raw;
  } else {
    String jsonStr = raw is String ? raw.trim() : raw.toString().trim();
    if (jsonStr.isEmpty || jsonStr == '[]') return [];
    try {
      final result = jsonDecode(jsonStr);
      if (result is! List) return [];
      decoded = result;
    } catch (_) {
      if (jsonStr.contains('M') && jsonStr.contains('|')) {
        return [AutoRoute(name: '', pathData: jsonStr)];
      }
      return [];
    }
  }

  return decoded.map<AutoRoute?>((item) {
    if (item is! Map) return null;
    final name = (item['name'] ?? '').toString();
    final path = (item['path'] ?? '').toString();
    if (path.isEmpty) return null;
    return AutoRoute(name: name, pathData: path);
  }).whereType<AutoRoute>().toList();
}
