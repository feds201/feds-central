/// Resolves the TBA API key from available sources.
///
/// Priority: AppSettings override > hardcoded default.
class TbaConfig {
  TbaConfig._();

  // Read-only key for public TBA data — safe to commit.
  static const String defaultApiKey =
      'nfgL68cGRgoKXYWT0D4JcGxv6lPYuWkWVz4TcYPN9VlFQ6vHoLrQjJRwjFKRcJu8';

  /// Resolves the effective API key given an optional settings override.
  static String resolveApiKey(String? settingsOverride) {
    if (settingsOverride != null && settingsOverride.isNotEmpty) {
      return settingsOverride;
    }
    return defaultApiKey;
  }
}
