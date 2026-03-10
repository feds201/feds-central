import 'package:flutter/material.dart';

class ScoutHeader extends StatelessWidget {
  const ScoutHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 100, // Increased height to account for status bar area
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top:
              40.0, // Add top padding to push content down from status bar area
          bottom: 16.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Red status indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                shape: BoxShape.circle,
              ),
            ),

            // Title
            Text(
              'SCOUT OPS DATA',
              style: theme.textTheme.titleLarge?.copyWith(
                letterSpacing: 1.5,
              ),
            ),

            // Spacer for alignment
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
