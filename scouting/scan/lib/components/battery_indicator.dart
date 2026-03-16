import 'package:flutter/material.dart';

class BatteryIndicator extends StatelessWidget {
  final int percentage;
  final String label;
  final Color? color;

  const BatteryIndicator({
    super.key,
    required this.percentage,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color batteryColor = color ?? _getBatteryColor(percentage, theme);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$percentage%',
            style: theme.textTheme.titleLarge?.copyWith(
              color: batteryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Color _getBatteryColor(int percentage, ThemeData theme) {
    if (percentage >= 80) return theme.colorScheme.primary;
    if (percentage >= 50) return theme.colorScheme.secondary;
    if (percentage >= 20) return theme.colorScheme.tertiary;
    return theme.colorScheme.error;
  }
}
