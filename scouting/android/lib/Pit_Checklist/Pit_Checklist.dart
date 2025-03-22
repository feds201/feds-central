import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:scouting_app/Pit_Checklist/CheckLists.dart';
import 'package:scouting_app/components/Inspiration.dart';
import 'package:scouting_app/components/MatchSelection.dart';
import 'package:scouting_app/components/ScoutersList.dart';
import 'package:scouting_app/components/Insults.dart';
import 'package:scouting_app/home_page.dart';
import '../services/DataBase.dart';

class PitCheckListPage extends StatefulWidget {
  const PitCheckListPage({super.key});

  @override
  PitCheckListPageState createState() => PitCheckListPageState();
}

class PitCheckListPageState extends State<PitCheckListPage>
    with SingleTickerProviderStateMixin {
  late int selectedMatchType;
  late AnimationController _animationController;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    selectedMatchType = 0;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var data = Hive.box('matchData').get('matches');
    if (data == null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: _buildNoDataView(),
      );
    }
    return Scaffold(
      appBar: _buildAppBar(),
      body: matchSelection(context, selectedMatchType, (int index) {
        setState(() {
          selectedMatchType = index;
          _animationController.reset();
          _animationController.forward();
        });
      }, jsonEncode(data)),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
          ),
          child: IconButton(
            icon: const Icon(Icons.home, color: Color.fromARGB(255, 0, 0, 0)),
            onPressed: () async {
              await Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomePage(),
                  fullscreenDialog: true,
                ),
                (Route<dynamic> route) => false,
              );
            },
          ),
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
            'Pit Checklist',
            style: GoogleFonts.museoModerno(
              fontSize: 30,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          )),
      centerTitle: true,
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_score_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'No Match Data Available',
            style: GoogleFonts.museoModerno(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Please load match data from the TBA',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget matchSelection(BuildContext context, int currentSelectedMatchType,
      Function onMatchTypeSelected, String matchData) {
    return Row(
      children: [
        // Enhanced Navigation Rail
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: NavigationRail(
            backgroundColor: Colors.white,
            selectedIndex: currentSelectedMatchType,
            onDestinationSelected: (int index) {
              onMatchTypeSelected(index);
            },
            labelType: NavigationRailLabelType.all,
            selectedLabelTextStyle: GoogleFonts.museoModerno(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelTextStyle: GoogleFonts.museoModerno(
              color: Colors.grey.shade600,
            ),
            destinations: [
              _buildNavDestination(
                Icons.sports_soccer,
                'Quals',
                Colors.blue,
                currentSelectedMatchType == 0,
              ),
              _buildNavDestination(
                Icons.sports_basketball,
                'Playoffs',
                Colors.orange,
                currentSelectedMatchType == 1,
              ),
              _buildNavDestination(
                Icons.sports_rugby,
                'Finals',
                Colors.red,
                currentSelectedMatchType == 2,
              ),
              _buildNavDestination(
                Icons.settings,
                'Settings',
                Colors.purple,
                currentSelectedMatchType == 3,
              ),
            ],
          ),
        ),
        const VerticalDivider(thickness: 1, width: 1),

        // Match List with Animation
        Expanded(
          child: FadeTransition(
            opacity: _animationController..forward(),
            child: _buildMatchList(currentSelectedMatchType, matchData),
          ),
        ),
      ],
    );
  }

  NavigationRailDestination _buildNavDestination(
      IconData icon, String label, Color color, bool isSelected) {
    return NavigationRailDestination(
      icon: Icon(
        icon,
        color: isSelected ? color : Colors.grey.shade500,
      ),
      selectedIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: color,
        ),
      ),
      label: Text(label),
    );
  }

  // Filter matches to include only those where team 201 is participating
  bool _hasTeam201(dynamic match) {
    if (match == null || match['alliances'] == null) return false;

    // Check if team 201 is in red alliance
    if (match['alliances']['red'] != null &&
        match['alliances']['red']['team_keys'] != null) {
      List<dynamic> redTeams = match['alliances']['red']['team_keys'];
      if (redTeams.contains('frc201')) return true;
    }

    // Check if team 201 is in blue alliance
    if (match['alliances']['blue'] != null &&
        match['alliances']['blue']['team_keys'] != null) {
      List<dynamic> blueTeams = match['alliances']['blue']['team_keys'];
      if (blueTeams.contains('frc201')) return true;
    }

    return false;
  }

  Widget _buildMatchList(int selectedMatchType, String matchData) {
    // Decode the JSON string to a Dart object
    List<dynamic> allMatches = jsonDecode(matchData);

    // Filter matches where Team 201 is participating
    List<dynamic> matches =
        allMatches.where((match) => _hasTeam201(match)).toList();

    switch (selectedMatchType) {
      case 0:
        var filteredMatches = matches
            .where((match) => match['comp_level'] == 'qm')
            .toList()
          ..sort((a, b) => int.parse(a['match_number'].toString())
              .compareTo(int.parse(b['match_number'].toString())));

        return _buildMatchListView(
          filteredMatches,
          'Qualification',
          Icons.sports_soccer,
          Colors.blue,
          (match) => int.parse(match['match_number'].toString()),
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

        return _buildMatchListView(
          filteredMatches,
          'Semifinal',
          Icons.sports_basketball,
          Colors.orange,
          (match) => match['comp_level'].startsWith('sf')
              ? int.parse(match['set_number'].toString())
              : int.parse(match['match_number'].toString()),
        );

      case 2:
        var filteredMatches = matches
            .where((match) => match['comp_level'] == 'f')
            .toList()
          ..sort((a, b) => int.parse(a['match_number'].toString())
              .compareTo(int.parse(b['match_number'].toString())));

        return _buildMatchListView(
          filteredMatches,
          'Final',
          Icons.sports_rugby,
          Colors.red,
          (match) => int.parse(match['match_number'].toString()),
        );

      case 3:
        // Settings Page
        // Using the existing settings page implementation but with total match count of team 201
        return _buildSettingsView(matches, allMatches);

      default:
        return const Center(child: Text('Unknown Match Type'));
    }
  }

  Widget _buildMatchListView(
    List<dynamic> matches,
    String matchTypeName,
    IconData matchIcon,
    Color themeColor,
    Function(dynamic) getMatchNumber,
  ) {
    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              matchIcon,
              size: 60,
              color: themeColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No $matchTypeName Matches for Team 201',
              style: GoogleFonts.museoModerno(
                fontSize: 20,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
      itemCount: matches.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return ShowInsults();
        }
        index -= 1;

        final match = matches[index];
        final matchNumber = getMatchNumber(match);

        return _buildEnhancedMatchCard(
          context,
          match,
          matchTypeName,
          matchIcon,
          themeColor,
          matchNumber,
          index,
        );
      },
    );
  }

  Widget _buildEnhancedMatchCard(
    BuildContext context,
    dynamic match,
    String matchTypeName,
    IconData matchIcon,
    Color themeColor,
    int matchNumber,
    int index,
  ) {
    // Create alliance teams lists
    final redAlliance = match['alliances']['red']['team_keys']
        .map((team) => team.toString().replaceAll('frc', ''))
        .toList();
    final blueAlliance = match['alliances']['blue']['team_keys']
        .map((team) => team.toString().replaceAll('frc', ''))
        .toList();

    // Determine which alliance has Team 201
    final bool team201InRed = redAlliance.contains('201');
    final bool team201InBlue = blueAlliance.contains('201');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shadowColor: themeColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: themeColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleMatchSelection(match),
          splashColor: themeColor.withOpacity(0.1),
          highlightColor: themeColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with match number, icon, and Team 201 indicator
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        matchIcon,
                        color: themeColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$matchTypeName $matchNumber',
                            style: GoogleFonts.museoModerno(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: themeColor,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '$matchTypeName Match',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: team201InRed
                                      ? Colors.red.withOpacity(0.2)
                                      : Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${team201InRed ? 'Red' : 'Blue'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: team201InRed
                                        ? Colors.red.shade700
                                        : Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: themeColor.withOpacity(0.6),
                      size: 18,
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // Alliance information with Team 201 highlighted
                Row(
                  children: [
                    // Red Alliance
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Red Alliance',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ...redAlliance.map((team) => Padding(
                                padding:
                                    const EdgeInsets.only(left: 20, top: 2),
                                child: Text(
                                  team,
                                  style: TextStyle(
                                    color: team == '201'
                                        ? Colors.red.shade700
                                        : Colors.grey.shade700,
                                    fontWeight: team == '201'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),

                    // Blue Alliance
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Blue Alliance',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ...blueAlliance.map((team) => Padding(
                                padding:
                                    const EdgeInsets.only(left: 20, top: 2),
                                child: Text(
                                  team,
                                  style: TextStyle(
                                    color: team == '201'
                                        ? Colors.blue.shade700
                                        : Colors.grey.shade700,
                                    fontWeight: team == '201'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleMatchSelection(dynamic match) {
    PitChecklistItem record =
        PitChecklistItem.defaultConstructor(match['match_number']);

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Checklist_record(list_item: record),
          fullscreenDialog: true),
    ).then((_) {
      print('Returned to Pit Checklist Page');
    });
  }

  Widget _buildSettingsView(
      List<dynamic> team201Matches, List<dynamic> allMatches) {
    // Extract event information
    int totalMatches = allMatches.length;
    int team201MatchCount = team201Matches.length;
    int qualMatches =
        team201Matches.where((m) => m['comp_level'] == 'qm').length;
    int playoffMatches =
        team201Matches.where((m) => m['comp_level'] == 'sf').length;
    int finalMatches =
        team201Matches.where((m) => m['comp_level'] == 'f').length;

    String eventKey =
        allMatches.isNotEmpty ? allMatches[0]['event_key'] : 'Unknown';
    String eventName = _formatEventName(eventKey);
    String eventYear = eventKey.substring(0, 4);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ScouterList(),

          // Team 201 Card with enhanced visual appeal
          Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 8,
            shadowColor: Colors.redAccent.withOpacity(0.3),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [
                    Colors.redAccent.withOpacity(0.7),
                    Colors.orangeAccent.withOpacity(0.8)
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
                      Icon(Icons.sports_kabaddi, color: Colors.white, size: 26),
                      const SizedBox(width: 12),
                      Text(
                        'Team 201',
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
                    'FEDS201',
                    style: GoogleFonts.museoModerno(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Fully Engaged Dedicated Students',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Event Information Card
          Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                      Icon(Icons.emoji_events, color: Colors.white, size: 26),
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

          // Team 201 Match Statistics Card
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
                        'Team 201 Match Statistics',
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
                      'Team 201 Matches',
                      team201MatchCount.toString(),
                      Colors.purple.shade800),
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
                  const SizedBox(height: 12),
                  _buildStatisticRow(
                      context,
                      Icons.calendar_today,
                      'Total Event Matches',
                      totalMatches.toString(),
                      Colors.blue.shade800),
                ],
              ),
            ),
          ),

          // Scouter Profile
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
                        'Pit Scout Profile',
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
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Team 201 Pit Crew",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          ShowInsiration()
        ],
      ),
    );
  }

  // Helper method to format event name
  String _formatEventName(String eventKey) {
    // Your existing formatting code
    String eventCode = eventKey.substring(4);

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
      "mimtp": "Mt. Pleasant District",
      "mipla": "Placeholder District",

      // Michigan State Championship
      "micmp": "Michigan State Championship",
      "micha": "Michigan State Championship",

      // Other popular events
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

      // Additional events
      "isde": "Israel District Event",
      "isdc": "Israel District Championship",
      "isw": "Israel World Championship",
    };

    return eventNames[eventCode] ?? "Event ${eventCode.toUpperCase()}";
  }

  // Helper method to build statistic row with enhanced visual appeal
  Widget _buildStatisticRow(BuildContext context, IconData icon, String label,
      String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
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
    if (name.isEmpty) return "201";

    List<String> nameParts = name.split(" ");
    if (nameParts.length > 1) {
      return nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }
}
