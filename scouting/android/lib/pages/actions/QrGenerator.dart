
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';


class Qrgenerator extends StatefulWidget {
  final Map<String, dynamic> ScoutData;

  const Qrgenerator(
      {Key? key,
        required this.ScoutData,}) : super(key: key);

  @override
  QrCoder createState() => QrCoder();
}

class QrCoder extends State<Qrgenerator> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            QrImageView(
              data: 'This is a simple QR code',
              version: QrVersions.auto,
              size: 320,
              semanticsLabel: 'QR code',
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.circle,
                color: Colors.red,
              ),
              // embeddedImage: const AssetImage('assets/logo__.png'),
              // embeddedImageStyle: const QrEmbeddedImageStyle(
              //   size: Size(80, 80),
              // ),
              gapless: false,
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: Colors.blue,
                ),
            ),
            const SizedBox(
              height: 20.0,
            ),
            const Text(
              'Scan the QR code to submit the data',
              style: TextStyle(fontSize: 20.0),
            ),
          ],
        ),
      ),
    );
  }
}