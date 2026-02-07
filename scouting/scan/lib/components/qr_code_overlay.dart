import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'QR Code Detected',
                    style: GoogleFonts.orbitron(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                barcode?.rawValue ?? 'Unknown',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              if (barcode?.format != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Format: ${barcode!.format.name}',
                  style: GoogleFonts.orbitron(
                    color: Colors.white70,
                    fontSize: 10,
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
