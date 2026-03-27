import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../data/models.dart';
import '../import/import_pipeline.dart';
import '../util/constants.dart';
import '../util/format.dart';

class ImportPreviewRowWidget extends StatelessWidget {
  final ImportPreviewRow row;
  final int rowIndex;
  final List<Match> allMatches;
  final DataStore dataStore;
  final void Function(String? matchKey) onMatchChanged;
  final void Function(String side) onAllianceSideChanged;
  final void Function(bool selected) onSelectionChanged;
  final void Function(List<int> teams) onTeamsChanged;
  final void Function(String? eventKey)? onEventChanged;
  final bool showEventSelector;
  final VoidCallback? onPlayPreview;

  const ImportPreviewRowWidget({
    super.key,
    required this.row,
    required this.rowIndex,
    required this.allMatches,
    required this.dataStore,
    required this.onMatchChanged,
    required this.onAllianceSideChanged,
    required this.onSelectionChanged,
    required this.onTeamsChanged,
    this.onEventChanged,
    this.showEventSelector = false,
    this.onPlayPreview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighlighted = row.requiresManualMatch;
    final isDisabled = row.matchKey == null && !row.isAutoSkipped;

    return Container(
      decoration: BoxDecoration(
        color: isHighlighted
            ? Colors.amber.withValues(alpha: 0.1)
            : null,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
          left: BorderSide(
            color: AppColors.colorForAllianceSide(row.allianceSide),
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            // Selection checkbox
            Checkbox(
              value: row.isSelected,
              onChanged: isDisabled
                  ? null
                  : (value) => onSelectionChanged(value ?? false),
            ),

            // Video info column
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.metadata.originalFilename,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      if (row.metadata.recordingStartTime != null) ...[
                        Text(
                          formatDateTime(row.metadata.recordingStartTime!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (row.metadata.durationMs != null)
                        Text(
                          _formatDuration(row.metadata.durationMs!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  if (row.isAutoSkipped && row.autoSkipReason != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          row.autoSkipReason == 'Already imported'
                              ? Icons.check_circle
                              : Icons.skip_next,
                          size: 14,
                          color: row.autoSkipReason == 'Already imported'
                              ? Colors.green
                              : theme.colorScheme.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          row.autoSkipReason!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: row.autoSkipReason == 'Already imported'
                                ? Colors.green
                                : theme.colorScheme.error,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  if (isDisabled)
                    Text(
                      'Assign a match to import',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),

            // Play preview button
            if (onPlayPreview != null)
              IconButton(
                icon: const Icon(Icons.play_circle_outline, size: 20),
                onPressed: onPlayPreview,
                tooltip: 'Preview video',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),

            // Event dropdown (only when multiple events)
            if (showEventSelector)
              SizedBox(
                width: 80,
                child: _buildEventDropdown(context),
              ),

            // Match dropdown (filtered by selected event when multiple events)
            Expanded(
              flex: 1,
              child: _buildMatchDropdown(context),
            ),

            // Team numbers
            Expanded(
              flex: 2,
              child: _buildTeamChips(context),
            ),

            // Alliance side toggle
            _buildAllianceToggle(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDropdown(BuildContext context) {
    final eventKeys = dataStore.settings.selectedEventKeys;
    final eventNameMap = <String, String>{};
    for (final e in dataStore.events) {
      eventNameMap[e.eventKey] = e.shortName;
    }

    return DropdownButton<String>(
      value: row.eventKey,
      isExpanded: true,
      isDense: true,
      hint: const Text('Event', style: TextStyle(fontSize: 11)),
      style: TextStyle(
        fontSize: 11,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      items: eventKeys.map((eventKey) {
        return DropdownMenuItem<String>(
          value: eventKey,
          child: Text(
            eventNameMap[eventKey] ?? eventKey,
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onEventChanged,
    );
  }

  Widget _buildMatchDropdown(BuildContext context) {
    final yourTeamNumber = dataStore.settings.teamNumber;
    final yourTeamKey =
        yourTeamNumber != null ? 'frc$yourTeamNumber' : null;

    // Filter matches by the row's event when multiple events are selected
    final filteredMatches = row.eventKey != null && showEventSelector
        ? allMatches.where((m) => m.eventKey == row.eventKey).toList()
        : allMatches;

    // If the current matchKey isn't in the filtered list, it means the event
    // changed — the match dropdown value will be null (no selection).
    final currentMatchKey = filteredMatches.any((m) => m.matchKey == row.matchKey)
        ? row.matchKey
        : null;

    return DropdownButton<String>(
      value: currentMatchKey,
      isExpanded: true,
      isDense: true,
      hint: const Text('Match', style: TextStyle(fontSize: 12)),
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('None', style: TextStyle(fontSize: 12)),
        ),
        ...filteredMatches.map((match) {
          final isOurMatch = yourTeamKey != null &&
              (match.redTeamKeys.contains(yourTeamKey) ||
                  match.blueTeamKeys.contains(yourTeamKey));
          final label = isOurMatch
              ? '\u2605 ${match.displayName}'
              : match.displayName;
          return DropdownMenuItem<String>(
            value: match.matchKey,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isOurMatch ? FontWeight.bold : null,
                color: isOurMatch
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          );
        }),
      ],
      onChanged: onMatchChanged,
    );
  }

  Widget _buildTeamChips(BuildContext context) {
    final theme = Theme.of(context);
    final allianceColor = AppColors.colorForAllianceSide(row.allianceSide);
    final eventKeys = dataStore.settings.selectedEventKeys;
    final alliances = dataStore.getAlliancesForEvents(eventKeys);

    // Build team chip widgets, adding extra space between red and blue
    // teams when in full-field mode (first 3 = red, last 3 = blue).
    final teamWidgets = <Widget>[];
    for (int i = 0; i < row.teams.length; i++) {
      if (row.allianceSide == 'full' && i == 3) {
        teamWidgets.add(const SizedBox(width: 8));
      }
      final team = row.teams[i];
      final color = row.allianceSide == 'full'
          ? (i < 3 ? AppColors.redAlliance : AppColors.blueAlliance)
          : allianceColor;
      teamWidgets.add(Text(
        team > 0 ? '$team' : '---',
        style: theme.textTheme.bodySmall?.copyWith(
          color: team > 0 ? color : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ));
    }

    return InkWell(
      onTap: alliances.isNotEmpty
          ? () => _showAlliancePicker(context, alliances)
          : null,
      child: Wrap(
        spacing: 4,
        children: teamWidgets,
      ),
    );
  }

  void _showAlliancePicker(
      BuildContext context, List<Alliance> alliances) {
    showDialog(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Pick Alliance'),
          children: alliances.map((alliance) {
            final teamNumbers = alliance.picks
                .map((key) => int.tryParse(key.replaceFirst('frc', '')) ?? 0)
                .toList();
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                onTeamsChanged(teamNumbers);
              },
              child: Text(
                '${alliance.name}: ${teamNumbers.join(", ")}',
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAllianceToggle(BuildContext context) {
    // Cycle: red → blue → full → red
    final nextSide = row.allianceSide == 'red'
        ? 'blue'
        : row.allianceSide == 'blue'
            ? 'full'
            : 'red';
    final color = AppColors.colorForAllianceSide(row.allianceSide);

    return InkWell(
      onTap: () => onAllianceSideChanged(nextSide),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color),
        ),
        child: Text(
          row.allianceSide.toUpperCase(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  String _formatDuration(int durationMs) {
    final seconds = durationMs ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }
}
