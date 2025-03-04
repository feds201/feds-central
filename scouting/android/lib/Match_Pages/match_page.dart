import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:scouting_app/components/MatchSelection.dart';
import 'package:scouting_app/components/ScoutersList.dart';
import 'package:scouting_app/home_page.dart';
import 'match.dart';
import '../services/DataBase.dart';

class MatchPage extends StatefulWidget {
  const MatchPage({super.key});

  @override
  MatchPageState createState() => MatchPageState();
}

class MatchPageState extends State<MatchPage> {
  late int selectedMatchType;

  @override
  void initState() {
    super.initState();
    selectedMatchType = 0;
  }

  @override
  Widget build(BuildContext context) {
    var data = Hive.box('matchData').get('matches');
    if (data == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.red, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              'Match Scouting',
              style: GoogleFonts.museoModerno(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          centerTitle: true,
        ),
        body: Center(child: Text('No match data available.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () async {
              await Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomePage(),
                  fullscreenDialog: true,
                ),
                (Route<dynamic> route) => false,
              );

              print('Navigated back to MatchPage and removed previous pages.');
            },
          ),
        ],
        backgroundColor: Colors.transparent,
        title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.red, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
            child: Text(
              'Match Scouting',
              style: GoogleFonts.museoModerno(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            )),
        centerTitle: true,
      ),
      body: matchSelection(context, selectedMatchType, (int index) {
        setState(() {
          selectedMatchType = index;
        });
      }, jsonEncode(data)),
    );
  }

  Widget matchSelection(BuildContext context, int currentSelectedMatchType,
      Function onMatchTypeSelected, String matchData) {
    return Row(
      children: [
        NavigationRail(
          backgroundColor: Colors.white,
          selectedIndex: currentSelectedMatchType,
          onDestinationSelected: (int index) {
            onMatchTypeSelected(index);
          },
          labelType: NavigationRailLabelType.all,
          destinations: const <NavigationRailDestination>[
            NavigationRailDestination(
              indicatorColor: Colors.white,
              icon: Icon(Icons.sports_soccer),
              label: Text('Quals'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.sports_basketball),
              label: Text('Playoffs'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.sports_rugby),
              label: Text('Finals'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.settings),
              label: Text('Settings'),
            ),
          ],
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: _buildMatchList(currentSelectedMatchType, matchData),
        ),
      ],
    );
  }

  Widget _buildMatchList(int selectedMatchType, String matchData) {
    // Decode the JSON string to a Dart object
    List<dynamic> matches = jsonDecode(matchData);

    switch (selectedMatchType) {
      case 0:
        var filteredMatches = matches
            .where((match) => match['comp_level'] == 'qm')
            .toList()
          ..sort((a, b) => int.parse(a['match_number'].toString())
              .compareTo(int.parse(b['match_number'].toString())));

        return ListView.builder(
          itemCount: filteredMatches.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              title: Text(
                  'Qualification ${filteredMatches[index]['match_number']}'),
              subtitle: const Text('Qualification Match'),
              leading: Icon(Icons.sports_soccer,
                  color: Theme.of(context).colorScheme.primary),
              trailing: Icon(Icons.arrow_forward_ios_rounded,
                  color: Theme.of(context).colorScheme.onSurface),
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              onTap: () {
                // log(filteredMatches[index].toString());
                String _scouterName = Hive.box('settings').get('deviceName');
                String _allianceColor = Hive.box('userData').get('alliance');
                String _station = Hive.box('userData').get('position');
                String teamNNumber = filteredMatches[index]['alliances']
                        [_allianceColor.toLowerCase()]['team_keys']
                    [int.parse(_station) - 1];
                MatchRecord matchRecord = MatchRecord(
                  AutonPoints(0, 0, 0, 0, false, 0, 0),
                  TeleOpPoints(0, 0, 0, 0, 0, 0, false),
                  EndPoints(false, false, false, ""),
                  teamNumber: teamNNumber.split(
                    'frc',
                  )[1],
                  scouterName: _scouterName,
                  matchKey: filteredMatches[index]['key'].toString(),
                  allianceColor: _allianceColor,
                  station: int.parse(_station),
                  matchNumber: filteredMatches[index]['match_number'],
                  eventKey: filteredMatches[index]['event_key'],
                );
                // log(matchRecord.toString());
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Match(
                            matchRecord: matchRecord,
                          ),
                      fullscreenDialog: true),
                ).then((value) => print('Returned to Match Page'));
              },
            );
          },
        );

      case 1:
        var filteredMatches =
            matches.where((match) => match['comp_level'] == 'sf').toList()
              ..sort((a, b) {
                int aValue = a['comp_level'].startsWith('sf')
                    ? int.parse(a['set_number'].toString())
                    : int.parse(a['match_number'].toString());
                int bValue = b['comp_level'].startsWith('sf')
                    ? int.parse(b['set_number'].toString())
                    : int.parse(b['match_number'].toString());
                return aValue.compareTo(bValue);
              });

        return ListView.builder(
          itemCount: filteredMatches.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              title: Text(
                'Match ${filteredMatches[index]['comp_level'].startsWith('sf') ? filteredMatches[index]['set_number'] : filteredMatches[index]['match_number']}',
              ),
              subtitle: const Text('Semifinal Match'),
              leading: Icon(Icons.sports_basketball,
                  color: Theme.of(context).colorScheme.primary),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.onSurface),
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              onTap: () {
                // log(filteredMatches[index].toString());
                String _scouterName = Hive.box('settings').get('deviceName');
                String _allianceColor = Hive.box('userData').get('alliance');
                String _station = Hive.box('userData').get('position');
                String teamNNumber = filteredMatches[index]['alliances']
                        [_allianceColor.toLowerCase()]['team_keys']
                    [int.parse(_station)];
                MatchRecord matchRecord = MatchRecord(
                  AutonPoints(0, 0, 0, 0, false, 0, 0),
                  TeleOpPoints(0, 0, 0, 0, 0, 0, false),
                  EndPoints(false, false, false, ""),
                  teamNumber: teamNNumber.split(
                    'frc',
                  )[1],
                  scouterName: _scouterName,
                  matchKey: filteredMatches[index]['match_number'].toString(),
                  allianceColor: _allianceColor,
                  station: int.parse(_station),
                  matchNumber: filteredMatches[index]['match_number'],
                  eventKey: filteredMatches[index]['event_key'],
                );
                // log(matchRecord.toString());
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Match(
                            matchRecord: matchRecord,
                          ),
                      fullscreenDialog: true),
                ).then((value) => print('Returned to Match Page'));
              },
            );
          },
        );

      case 2:
        var filteredMatches = matches
            .where((match) => match['comp_level'] == 'f')
            .toList()
          ..sort((a, b) => int.parse(a['match_number'].toString())
              .compareTo(int.parse(b['match_number'].toString())));

        return ListView.builder(
          itemCount: filteredMatches.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              title: Text('Match ${filteredMatches[index]['match_number']}'),
              subtitle: const Text('Final Match'),
              leading: Icon(Icons.sports_rugby,
                  color: Theme.of(context).colorScheme.primary),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.onSurface),
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              onTap: () {
                // log(filteredMatches[index].toString());
                String _scouterName = Hive.box('settings').get('deviceName');
                String _allianceColor = Hive.box('userData').get('alliance');
                String _station = Hive.box('userData').get('position');
                String teamNNumber = filteredMatches[index]['alliances']
                        [_allianceColor.toLowerCase()]['team_keys']
                    [int.parse(_station)];
                MatchRecord matchRecord = MatchRecord(
                  AutonPoints(0, 0, 0, 0, false, 0, 0),
                  TeleOpPoints(0, 0, 0, 0, 0, 0, false),
                  EndPoints(false, false, false, ""),
                  teamNumber: teamNNumber.split(
                    'frc',
                  )[1],
                  scouterName: _scouterName,
                  matchKey: filteredMatches[index]['match_number'].toString(),
                  allianceColor: _allianceColor,
                  station: int.parse(_station),
                  matchNumber: filteredMatches[index]['match_number'],
                  eventKey: filteredMatches[index]['event_key'],
                );
                // log(matchRecord.toString());
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Match(
                            matchRecord: matchRecord,
                          ),
                      fullscreenDialog: true),
                ).then((value) => print('Returned to Match Page'));
              },
            );
          },
        );

      case 3:
        // Decode match data to extract statistics
        List<dynamic> allMatches = jsonDecode(matchData);
        int totalMatches = allMatches.length;
        int qualMatches =
            allMatches.where((m) => m['comp_level'] == 'qm').length;
        int playoffMatches =
            allMatches.where((m) => m['comp_level'] == 'sf').length;
        int finalMatches =
            allMatches.where((m) => m['comp_level'] == 'f').length;

        // Extract event information
        String eventKey =
            allMatches.isNotEmpty ? allMatches[0]['event_key'] : 'Unknown';
        String eventName = _formatEventName(eventKey);
        String eventYear = eventKey.substring(0, 4);
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ScouterList(),
              // Event Information Card
              Card(
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 8,
                shadowColor: Colors.blueAccent.withOpacity(0.3),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueAccent.withOpacity(0.7),
                        Colors.indigoAccent.withOpacity(0.8)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.emoji_events,
                              color: Colors.white, size: 26),
                          const SizedBox(width: 12),
                          Text(
                            'Competition',
                            style: GoogleFonts.museoModerno(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        eventName,
                        style: GoogleFonts.museoModerno(
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$eventYear Season',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Match Statistics Card
              Card(
                color: Colors.white,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24),
                          const SizedBox(width: 10),
                          Text(
                            'Match Statistics',
                            style: GoogleFonts.roboto(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildStatisticRow(
                          context,
                          Icons.sports_score,
                          'Total Matches',
                          totalMatches.toString(),
                          Colors.blue.shade800),
                      const SizedBox(height: 12),
                      _buildStatisticRow(
                          context,
                          Icons.sports_soccer,
                          'Qualification Matches',
                          qualMatches.toString(),
                          Colors.green.shade700),
                      const SizedBox(height: 12),
                      _buildStatisticRow(
                          context,
                          Icons.sports_basketball,
                          'Playoff Matches',
                          playoffMatches.toString(),
                          Colors.orange.shade700),
                      const SizedBox(height: 12),
                      _buildStatisticRow(
                          context,
                          Icons.sports_rugby,
                          'Final Matches',
                          finalMatches.toString(),
                          Colors.red.shade700),
                    ],
                  ),
                ),
              ),

              // Scouter Configuration
              Card(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                color: const Color.fromARGB(255, 255, 255, 255),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24),
                          const SizedBox(width: 10),
                          Text(
                            'Scouter Profile',
                            style: GoogleFonts.roboto(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2),
                            radius: 36,
                            child: Text(
                              _getInitials(Hive.box('settings')
                                  .get('deviceName', defaultValue: 'Scout')),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Hive.box('settings').get('deviceName') ??
                                      'Unknown Scout',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        Hive.box('userData').get('alliance') ==
                                                'Red'
                                            ? Colors.red.withOpacity(0.2)
                                            : Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${Hive.box('userData').get('alliance', defaultValue: 'Red')} Alliance - Position ${Hive.box('userData').get('position', defaultValue: '1')}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Hive.box('userData')
                                                  .get('alliance') ==
                                              'Red'
                                          ? Colors.red.shade700
                                          : Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      MatchSelection(
                          onAllianceSelected: (String? alliance) {
                            setState(() {
                              Hive.box('userData').put('alliance', alliance);
                            });
                          },
                          onPositionSelected: (String? position) {
                            setState(() {
                              Hive.box('userData').put('position', position);
                            });
                          },
                          initAlliance: Hive.box('userData')
                              .get('alliance', defaultValue: "Red"),
                          initPosition: Hive.box('userData')
                              .get('position', defaultValue: '1')),
                    ],
                  ),
                ),
              ),

              // Tips or Fun Facts
              Card(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 6,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.shade300,
                        Colors.deepPurple.shade500
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline,
                              color: Colors.white, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            'Scouting Tip',
                            style: GoogleFonts.roboto(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getRandomScoutingTip(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      default:
        return const Center(child: Text('Unknown Match Type'));
    }
  }

// Helper method to format event name
  String _formatEventName(String eventKey) {
    // Extract event code (e.g., "2024nyro" becomes "NYRO")
    String eventCode = eventKey.substring(4);

    // Convert to proper format
    Map<String, String> eventNames = {
      // Michigan District Events
      "miket": "Kettering University District",
      "micen": "Center Line District",
      "misjo": "St. Joseph District",
      "mitvc": "Traverse City District",
      "miwat": "Waterford District",
      "mitry": "Troy District",
      "milak": "Lakeview District",
      "miken": "East Kentwood District",
      "miliv": "Livonia District",
      "mimas": "Mason District",
      "mialp": "Alpena District",
      "mimid": "Midland District",
      "mimon": "Monroe District",
      "mimil": "Milford District",
      "misou": "Southfield District",
      "miann": "Ann Arbor District",
      "mijac": "Jackson District",
      "miwoo": "Woodhaven District",
      "mimac": "Macomb District",
      "mibel": "Belleville District",
      "misag": "Saginaw Valley District",
      "migib": "Gibraltar District",
      "migul": "Gull Lake District",
      "mical": "Calvin District",
      "miesc": "Escanaba District",
      "mifor": "Fordson District",
      "mibri": "Brighton District",
      "mimtp": "Mt. Pleasant District", // Added Mt. Pleasant
      "mipla": "Placeholder District",

      // Michigan State Championship
      "micmp": "Michigan State Championship",
      "micha": "Michigan State Championship",

      // Other popular events Michigan teams might attend
      "chs": "Chesapeake District Championship",
      "ont": "Ontario Provincial Championship",
      "in": "Indiana State Championship",
      "oh": "Ohio State Championship",
      "first": "FIRST Championship",
      "arc": "Archimedes Division",
      "car": "Carson Division",
      "cur": "Curie Division",
      "dal": "Daly Division",
      "dar": "Darwin Division",
      "gal": "Galileo Division",
      "hop": "Hopper Division",
      "new": "Newton Division",
      "roe": "Roebling Division",
      "tur": "Turing Division",
      "cmptx": "FIRST Championship - Houston",
      "cmpmi": "FIRST Championship - Detroit",

      // Add more event codes and names as needed
      "isde": "Isreal District Event",
      "isdc": "Isreal District Championship",
      "isw": "Isreal World Championship",
    };

    return eventNames[eventCode] ?? "Event ${eventCode.toUpperCase()}";
  }

// Helper method to build statistic row
  Widget _buildStatisticRow(BuildContext context, IconData icon, String label,
      String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

// Helper method to get initials from name
  String _getInitials(String name) {
    if (name.isEmpty) return "Ri";

    List<String> nameParts = name.split(" ");
    if (nameParts.length > 1) {
      return nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }

// Helper method to get random scouting tip
// Helper method to get random scouting tip
  String _getRandomScoutingTip() {
    List<String> tips = [
      "Focus on one robot at a time to get accurate data.",
      "Note unusual strategies that might affect alliance selection.",
      "Watch for consistent performance rather than best/worst matches.",
      "Pay attention to robot speed and maneuverability during matches.",
      "Defense capability can be just as valuable as scoring ability.",
      "Track cycle times for repetitive actions to gauge efficiency.",
      "Note any technical issues that might indicate reliability problems.",
      "Watch for effective communication between alliance partners.",
      "Be aware of the field layout and how it affects robot movement.",
      "Take note of any unique features or strategies used by teams.",
      "Scouting is only as hard as you make it. You can always give up. 😁",
      "Data drives decisions—scout smart, strategize smarter.",
      "Scouting isn't just collecting numbers; it's unlocking victories.",
      "Great teams don't guess—they scout.",
      "Every match tells a story. It's your job to read it.",
      "Championships are built on good scouting.",
      "Scouting today wins matches tomorrow.",
      "Your data is your weapon—use it wisely.",
      "Precision in scouting leads to domination on the field.",
      "The best alliances are chosen, not given.",
      "Numbers don't lie—trust the data, trust the process.",
    ];

    return tips[DateTime.now().microsecond % tips.length];
  }
}
