import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scouting_app/main.dart';

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
    bool isRed = allianceColor.toLowerCase().contains('red');
    Color baseColor = isRed ? const Color(0xFFE0643B) : const Color(0xFF3B9AE0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: islightmode()
                ? [baseColor.withOpacity(0.95), baseColor.withOpacity(0.8)]
                : [baseColor.withOpacity(0.8), baseColor.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onPressed, // Use the callback just in case
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
              child: Row(
                children: [
                  // Team Number Container
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      assignedTeam,
                      style: GoogleFonts.museoModerno(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Info Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alliance Station',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              allianceColor,
                              style: GoogleFonts.museoModerno(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$assignedStation',
                                style: GoogleFonts.museoModerno(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: baseColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        assignedTeam, // Placeholder for team logo
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: baseColor,
                        ),
                      ),
                    ),
                    // If you have image urls, you can use:
                    // child: ClipOval(
                    //   child: Image.network(imageUrl, fit: BoxFit.cover),
                    // ),
                  ),
                ],
              ),
            ),
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
        color: islightmode() ? Colors.white : const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
          side: BorderSide(
            color: islightmode()
                ? Colors.grey.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(islightmode() ? 0.1 : 0.4),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.engineering,
                        size: 28, color: Colors.blueAccent),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Team $teamNumber',
                          style: GoogleFonts.museoModerno(
                            fontSize: 16,
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          nickname,
                          style: GoogleFonts.roboto(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color:
                                islightmode() ? Colors.black87 : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(height: 1),
              ),
              if (city != null || stateProv != null || country != null)
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 20,
                      color: Colors.redAccent.withOpacity(0.8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${city ?? ''}${city != null && stateProv != null ? ', ' : ''}${stateProv ?? ''}${(city != null || stateProv != null) && country != null ? ', ' : ''}${country ?? ''}',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: islightmode()
                              ? Colors.grey[700]
                              : Colors.grey[300],
                        ),
                      ),
                    ),
                  ],
                ),
              if (website != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Row(
                    children: [
                      Icon(Icons.link,
                          size: 20, color: Colors.green.withOpacity(0.8)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            // Launch website
                          },
                          child: Text(
                            website!,
                            style: GoogleFonts.roboto(
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
