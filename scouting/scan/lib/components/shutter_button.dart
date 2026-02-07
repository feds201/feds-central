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
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFF2C2C2C),
            width: 4,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFE0E0E0),
          ),
        ),
      ),
    );
  }
}
