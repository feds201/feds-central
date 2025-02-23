import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:scouting_app/Match_Pages/match.dart';
import 'package:scouting_app/Qualitative/QualitativePage.dart';

import '../components/DataBase.dart';

class Qualitative extends StatefulWidget {
  const Qualitative({super.key});

  @override
  QualitativeState createState() => QualitativeState();
}

class QualitativeState extends State<Qualitative> {
  late int selectedMatchType;

  @override
  void initState() {
    super.initState();
    selectedMatchType = 0;
  }

  @override
  Widget build(BuildContext context) {
    var data = Hive.box("matchData").get("matches", defaultValue: null);

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
              'Qualitative Data',
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
                LocalDataBase.putData(Types.matchFile, filteredMatches[index]);
                var eventKey = LocalDataBase.getData(Types.eventKey);
                var matchKey = filteredMatches[index]['key'];
                var allianceColor = LocalDataBase.getData(Types.allianceColor);
                var selectedStation =
                    LocalDataBase.getData(Types.selectedStation);
                var matchFile = LocalDataBase.getData(Types.matchFile);
                LocalDataBase.putData(Types.matchKey, matchKey);
                LocalDataBase.putData(Types.eventKey, eventKey);
                LocalDataBase.putData(Types.allianceColor, allianceColor);
                LocalDataBase.putData(Types.selectedStation, selectedStation);
                LocalDataBase.putData(Types.matchFile, matchFile);
                print('Match Key: $matchKey');
                print('Event Key: $eventKey');
                print('Alliance Color: $allianceColor');
                print('Selected Station: $selectedStation');
                print('Match File: $matchFile');

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QualitativePage()),
                );
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
              onTap: () {},
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
                  print(filteredMatches);
                  _showMatchDetailsDialog(
                      context, jsonDecode(matchData)[index]);
                });
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
              Text("data"),
            ],
          ),
        );
      },
    );
  }
}
