import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../data/models.dart';
import '../tba/tba_config.dart';

/// Returns the warning message to show, or null if everything is fine.
///
/// Tier order (highest priority first):
///   1. No events selected.
///   2. Events selected, but the TBA client has no API key (override blank
///      AND default fallback empty).
///   3. Events + key, but no matches for the selected events.
String? resolveTbaWarning(AppSettings settings, List<Match> matchesForEvents) {
  if (settings.selectedEventKeys.isEmpty) {
    return 'No events selected. Please enter an event in settings.';
  }
  if (TbaConfig.resolveApiKey(settings.tbaApiKey).isEmpty) {
    return 'No Blue Alliance API key available. Please enter one in settings.';
  }
  if (matchesForEvents.isEmpty) {
    return 'No data from The Blue Alliance for the selected event(s). '
        'Please connect to Wi-Fi to fetch data.';
  }
  return null;
}

/// Schedules a post-frame check and shows a SnackBar if a warning applies.
/// Safe to call from `initState`.
void showTbaStatusWarningIfNeeded(BuildContext context, DataStore dataStore) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    final settings = dataStore.settings;
    final matches = dataStore.getMatchesForEvents(settings.selectedEventKeys);
    final message = resolveTbaWarning(settings, matches);
    if (message == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 6),
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  });
}
