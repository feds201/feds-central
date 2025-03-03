import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:scouting_app/components/CommentBox.dart';

import 'FullScreenQrCodePage.dart';
import 'compactifier.dart';

class MatchCard extends StatelessWidget {
  final String matchData;
  final String eventName;
  final String teamNumber;
  final String matchKey;
  final String allianceColor;
  final String selectedStation;

  const MatchCard({
    super.key,
    required this.matchData,
    required this.eventName,
    required this.teamNumber,
    required this.matchKey,
    required this.allianceColor,
    required this.selectedStation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: allianceColor == "Red" ? Colors.red : Colors.blue,
          // color: Colors.red,
          // Adjust color based on alliance
          borderRadius: BorderRadius.circular(20),
          shape: BoxShape.rectangle,
        ),
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildComments(
                  "Qualification Match", // Use team number here
                  [
                    buildCommentsBox(
                        "Event Key",
                        eventName,
                        const Icon(Icons.location_on_outlined),
                        (String value) {}),
                    buildCommentsBox("Team Number", teamNumber.toString(),
                        const Icon(Icons.people), (String value) {}),
                    buildCommentsBox(
                        "Match Key",
                        matchKey,
                        const Icon(Icons.contact_mail_sharp),
                        (String value) {}),
                    buildCommentsBox(
                        "Alliance Color",
                        allianceColor,
                        const Icon(Icons.connected_tv_sharp),
                        (String value) {}),
                    // Adjust color based on alliance
                    buildCommentsBox("Selected Station", selectedStation,
                        const Icon(Icons.map_outlined), (String value) {}),
                    // ... (Add comments for other data)
                  ],
                  const Icon(Icons.refresh_outlined)),
              buildComments(
                  "QR Code",
                  [
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FullScreenQrCodePage(data: matchData),
                              fullscreenDialog: true,
                            ),
                          );
                        },
                        child: QrImageView(
                          data: jsonEncode(matchData),
                          version: QrVersions.auto,
                          size: 270,
                          gapless: false,
                        ),
                      ),
                    ),
                  ],
                  const Icon(Icons.qr_code_2_sharp)),
            ],
          ),
        ));
  }
}
