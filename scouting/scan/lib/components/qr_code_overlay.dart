import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRCodeOverlay extends StatelessWidget {
  final Barcode? barcode;
  final VoidCallback? onTap;

  const QRCodeOverlay({
    super.key,
    this.barcode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (barcode == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.tertiary, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: theme.colorScheme.tertiary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'QR Code Detected',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                barcode?.rawValue ?? 'Unknown',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (barcode?.format != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Format: ${barcode!.format.name}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
