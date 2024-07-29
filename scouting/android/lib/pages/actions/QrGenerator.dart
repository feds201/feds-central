import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:scouting_app/pages/home_page.dart';
import 'package:slider_button/slider_button.dart';

import '../components/DataBase.dart';

class Qrgenerator extends StatefulWidget {
  const Qrgenerator({Key? key}) : super(key: key);

  @override
  QrCoder createState() => QrCoder();
}

class QrCoder extends State<Qrgenerator> {
  final LocalDataBase dataMaster = LocalDataBase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            QrImageView(
              data: LocalDataBase.getMatchData(),
              version: QrVersions.auto,
              size: 350,
              semanticsLabel: 'QR code',
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.circle,
                color: Colors.red,
              ),
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
            Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 40, left: 8, right: 8),
              child: Container(
                width: MediaQuery.of(context).size.width - 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SliderButton(
                  buttonColor: Colors.yellow,
                  backgroundColor: Colors.white,
                  highlightedColor: Colors.green,
                  buttonSize: 70,
                  dismissThresholds: 0.97,
                  vibrationFlag: true,
                  width: MediaQuery.of(context).size.width - 40,
                  action: () async {
                    //save the QRImage locally
                    MatchLogs.addLog(LocalDataBase.getMatchData());
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                    );
                  },
                  label: const Text(
                    "Slide to Scout Next Match",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 17,
                    ),
                    textAlign: TextAlign.start,
                  ),
                  icon: const Icon(
                    Icons.send_outlined,
                    size: 30,
                    color: Colors.black,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

