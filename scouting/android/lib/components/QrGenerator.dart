import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:scout_ops_android/components/slider.dart';
import 'package:scout_ops_android/main.dart';

import '../Match_Pages/match_page.dart';
import '../Plugins/plugin_state_manager.dart';
import '../services/DataBase.dart';

String compressToBase64(String data) {
  final bytes = utf8.encode(data);
  final compressed = GZipEncoder().encode(bytes);
  if (compressed == null) return data;
  return base64.encode(compressed);
}

String decompressFromBase64(String encoded) {
  final bytes = base64.decode(encoded);
  final decompressed = GZipDecoder().decodeBytes(bytes);
  return utf8.decode(decompressed);
}

class Qrgenerator extends StatefulWidget {
  final MatchRecord matchRecord;
  const Qrgenerator({super.key, required this.matchRecord});

  @override
  QrCoder createState() => QrCoder();
}

class QrCoder extends State<Qrgenerator> {
  final PluginStateManager pluginStateManager = PluginStateManager();
  @override
  Widget build(BuildContext context) {
    final qrData = compressToBase64(widget.matchRecord.toCsv());
    print('Raw CSV length: ${widget.matchRecord.toCsv().length} chars');
    print('Compressed length: ${qrData.length} chars');
    // bool isJson = Hive.box('settings').get('isJson');
    // log('Building QR Code with isJson: $isJson');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: islightmode() ? Colors.white : Colors.black,
        title: Text('QR Code',
            style: GoogleFonts.museoModerno(
              fontSize: 25,
              color: islightmode() ? Colors.black : Colors.white,
            )),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            QrImageView(
              backgroundColor: Colors.white,
              data: qrData,
              // data: json.encode(widget.matchRecord.toJson()),
              version: QrVersions.auto,
              size: MediaQuery.of(context).size.width - 40,
              semanticsLabel: 'QR code',
              // eyeStyle: const QrEyeStyle(
              //   eyeShape: QrEyeShape.square,
              //   color: Colors.white,
              // ),
              gapless: false,
              // dataModuleStyle: const QrDataModuleStyle(
              //   dataModuleShape: QrDataModuleShape.square,
              //   color: Colors.white,
              // ),
            ),
            const SizedBox(
              height: 30.0,
            ),
            Text(
              'Scan the QR code to submit the data',
              style: TextStyle(
                  fontSize: 20.0,
                  color: islightmode() ? Colors.black : Colors.white),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 40, left: 8, right: 8),
              child: Container(
                width: MediaQuery.of(context).size.width - 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: islightmode()
                          ? const Color.fromARGB(255, 248, 248, 248)
                          : const Color.fromARGB(255, 255, 255, 255)
                              .withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SliderButton(
                  buttonColor: const Color(0xFFFFD700), // Golden color
                  backgroundColor: islightmode()
                      ? const Color.fromARGB(255, 255, 255, 255)
                      : const Color.fromARGB(255, 34, 34, 34),
                  highlightedColor: Colors.red,
                  buttonSize: 70,
                  dismissThresholds: 0.97,
                  vibrationFlag: true,
                  width: MediaQuery.of(context).size.width - 40,
                  action: () async {
                    await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const SavingProgressDialog());

                    // Save to local database
                    MatchDataBase.PutData(
                        widget.matchRecord.matchKey, widget.matchRecord);
                    MatchDataBase.SaveAll();

                    await InititiateTransactions(widget.matchRecord.toString());
                    return true;
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

  Future<void> InititiateTransactions(String qrData) async {
    // Navigation back to MatchPage to allow scouting the next match
    await Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (context) => const MatchPage(), fullscreenDialog: true),
      (Route<dynamic> route) => false,
    );
  }
}

class SavingProgressDialog extends StatefulWidget {
  const SavingProgressDialog({super.key});

  @override
  State<SavingProgressDialog> createState() => _SavingProgressDialogState();
}

class _SavingProgressDialogState extends State<SavingProgressDialog> {
  double _progress = 0.0;
  String _message = "Saving everything...";

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _progress = 0.33;
        _message = "Logging match...";
      });
    }
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() {
        _progress = 0.66;
        _message = "Getting ready for next match...";
      });
    }
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _progress = 1.0;
      });
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: islightmode() ? Colors.white : Colors.black,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: _progress,
            color: const Color(0xFFFFD700),
            backgroundColor:
                islightmode() ? Colors.grey[200] : Colors.grey[800],
          ),
          const SizedBox(height: 20),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: GoogleFonts.museoModerno(
                fontSize: 18.0,
                color: islightmode() ? Colors.black : Colors.white),
          ),
        ],
      ),
    );
  }
}
