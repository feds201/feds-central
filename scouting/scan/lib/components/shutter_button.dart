import 'package:flutter/material.dart';

class ShutterButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;

  const ShutterButton({
    super.key,
    this.onPressed,
    this.size = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.primary,
          border: Border.all(
            color: theme.colorScheme.onSurface,
            width: 4,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
