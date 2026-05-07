import 'package:flutter/material.dart';

class UsbInstructionsTab extends StatelessWidget {
  const UsbInstructionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.usb, color: colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'How to transfer match videos from other devices to here using USB drives',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final isLandscape = MediaQuery.of(context).orientation ==
                  Orientation.landscape;
              final androidCard = _PlatformCard(
                icon: Icons.android,
                iconColor: const Color(0xFF3DDC84),
                platform: 'Android',
                steps: const [
                  _Step('Plug in USB drive into the phone'),
                  _Step('Go to Files app'),
                  _Step(
                    'Navigate to: Internal Storage > DCIM > Camera',
                    tip: 'Sort by newest to oldest to find recent videos faster',
                  ),
                  _Step('Select all videos you want'),
                  _Step(
                    'Tap top-right menu > Move to > select the USB drive (e.g. "Disk 20")',
                    note:
                        'Android sometimes shows the default USB name instead of our custom label',
                  ),
                  _Step(
                    'Wait for LED on USB to stop flashing (should be solid red)',
                    isFinishStep: true,
                  ),
                ],
              );
              final iosCard = _PlatformCard(
                icon: Icons.phone_iphone,
                iconColor: Colors.grey,
                platform: 'iOS',
                steps: const [
                  _Step('Plug in USB drive into the phone'),
                  _Step('Open camera gallery'),
                  _Step('Select all videos you want'),
                  _Step('Tap "Save to Files"'),
                  _Step(
                    'Hit back until at top level',
                    tip: 'You\'ll know you\'re at the top level when the back button becomes an X',
                  ),
                  _Step(
                    'Tap the USB drive under "Locations" section (e.g. "FEDS-red")',
                  ),
                  _Step('Tap Save'),
                  _Step(
                    'Wait for LED on USB to stop flashing (should be solid red)',
                    isFinishStep: true,
                  ),
                ],
              );

              if (isLandscape) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: androidCard),
                      const SizedBox(width: 12),
                      Expanded(child: iosCard),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  androidCard,
                  const SizedBox(height: 12),
                  iosCard,
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Step {
  final String text;
  final String? tip;
  final String? note;
  final bool isFinishStep;

  const _Step(this.text, {this.tip, this.note, this.isFinishStep = false});
}

class _PlatformCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String platform;
  final List<_Step> steps;

  const _PlatformCard({
    required this.icon,
    required this.iconColor,
    required this.platform,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 10),
                Text(
                  platform,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < steps.length; i++) ...[
              _StepRow(
                number: i + 1,
                step: steps[i],
                colorScheme: colorScheme,
                textTheme: theme.textTheme,
              ),
              if (i < steps.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final _Step step;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _StepRow({
    required this.number,
    required this.step,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (step.isFinishStep)
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.usb,
                  size: 16,
                  color: colorScheme.onTertiaryContainer,
                ),
              )
            else
              CircleAvatar(
                radius: 14,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  '$number',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  step.text,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        step.isFinishStep ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (step.tip != null)
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: colorScheme.tertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tip: ${step.tip}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (step.note != null)
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: colorScheme.tertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Note: ${step.note}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
