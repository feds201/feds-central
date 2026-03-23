import 'package:flutter/material.dart';

import '../data/models.dart';

class AllianceTile extends StatelessWidget {
  final Alliance alliance;
  final bool isYourAlliance;
  final VoidCallback? onTap;

  const AllianceTile({
    super.key,
    required this.alliance,
    this.isYourAlliance = false,
    this.onTap,
  });

  String _formatTeamNumbers() {
    return alliance.picks
        .map((key) => key.replaceFirst('frc', ''))
        .join(' \u00b7 ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isYourAlliance
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        child: Text(
          '${alliance.allianceNumber}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isYourAlliance
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
      title: Text(
        alliance.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(_formatTeamNumbers()),
      trailing: isYourAlliance
          ? Icon(Icons.star, color: theme.colorScheme.primary, size: 20)
          : null,
      onTap: onTap,
    );
  }
}
