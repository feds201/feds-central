import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Resolves the TBA API key from available sources.
///
/// Priority: AppSettings override > .env file > null (no key available).
class TbaConfig {
  TbaConfig._();

  static bool _dotenvLoaded = false;

  /// Load .env file. Safe to call multiple times.
  static Future<void> loadDotenv() async {
    if (_dotenvLoaded) return;
    try {
      await dotenv.load(fileName: '.env');
      _dotenvLoaded = true;
    } catch (_) {
      // .env file missing or unreadable — that's fine, user can set key in settings
    }
  }

  /// Returns the API key from the .env file, or null if not available.
  static String? get dotenvApiKey {
    if (!_dotenvLoaded) return null;
    final key = dotenv.maybeGet('TBA_API_KEY');
    if (key == null || key.isEmpty || key == 'your_tba_api_key_here') {
      return null;
    }
    return key;
  }

  /// Resolves the effective API key given an optional settings override.
  /// Returns null if no key is available from any source.
  static String? resolveApiKey(String? settingsOverride) {
    // Non-empty settings override takes priority
    if (settingsOverride != null && settingsOverride.isNotEmpty) {
      return settingsOverride;
    }
    // Fall back to .env
    return dotenvApiKey;
  }
}
