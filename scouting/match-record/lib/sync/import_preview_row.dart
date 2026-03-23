import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../data/models.dart';
import '../import/import_pipeline.dart';

class ImportPreviewRowWidget extends StatelessWidget {
  final ImportPreviewRow row;
  final int rowIndex;
  final List<Match> allMatches;
  final DataStore dataStore;
  final void Function(String? matchKey) onMatchChanged;
  final void Function(String side) onAllianceSideChanged;
  final void Function(bool selected) onSelectionChanged;
  final void Function(List<int> teams) onTeamsChanged;

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
            color: row.allianceSide == 'red' ? Colors.red : Colors.blue,
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
                          _formatTime(row.metadata.recordingStartTime!),
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

            // Match dropdown
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

  Widget _buildMatchDropdown(BuildContext context) {
    return DropdownButton<String>(
      value: row.matchKey,
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
        ...allMatches.map((match) {
          return DropdownMenuItem<String>(
            value: match.matchKey,
            child: Text(match.displayName, style: const TextStyle(fontSize: 12)),
          );
        }),
      ],
      onChanged: onMatchChanged,
    );
  }

  Widget _buildTeamChips(BuildContext context) {
    final theme = Theme.of(context);
    final allianceColor = row.allianceSide == 'red' ? Colors.red : Colors.blue;
    final eventKeys = dataStore.settings.selectedEventKeys;
    final alliances = dataStore.getAlliancesForEvents(eventKeys);

    return InkWell(
      onTap: alliances.isNotEmpty
          ? () => _showAlliancePicker(context, alliances)
          : null,
      child: Wrap(
        spacing: 4,
        children: row.teams.map((team) {
          return Text(
            team > 0 ? '$team' : '---',
            style: theme.textTheme.bodySmall?.copyWith(
              color: team > 0 ? allianceColor : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          );
        }).toList(),
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
    return InkWell(
      onTap: () {
        onAllianceSideChanged(
          row.allianceSide == 'red' ? 'blue' : 'red',
        );
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (row.allianceSide == 'red' ? Colors.red : Colors.blue)
              .withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: row.allianceSide == 'red' ? Colors.red : Colors.blue,
          ),
        ),
        child: Text(
          row.allianceSide.toUpperCase(),
          style: TextStyle(
            color: row.allianceSide == 'red' ? Colors.red : Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${time.minute.toString().padLeft(2, '0')} $amPm';
  }

  String _formatDuration(int durationMs) {
    final seconds = durationMs ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }
}
