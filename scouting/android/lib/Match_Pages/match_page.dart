import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
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

      default:
        return const Center(child: Text('Unknown Match Type'));
    }
  }

  void _showMatchDetailsDialog(BuildContext context, dynamic match) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Match Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Match Number: ${match['match_number']}"),
              Text("Comp Level: ${match['comp_level']}"),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
