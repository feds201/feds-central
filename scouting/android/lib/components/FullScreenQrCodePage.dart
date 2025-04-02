import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class FullScreenQrCodePage extends StatelessWidget {
  final String data;

  const FullScreenQrCodePage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Full Screen QR Code'),
      ),
      body: Center(
        child: QrImageView(
          data: data,
          version: QrVersions.auto,
          size: MediaQuery.of(context).size.width * 0.9,
          gapless: false,
          
        ),
      ),
    );
  }
}