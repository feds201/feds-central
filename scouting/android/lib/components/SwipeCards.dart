import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:scouting_app/components/CommentBox.dart';

class MatchCard extends StatelessWidget {
  final Color colors;
  final String matchNumber;
  final String teamNumber;
  final String eventName;
  final String matchKey;
  final String matchData;

  MatchCard({
    required this.colors,
    required this.matchNumber,
    required this.teamNumber,
    required this.eventName,
    required this.matchKey,
    required this.matchData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors,
        borderRadius: BorderRadius.circular(20),
        shape: BoxShape.rectangle,
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildComments(
              "Qualification Match : ${matchNumber}",
              [
                buildCommentsBox("Event Key", eventName,
                    const Icon(Icons.location_on_outlined), (String value) {}),
                buildCommentsBox("Team Number", teamNumber,
                    const Icon(Icons.people), (String value) {}),
                buildCommentsBox("Match Key", matchKey,
                    const Icon(Icons.contact_mail_sharp), (String value) {}),
              ],
              const Icon(Icons.refresh_outlined)),
          buildComments(
              "QR Code",
              [
                Center(
                  child: QrImageView(
                    data: matchData,
                    version: QrVersions.auto,
                    size: 270,
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
                ),
              ],
              const Icon(Icons.qr_code_2_sharp)),
        ],
      ),
    );
  }
}
