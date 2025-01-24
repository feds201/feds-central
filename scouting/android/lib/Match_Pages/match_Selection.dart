import 'dart:convert';

import 'package:flutter/material.dart';

import '../components/DataBase.dart';
import 'match.dart';

Widget matchSelection(BuildContext context, int _selectedMatchType,
    Function _onMatchTypeSelected, String matchData) {
  return Row(
    children: [
      NavigationRail(
        selectedIndex: _selectedMatchType,
        onDestinationSelected: (int index) {
          _onMatchTypeSelected(index);
        },
        labelType: NavigationRailLabelType.all,
        destinations: const <NavigationRailDestination>[
          NavigationRailDestination(
            icon: Icon(Icons.sports_soccer),
            label: Text('Quals'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.sports_basketball),
            label: Text('Matches'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.sports_rugby),
            label: Text('Finals'),
          ),
        ],
      ),
      const VerticalDivider(thickness: 1, width: 1),
      Expanded(
        child: _buildMatchList(_selectedMatchType, matchData),
      ),
    ],
  );
}
Widget _buildMatchList(int _selectedMatchType, String matchData) {
  // Decode the JSON string to a Dart object
  List<dynamic> matches = jsonDecode(matchData);

  switch (_selectedMatchType) {
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
            title:
            Text('Qualification ${filteredMatches[index]['match_number']}'),
            subtitle: const Text('Qualification Match'),
            leading: Icon(Icons.sports_soccer,
                color: Theme.of(context).colorScheme.primary),
            trailing: Icon(Icons.arrow_forward_ios_rounded,
                color: Theme.of(context).colorScheme.onSurface),
            tileColor: Theme.of(context).colorScheme.surface,
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
              var selectedStation = LocalDataBase.getData(Types.selectedStation);
              var matchFile = LocalDataBase.getData(Types.matchFile);
              LocalDataBase.putData(Types.matchKey, matchKey);
              LocalDataBase.putData(Types.eventKey, eventKey);
              LocalDataBase.putData(Types.allianceColor, allianceColor);
              LocalDataBase.putData(Types.selectedStation, selectedStation);
              LocalDataBase.putData(Types.matchFile, matchFile);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const Match(),
                    fullscreenDialog: true),
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
            tileColor: Theme.of(context).colorScheme.surface,
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
              var selectedStation = LocalDataBase.getData(Types.selectedStation);
              var matchFile = LocalDataBase.getData(Types.matchFile);
              LocalDataBase.putData(Types.matchKey, matchKey);
              LocalDataBase.putData(Types.eventKey, eventKey);
              LocalDataBase.putData(Types.allianceColor, allianceColor);
              LocalDataBase.putData(Types.selectedStation, selectedStation);
              LocalDataBase.putData(Types.matchFile, matchFile);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const Match(),
                    fullscreenDialog: true),
              );
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
            tileColor: Theme.of(context).colorScheme.surface,
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
              var selectedStation = LocalDataBase.getData(Types.selectedStation);
              var matchFile = LocalDataBase.getData(Types.matchFile);
              LocalDataBase.putData(Types.matchKey, matchKey);
              LocalDataBase.putData(Types.eventKey, eventKey);
              LocalDataBase.putData(Types.allianceColor, allianceColor);
              LocalDataBase.putData(Types.selectedStation, selectedStation);
              LocalDataBase.putData(Types.matchFile, matchFile);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Match(),
                    fullscreenDialog: true),
              );
            },
          );
        },
      );

    default:
      return const Center(child: Text('Unknown Match Type'));
  }
}
