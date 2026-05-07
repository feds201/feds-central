import 'package:flutter/material.dart';

import '../data/models.dart';

class TeamTile extends StatelessWidget {
  final Team team;
  final bool isYourTeam;
  final String? eventSubtitle;
  final VoidCallback? onTap;

  const TeamTile({
    super.key,
    required this.team,
    this.isYourTeam = false,
    this.eventSubtitle,
    this.onTap,
  });

  Widget? _buildSubtitle(ThemeData theme) {
    final hasNickname = team.nickname.isNotEmpty;
    final hasEvents = eventSubtitle != null;
    if (!hasNickname && !hasEvents) return null;

    if (!hasEvents) return Text(team.nickname);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasNickname) Text(team.nickname),
        Text(
          eventSubtitle!,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: isYourTeam
          ? BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 3,
                ),
              ),
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
            )
          : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isYourTeam
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          child: Text(
            '${team.teamNumber}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isYourTeam
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
        title: Text(
          '${team.teamNumber}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: _buildSubtitle(theme),
        onTap: onTap,
      ),
    );
  }
}
