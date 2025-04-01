import 'package:flutter/material.dart';
import 'package:scouting_app/main.dart';
import 'package:scouting_app/services/Colors.dart';

class MatchInfo extends StatelessWidget {
  final String assignedTeam;
  final int assignedStation;
  final String allianceColor;
  final VoidCallback onPressed;

  const MatchInfo({
    super.key,
    required this.assignedTeam,
    required this.assignedStation,
    required this.allianceColor,
    required this.onPressed,
  });

  // Convert this widget to a map for saving
  Map<String, dynamic> toJson() {
    return {
      'assignedTeam': assignedTeam,
      'assignedStation': assignedStation,
      'allianceColor': allianceColor,
    };
  }

  // Create a widget from a map
  factory MatchInfo.fromJson(
      Map<String, dynamic> json, VoidCallback onPressed) {
    return MatchInfo(
      assignedTeam: json['assignedTeam'],
      assignedStation: json['assignedStation'],
      allianceColor: json['allianceColor'],
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 100, // Set minimum width
          minHeight: 50, // Set minimum height
        ),
        decoration: BoxDecoration(
          color: islightmode() ? Colors.white : Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: islightmode()
                  ? Colors.grey.withOpacity(0.2)
                  : const Color.fromARGB(255, 45, 44, 44).withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.category,
                  color: Colors.grey,
                  size: 40,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignedTeam,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: islightmode() ? Colors.black : Colors.white,
                    ),
                  ),
                  Text(
                    '$allianceColor Alliance, Station $assignedStation',
                    style: TextStyle(
                      fontSize: 16,
                      color: islightmode() ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // ElevatedButton(
              //   onPressed: onPressed,
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.deepPurple,
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(30.0),
              //     ),
              //     padding:
              //         const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              //   ),
              //   child: const Text(
              //     'START',
              //     style: TextStyle(
              //       color: Colors.white,
              //       fontSize: 16,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class TeamInfo extends StatelessWidget {
  final int teamNumber;
  final String nickname;
  final String? city;
  final String? stateProv;
  final String? country;
  final String? website;

  const TeamInfo({
    super.key,
    required this.teamNumber,
    required this.nickname,
    this.city,
    this.stateProv,
    this.country,
    this.website,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        elevation: 8,
        shadowColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.engineering,
                      size: 32, color: Colors.blueAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Team $teamNumber: $nickname',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 2),
              if (city != null || stateProv != null || country != null)
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 20, color: Colors.redAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${city ?? ''}${city != null && stateProv != null ? ', ' : ''}${stateProv ?? ''}${(city != null || stateProv != null) && country != null ? ', ' : ''}${country ?? ''}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              if (website != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.link, size: 20, color: Colors.green),
                      const SizedBox(width: 6),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            // Launch website
                          },
                          child: Text(
                            website!,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
