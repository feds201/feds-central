
/// Parses a pit scouting CSV string into a list of row maps.
///
/// Handles the quoted-CSV format from the Neon export, including
/// doubled-up quotes inside fields (e.g. `""name""` → `"name"`).
class CsvLoader {
  /// Parse [csvText] and return a list of column-name → value maps.
  static List<Map<String, dynamic>> parse(String csvText) {
    final lines = _splitLines(csvText);
    if (lines.length < 2) return [];

    final headers = _parseLine(lines[0]);
    final rows = <Map<String, dynamic>>[];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final values = _parseLine(line);
      final map = <String, dynamic>{};
      for (int j = 0; j < headers.length; j++) {
        final key = headers[j];
        final val = j < values.length ? values[j] : '';
        // Try to parse as number.
        final intVal = int.tryParse(val);
        final doubleVal = double.tryParse(val);
        if (intVal != null) {
          map[key] = intVal;
        } else if (doubleVal != null) {
          map[key] = doubleVal;
        } else {
          map[key] = val;
        }
      }
      rows.add(map);
    }

    return rows;
  }

  /// Extract column names from CSV text.
  static List<String> columns(String csvText) {
    final lines = _splitLines(csvText);
    if (lines.isEmpty) return [];
    return _parseLine(lines[0]);
  }

  // ── Internal CSV parsing ───────────────────────────────────────────

  /// Split text into lines, handling \r\n and \n.
  static List<String> _splitLines(String text) {
    // Can't just split on \n because fields may contain newlines inside quotes.
    // For our pit scouting data, each row is on one line, so simple split works.
    return text
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty)
        .toList();
  }

  /// Parse a single CSV line into field values, handling quoted fields.
  static List<String> _parseLine(String line) {
    final fields = <String>[];
    int i = 0;

    while (i < line.length) {
      if (line[i] == '"') {
        // Quoted field.
        i++; // skip opening quote
        final buf = StringBuffer();
        while (i < line.length) {
          if (line[i] == '"') {
            if (i + 1 < line.length && line[i + 1] == '"') {
              buf.write('"');
              i += 2;
            } else {
              i++; // skip closing quote
              break;
            }
          } else {
            buf.write(line[i]);
            i++;
          }
        }
        fields.add(buf.toString());
        // Skip comma after closing quote.
        if (i < line.length && line[i] == ',') i++;
      } else {
        // Unquoted field.
        final commaIdx = line.indexOf(',', i);
        if (commaIdx == -1) {
          fields.add(line.substring(i));
          break;
        } else {
          fields.add(line.substring(i, commaIdx));
          i = commaIdx + 1;
        }
      }
    }

    return fields;
  }
}
