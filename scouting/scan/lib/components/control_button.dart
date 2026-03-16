import 'package:flutter/material.dart';

class ControlButton extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onPressed;
  final double? width;

  const ControlButton({
    super.key,
    required this.text,
    required this.backgroundColor,
    this.textColor = Colors.white,
    this.onPressed,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width ?? 80,
      height: 40,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: theme.textTheme.labelLarge,
        ),
        child: Text(
          text,
        ),
      ),
    );
  }
}
