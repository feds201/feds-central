import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:scouting_app/Pit_Checklist/CheckLists.dart';
import 'package:scouting_app/components/Inspiration.dart';
import 'package:scouting_app/components/ScoutersList.dart';
import 'package:scouting_app/components/Insults.dart';
import 'package:scouting_app/home_page.dart';
import 'package:scouting_app/main.dart';
import 'package:scouting_app/services/Colors.dart';
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

  // Add these variables for team filtering
  final TextEditingController _teamFilterController = TextEditingController();
  final List<String> _selectedTeams = [];
  bool _isFilterActive = false;
  String _filteredTeam = ""; // Added for single team filtering

  // Add this to your class variables
  bool _isClearing = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    selectedMatchType = 1;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _loadFilteredTeam(); // Load filtered team from storage
  }

  // Load filtered team from Hive
  void _loadFilteredTeam() async {
    var box = Hive.box('settings');
    setState(() {
      _filteredTeam = box.get('filteredTeam', defaultValue: "");
      if (_filteredTeam.isNotEmpty) {
        _teamFilterController.text = _filteredTeam;
        _selectedTeams.clear();
        _selectedTeams.add(_filteredTeam);
        _isFilterActive = true;
      }
    });
  }

// Get filtered matches based on team number
  List<dynamic> _getFilteredMatches(List<dynamic> matches) {
    if (_filteredTeam.isEmpty && !_isFilterActive) {
      return matches;
    }

    return matches.where((match) {
      if (match['alliances'] == null) return false;

      List<dynamic> teamKeys = [];
      if (match['alliances']['blue'] != null &&
          match['alliances']['blue']['team_keys'] != null) {
        teamKeys.addAll(match['alliances']['blue']['team_keys']);
      }

      if (match['alliances']['red'] != null &&
          match['alliances']['red']['team_keys'] != null) {
        teamKeys.addAll(match['alliances']['red']['team_keys']);
      }

      // Check if any selected team is in this match
      for (String teamNum in _selectedTeams) {
        if (teamKeys.any((team) => team.toString().contains(teamNum))) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  @override
  void dispose() {
    _teamFilterController.dispose();
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
      body: FutureBuilder<Widget>(
        future: matchSelection(context, selectedMatchType, (int index) {
          setState(() {
            selectedMatchType = index;
            _animationController.reset();
            _animationController.forward();
          });
        }, jsonEncode(data)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return snapshot.data ?? Container();
          }
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    String filterTitle =
        _filteredTeam.isNotEmpty ? " - Team $_filteredTeam" : "";

    return AppBar(
      elevation: 0,
      leading: Builder(builder: (context) {
        return IconButton(
            icon: const Icon(Icons.menu),
            color: !islightmode()
                ? const Color.fromARGB(193, 255, 255, 255)
                : const Color.fromARGB(105, 36, 33, 33),
            onPressed: () async {
              await Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomePage(),
                  fullscreenDialog: true,
                ),
                (Route<dynamic> route) => false,
              );
            });
      }),
      backgroundColor: islightmode() ? lightColors.white : darkColors.goodblack,
      title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.red, Colors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
          child: Text(
            'Pit Checklist$filterTitle',
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
              'Please load match data from The Blue Alliance',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.download_rounded),
            label: const Text('Load Match Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              _navigateToDataLoader();
            },
          ),
        ],
      ),
    );
  }

  void _navigateToDataLoader() async {
    // Navigate to the TBA data loading screen
    await Navigator.pushNamed(context, '/tba_data_loader');

    // After returning, check if data is now available
    if (Hive.box('matchData').get('matches') != null) {
      setState(() {
        // This will refresh the UI
      });
    }
  }

  Future<Widget> matchSelection(
      BuildContext context,
      int currentSelectedMatchType,
      Function onMatchTypeSelected,
      String matchData) async {
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
            backgroundColor:
                islightmode() ? lightColors.white : darkColors.goodblack,
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
                Icons.flag_circle,
                'Practice',
                Colors.pink,
                currentSelectedMatchType == 0,
              ),
              _buildNavDestination(
                Icons.sports_soccer,
                'Quals',
                Colors.blue,
                currentSelectedMatchType == 1,
              ),
              _buildNavDestination(
                Icons.sports_basketball,
                'Playoffs',
                Colors.orange,
                currentSelectedMatchType == 2,
              ),
              _buildNavDestination(
                Icons.sports_rugby,
                'Finals',
                Colors.red,
                currentSelectedMatchType == 3,
              ),
              _buildNavDestination(
                Icons.settings,
                'Settings',
                Colors.purple,
                currentSelectedMatchType == 4,
              ),
              _buildNavDestination(
                Icons.cloud,
                'Share',
                Colors.purple,
                currentSelectedMatchType == 5,
              ),
            ],
          ),
        ),

        VerticalDivider(
          thickness: 1,
          width: 1,
          color: islightmode() ? lightColors.white : darkColors.goodblack,
        ),
        // Match List with Animation
        Expanded(
          child: FadeTransition(
            opacity: _animationController..forward(),
            child: await _buildMatchList(currentSelectedMatchType, matchData),
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

  // Fix the _hasTeam201 method
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

  Future<Widget> _buildMatchList(
    int selectedMatchType,
    String matchData,
  ) async {
    // Decode the JSON string to a Dart object
    List<dynamic> allMatches = jsonDecode(matchData);

    // Filter matches by filtered team if enabled
    List<dynamic> filteredByTeam = _getFilteredMatches(allMatches);

    // Filter matches where Team 201 is participating if no team filter active
    List<dynamic> matches = _filteredTeam.isEmpty && !_isFilterActive
        ? filteredByTeam.where((match) => _hasTeam201(match)).toList()
        : filteredByTeam;

    switch (selectedMatchType) {
      case 0:
        final String jsonString =
            await rootBundle.loadString('assets/day_zero.json');
        List<dynamic> practiceMatches = jsonDecode(jsonString);
        // Apply team filter to practice matches too
        if (_filteredTeam.isNotEmpty || _isFilterActive) {
          practiceMatches = _getFilteredMatches(practiceMatches);
        }
        return _buildMatchListView(
          practiceMatches,
          'Practice',
          Icons.flag_circle,
          Colors.pink,
          (match) => int.parse(match['match_number'].toString()),
        );

      case 1:
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

      case 2:
        // Modified - Playoff matches including manual entries
        var filteredMatches = matches
            .where((match) =>
                match['comp_level'] == 'sf' || match['comp_level'] == 'qf')
            .toList();

        // Add manual playoff matches
        List<dynamic> manualMatches = _loadManualMatches();

        // Apply team filter to manual matches too
        if (_filteredTeam.isNotEmpty || _isFilterActive) {
          manualMatches = _getFilteredMatches(manualMatches);
        }

        var manualPlayoffMatches = manualMatches
            .where((match) =>
                match['comp_level'] == 'sf' || match['comp_level'] == 'qf')
            .toList();

        // Combine TBA and manual matches
        filteredMatches.addAll(manualPlayoffMatches);

        // Sort all matches
        filteredMatches.sort((a, b) {
          // First sort by comp_level (qf before sf)
          int compLevelComparison = a['comp_level'].compareTo(b['comp_level']);
          if (compLevelComparison != 0) return compLevelComparison;

          // Then by set number
          int aSet = int.parse(a['set_number'].toString());
          int bSet = int.parse(b['set_number'].toString());
          int setComparison = aSet.compareTo(bSet);
          if (setComparison != 0) return setComparison;

          // Finally by match number
          int aMatch = int.parse(a['match_number'].toString());
          int bMatch = int.parse(b['match_number'].toString());
          return aMatch.compareTo(bMatch);
        });

        return _buildPlayoffsMatchList(
          filteredMatches,
          'Playoff',
          Icons.sports_basketball,
          Colors.orange,
          (match) => match['comp_level'].startsWith('sf')
              ? int.parse(match['set_number'].toString())
              : int.parse(match['match_number'].toString()),
        );

      case 3:
        var filteredMatches =
            matches.where((match) => match['comp_level'] == 'f').toList();

        // Add manual final matches
        List<dynamic> manualMatches = _loadManualMatches();

        // Apply team filter to manual matches too
        if (_filteredTeam.isNotEmpty || _isFilterActive) {
          manualMatches = _getFilteredMatches(manualMatches);
        }

        var manualFinalMatches =
            manualMatches.where((match) => match['comp_level'] == 'f').toList();

        // Combine TBA and manual matches
        filteredMatches.addAll(manualFinalMatches);

        // Sort all matches
        filteredMatches.sort((a, b) => int.parse(a['match_number'].toString())
            .compareTo(int.parse(b['match_number'].toString())));

        return _buildMatchListView(
          filteredMatches,
          'Final',
          Icons.sports_rugby,
          Colors.red,
          (match) => int.parse(match['match_number'].toString()),
        );

      case 4:
        return _buildSettingsView(matches, allMatches);

      case 5:
        return buildShare(context);

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
    // Extract all teams from these matches
    _extractTeamsFromMatches(matches);

    if (matches.isEmpty) {
      return Column(
        children: [
          // Add team filter at the top

          Expanded(
            child: Center(
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
                    _isFilterActive
                        ? 'No matches found with selected teams'
                        : 'No $matchTypeName Matches for Team 201',
                    style: GoogleFonts.museoModerno(
                      fontSize: 20,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // Add team filter at the top

        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
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
          ),
        ),
      ],
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
    PitCheckListDatabase.LoadAll();
    // Check if this is a manual entry
    final bool isManual = match['manual_entry'] == true;

    // Create alliance teams lists
    final redAlliance = match['alliances']['red']['team_keys']
        .map((team) => team.toString().replaceAll('frc', ''))
        .toList();
    final blueAlliance = match['alliances']['blue']['team_keys']
        .map((team) => team.toString().replaceAll('frc', ''))
        .toList();

    // Determine which alliance has Team 201
    final bool team201InRed = redAlliance.contains('201');

    // Add a badge for manual entries
    Widget? badgeWidget = isManual
        ? Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_note,
                    size: 14,
                    color: Colors.purple,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Manual',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ),
          )
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          Card(
            elevation: 4,
            shadowColor: themeColor.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isManual
                    ? Colors.purple.withOpacity(0.3)
                    : themeColor.withOpacity(0.2),
                width: isManual ? 1.5 : 1,
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
                                            : (_filteredTeam == team
                                                ? Colors.purple.shade700
                                                : Colors.grey.shade700),
                                        fontWeight: (team == '201' ||
                                                _filteredTeam == team)
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
                                            : (_filteredTeam == team
                                                ? Colors.purple.shade700
                                                : Colors.grey.shade700),
                                        fontWeight: (team == '201' ||
                                                _filteredTeam == team)
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
            color: islightmode() ? lightColors.white : darkColors.goodblack,
          ),
          if (badgeWidget != null) badgeWidget,
        ],
      ),
    );
  }

  void _handleMatchSelection(dynamic match) {
    PitChecklistItem record = PitChecklistItem.defaultConstructor(match['key']);

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

          // Replace the duplicated Pit Memory card and data management sections with this single card
          Card(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.storage,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Pit Data Management',
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Statistics Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        // Data icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.assignment_rounded,
                            color: Colors.blue.shade600,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Data stats
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Saved Pit Checklists',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '${PitCheckListDatabase.GetStorageSize()}',
                                    style: GoogleFonts.roboto(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: PitCheckListDatabase
                                                  .GetStorageSize() >
                                              0
                                          ? Colors.blue.shade700
                                          : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'teams',
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Quick status indicator
                        if (PitCheckListDatabase.GetStorageSize() > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green.shade700,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Active',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.grey.shade600,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Empty',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      // Export Button
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: _isExporting
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.share_rounded, size: 20),
                          label: Text(
                              _isExporting ? 'Exporting...' : 'Export Data'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            visualDensity: VisualDensity.comfortable,
                          ),
                          onPressed: (_isClearing || _isExporting)
                              ? null
                              : () async {
                                  final dataCount =
                                      PitCheckListDatabase.GetStorageSize();
                                  if (dataCount == 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'No pit checklist data to export'),
                                        backgroundColor: Colors.blue.shade700,
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() {
                                    _isExporting = true;
                                  });

                                  setState(() {
                                    _isExporting = false;
                                    selectedMatchType = 5;
                                  });

                                  // Here you'd add your actual export logic
                                },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Clear Button
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: _isClearing
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.delete_outline_rounded,
                                  size: 20),
                          label:
                              Text(_isClearing ? 'Clearing...' : 'Clear All'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            visualDensity: VisualDensity.comfortable,
                          ),
                          onPressed: (_isClearing || _isExporting)
                              ? null
                              : () => _clearPitChecklistData(context),
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

  // Add this method to the PitCheckListPageState class
  Widget _buildPlayoffsMatchList(
    List<dynamic> matches,
    String matchTypeName,
    IconData matchIcon,
    Color themeColor,
    Function(dynamic) getMatchNumber,
  ) {
    // Extract all teams from these matches
    _extractTeamsFromMatches(matches);

    return Column(
      children: [
        // Add "Create Playoff Match" button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Create Manual Playoff Match'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () => _showCreatePlayoffMatchDialog(context),
          ),
        ),

        // Show existing matches (if any) or a message
        Expanded(
          child: matches.isEmpty
              ? Center(
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
                        _isFilterActive
                            ? 'No matches found with selected teams'
                            : 'No $matchTypeName Matches for Team 201 yet',
                        style: GoogleFonts.museoModerno(
                          fontSize: 20,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use the button above to create a manual entry',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
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
                ),
        ),
      ],
    );
  }

  // Dialog for creating manual playoff matches
  void _showCreatePlayoffMatchDialog(BuildContext context) {
    String selectedMatchType = 'Quarterfinal';
    int allianceNumber = 1;
    String alliancePosition = 'Captain';
    int matchNumber = 1;
    String allianceColor = 'Red';
    int setNumber = 1;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Create Playoff Match',
            style: GoogleFonts.museoModerno(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Match Type
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Match Type',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  value: selectedMatchType,
                  items: ['Quarterfinal', 'Semifinal', 'Final'].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedMatchType = value!;
                  },
                ),
                const SizedBox(height: 16),

                // Alliance Number
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Alliance Number',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  value: allianceNumber,
                  items: List.generate(8, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text('Alliance ${index + 1}'),
                    );
                  }),
                  onChanged: (value) {
                    allianceNumber = value!;
                  },
                ),
                const SizedBox(height: 16),

                // Alliance Position
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Team 201 Position',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  value: alliancePosition,
                  items: ['Captain', 'First Pick', 'Second Pick'].map((pos) {
                    return DropdownMenuItem(
                      value: pos,
                      child: Text(pos),
                    );
                  }).toList(),
                  onChanged: (value) {
                    alliancePosition = value!;
                  },
                ),
                const SizedBox(height: 16),

                // Match Number and Set Number in a row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Match Number',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: matchNumber.toString(),
                        onChanged: (value) {
                          matchNumber = int.tryParse(value) ?? 1;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Set Number',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: setNumber.toString(),
                        onChanged: (value) {
                          setNumber = int.tryParse(value) ?? 1;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Alliance Color
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Alliance Color',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  value: allianceColor,
                  items: ['Red', 'Blue'].map((color) {
                    return DropdownMenuItem(
                      value: color,
                      child: Text(color),
                    );
                  }).toList(),
                  onChanged: (value) {
                    allianceColor = value!;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child:
                  Text('Cancel', style: TextStyle(color: Colors.grey.shade700)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Match'),
              onPressed: () {
                // Generate match ID based on match type
                String matchTypeCode = selectedMatchType == 'Quarterfinal'
                    ? 'qf'
                    : selectedMatchType == 'Semifinal'
                        ? 'sf'
                        : 'f';

                String matchKey =
                    '2025mimid_${matchTypeCode}${setNumber}m$matchNumber';

                // Create synthetic match object
                Map<String, dynamic> syntheticMatch = {
                  'key': matchKey,
                  'comp_level': matchTypeCode,
                  'match_number': matchNumber,
                  'set_number': setNumber,
                  'event_key': '2025mimid',
                  'manual_entry': true,
                  'alliance_selection_data': {
                    'alliance_number': allianceNumber,
                    'position': alliancePosition,
                  },
                  'alliances': {
                    'red': {
                      'team_keys': allianceColor == 'Red'
                          ? ['frc201', 'frcXXXX', 'frcYYYY']
                          : ['frcAAAA', 'frcBBBB', 'frcCCCC'],
                    },
                    'blue': {
                      'team_keys': allianceColor == 'Blue'
                          ? ['frc201', 'frcXXXX', 'frcYYYY']
                          : ['frcAAAA', 'frcBBBB', 'frcCCCC'],
                    },
                  }
                };

                // Store the manual match in Hive
                _saveManualMatch(syntheticMatch);

                // Handle the synthetic match
                _handleMatchSelection(syntheticMatch);
                Navigator.of(dialogContext).pop();

                // Refresh the UI to show the new match
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  // New method to save manual matches
  void _saveManualMatch(Map<String, dynamic> match) {
    // Get existing manual matches or create new list
    List<Map<String, dynamic>> manualMatches = [];
    final box = Hive.box('matchData');
    final existingData = box.get('manualMatches');

    if (existingData != null) {
      try {
        List<dynamic> decodedData = jsonDecode(existingData);
        manualMatches = List<Map<String, dynamic>>.from(decodedData);
      } catch (e) {
        print('Error loading manual matches: $e');
      }
    }

    // Check if a match with this key already exists
    final matchIndex =
        manualMatches.indexWhere((m) => m['key'] == match['key']);
    if (matchIndex >= 0) {
      manualMatches[matchIndex] = match; // Replace existing
    } else {
      manualMatches.add(match); // Add new
    }

    // Save back to Hive
    box.put('manualMatches', jsonEncode(manualMatches));
  }

  // New method to load manual matches
  List<dynamic> _loadManualMatches() {
    final box = Hive.box('matchData');
    final existingData = box.get('manualMatches');

    if (existingData != null) {
      try {
        List<dynamic> decodedData = jsonDecode(existingData);
        return decodedData;
      } catch (e) {
        print('Error loading manual matches: $e');
      }
    }
    return [];
  }

  // Add this method to extract all teams from matches
  List<String> _extractTeamsFromMatches(List<dynamic> matches) {
    Set<String> teams = {};

    for (var match in matches) {
      if (match['alliances'] != null) {
        // Extract red alliance teams
        if (match['alliances']['red'] != null &&
            match['alliances']['red']['team_keys'] != null) {
          for (var team in match['alliances']['red']['team_keys']) {
            teams.add(team.toString().replaceAll('frc', ''));
          }
        }

        // Extract blue alliance teams
        if (match['alliances']['blue'] != null &&
            match['alliances']['blue']['team_keys'] != null) {
          for (var team in match['alliances']['blue']['team_keys']) {
            teams.add(team.toString().replaceAll('frc', ''));
          }
        }
      }
    }

    // Convert to List and sort
    List<String> teamsList = teams.toList();
    teamsList.sort((a, b) => int.tryParse(a) != null && int.tryParse(b) != null
        ? int.parse(a).compareTo(int.parse(b))
        : a.compareTo(b));

    return teamsList;
  }

  // Method to handle pit checklist data clearing
  Future<void> _clearPitChecklistData(BuildContext context) async {
    final dataCount = PitCheckListDatabase.GetStorageSize();
    if (dataCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 10),
              const Text('No pit checklist data to delete'),
            ],
          ),
          backgroundColor: Colors.blue.shade700,
        ),
      );
      return;
    }

    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.red.withOpacity(0.1),
                child: Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Confirm Deletion',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to delete pit checklist data for $dataCount teams.',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This action cannot be undone and all pit scouting data will be permanently removed from this device.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber.shade800,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Make sure you have shared or backed up any important data first!',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete All Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm) {
      setState(() {
        _isClearing = true;
      });

      try {
        // Add small delay for visual feedback
        await Future.delayed(const Duration(milliseconds: 800));

        // Clear both Hive and the PitCheckListDatabase
        PitCheckListDatabase.ClearData();

        setState(() {
          _isClearing = false;
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                const Text(
                    'All pit checklist data has been deleted successfully'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } catch (e) {
        setState(() {
          _isClearing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Text('Error: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Widget buildShare(BuildContext context) {
    bool _isSharing = false;
    String _shareStatus = "";
    Map<String, bool> _checkResults = {
      'Data': false,
      'WiFi': false,
      'Server': false,
    };

    // Load status checks
    _checkSharing() async {
      // Check if we have data to share
      final hasData = PitCheckListDatabase.GetStorageSize() > 0;

      // Check WiFi connection
      bool hasWifi = false;
      try {
        final response = await http
            .get(Uri.parse('https://google.com'))
            .timeout(const Duration(seconds: 3));
        hasWifi = response.statusCode == 200;
      } catch (e) {
        hasWifi = false;
      }

      // Check server availability - can modify this with your actual server check
      bool serverAvailable = true;

      return {
        'Data': hasData,
        'WiFi': hasWifi,
        'Server': serverAvailable,
      };
    }

    return StatefulBuilder(
      builder: (context, setState) {
        // Function to share the data
        Future<void> _shareData() async {
          if (_isSharing) return;

          setState(() {
            _isSharing = true;
            _shareStatus = "Preparing to share data...";
          });

          try {
            final dataCount = PitCheckListDatabase.GetStorageSize();
            final scriptUrl =
                "https://script.google.com/macros/s/${Settings.getPitKey()}/exec"; // Updated to use Settings.getPitKey()

            // Simulate sending data to the server
            final allChecklistData = PitCheckListDatabase.Export();
            final keys = allChecklistData.keys.toList();
            for (int i = 0; i < dataCount && i < keys.length; i++) {
              final key = keys[i];
              final PitChecklistItem checklistData =
                  allChecklistData[key] as PitChecklistItem;

              final finalchecklist = serverModifier(checklistData);

              final response = await http.post(
                Uri.parse(scriptUrl),
                body: jsonEncode(finalchecklist),
                headers: {"Content-Type": "application/json"},
              );

              if (response.statusCode != 200) {
                throw Exception("Failed to share data for team ${i + 1}");
              }

              setState(() {
                _shareStatus = "Sharing data... ${i + 1}/$dataCount";
              });
              await Future.delayed(const Duration(milliseconds: 800));
            }

            // Show success dialog
            if (!context.mounted) return;
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 28),
                      const SizedBox(width: 10),
                      const Text('Sharing Complete'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Successfully shared data for $dataCount teams.'),
                      const SizedBox(height: 12),
                      const Text('Thank you for sharing!'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          } catch (e) {
            // Show error dialog
            if (!context.mounted) return;
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 28),
                      const SizedBox(width: 10),
                      const Text('Error'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Failed to share data:'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          e.toString(),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          } finally {
            setState(() {
              _isSharing = false;
              _shareStatus = "";
            });
          }
        }

        return FutureBuilder<Map<String, bool>>(
          future: _checkSharing(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasData) {
              _checkResults = snapshot.data!;
            }

            final allChecksPass = _checkResults.values.every((v) => v);
            final dataCount = PitCheckListDatabase.GetStorageSize();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  // Header Card
                  Card(
                    margin: const EdgeInsets.all(16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade400,
                            Colors.indigo.shade600
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload,
                                  color: Colors.white, size: 28),
                              const SizedBox(width: 12),
                              Text(
                                'Share Pit Checklists',
                                style: GoogleFonts.museoModerno(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Share your pit checklist data with the FEDS scouting server',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Status Checks
                  Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pre-flight Checks',
                            style: GoogleFonts.roboto(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStatusCheck(
                            'Checklist Data Available',
                            _checkResults['Data'] ?? false,
                            Icons.assignment_outlined,
                          ),
                          const SizedBox(height: 12),
                          _buildStatusCheck(
                            'WiFi Connection',
                            _checkResults['WiFi'] ?? false,
                            Icons.wifi,
                          ),
                          const SizedBox(height: 12),
                          _buildStatusCheck(
                            'FEDS Server Available',
                            _checkResults['Server'] ?? false,
                            Icons.cloud_done,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Teams to Share
                  Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Teams to Share',
                            style: GoogleFonts.roboto(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (dataCount == 0)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: Colors.orange),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'No pit checklist data to share',
                                      style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '$dataCount teams will be shared',
                                      style: TextStyle(
                                        color: Colors.blue.shade800,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      'Ready',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
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

                  // Share Button
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: ElevatedButton.icon(
                      icon: _isSharing
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.cloud_upload, size: 24),
                      label: Text(
                        _isSharing ? 'Sharing...' : 'Share with FEDS Server',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            allChecksPass ? Colors.green : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      onPressed:
                          allChecksPass && !_isSharing ? _shareData : null,
                    ),
                  ),

                  // Status message
                  if (_isSharing && _shareStatus.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _shareStatus,
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

// Helper method for status check items
  Widget _buildStatusCheck(String title, bool isValid, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isValid
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isValid ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isValid
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isValid
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
            ),
          ),
          child: Text(
            isValid ? 'OK' : 'Failed',
            style: TextStyle(
              color: isValid ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> serverModifier(PitChecklistItem checklistData) {
    return {
      "type": "checklist",
      "matchKey": checklistData.matchkey,
      "chassisDriveMotors": checklistData.chassis_drive_motors,
      "chassisSteerMotors": checklistData.chassis_steer_motors,
      "chassisGearboxes": checklistData.chassis_gearboxes,
      "chassisTreadConditions": checklistData.chassis_tread_conditions,
      "chassisWires": checklistData.chassis_wires,
      "chassisBumpers": checklistData.chassis_bumpers,
      "chassisCamera": checklistData.chassis_camera,
      "chassisLimelightProtectors": checklistData.chassis_limelight_protectors,
      "ethernetFrontLeftLimelight": checklistData.ethernet_front_left_limelight,
      "ethernetFrontRightLimelight":
          checklistData.ethernet_front_right_limelight,
      "ethernetBackRightLimelight": checklistData.ethernet_back_right_limelight,
      "ethernetSwitch": checklistData.ethernet_switch,
      "ethernetRadio": checklistData.ethernet_radio,
      "climberString": checklistData.climber_string,
      "climberClips": checklistData.climber_clips,
      "climberSprings": checklistData.climber_springs,
      "climberBumper": checklistData.climber_bumper,
      "climberGearbox": checklistData.climber_gearbox,
      "climberMotors": checklistData.climber_motors,
      "climberWires": checklistData.climber_wires,
      "climberNutsAndBolts": checklistData.climber_nuts_and_bolts,
      "climberReset": checklistData.climber_reset,
      "climberNumber": checklistData.climber_hooks,
      "elevatorRodOfDoom": checklistData.elevator_rod_of_doom,
      "elevatorStage0": checklistData.elevator_stage_0,
      "elevatorStage1": checklistData.elevator_stage_1,
      "elevatorStage2": checklistData.elevator_stage_2,
      "elevatorChain": checklistData.elevator_chain,
      "elevatorGearbox": checklistData.elevator_gearbox,
      "elevatorMotors": checklistData.elevator_motors,
      "elevatorWires": checklistData.elevator_wires,
      "elevatorNutsAndBolts": checklistData.elevator_nuts_and_bolts,
      "trapdoorPanels": checklistData.trapdoor_panels,
      "trapdoorWires": checklistData.trapdoor_wires,
      "trapdoorSupports": checklistData.trapdoor_supports,
      "trapdoorHinges": checklistData.trapdoor_hinges,
      "trapdoorTensioners": checklistData.trapdoor_tensioners,
      "trapdoorNutsAndBolts": checklistData.trapdoor_nuts_and_bolts,
      "trapdoorReset": checklistData.trapdoor_reset,
      "carriageGearbox": checklistData.carriage_gearbox,
      "carriageBeltbox": checklistData.carriage_beltbox,
      "carriageMotors": checklistData.carriage_motors,
      "carriageWires": checklistData.carriage_wires,
      "carriageNutsAndBolts": checklistData.carriage_nuts_and_bolts,
      "carriageCoralSlide": checklistData.carriage_coral_slide,
      "carriageCarriage": checklistData.carriage_carriage,
      "gooseneckPanels": checklistData.gooseneck_panels,
      "gooseneckWheels": checklistData.gooseneck_wheels,
      "gooseneckBelts": checklistData.gooseneck_belts,
      "gooseneckNutsAndBolts": checklistData.gooseneck_nuts_and_bolts,
      "returningBatteryVoltage": checklistData.returning_battery_voltage,
      "returningBatteryCCA": checklistData.returning_battery_cca,
      "returningNumber": checklistData.returning_number,
      "outgoingBatteryVoltage": checklistData.outgoing_battery_voltage,
      "outgoingBatteryCCA": checklistData.outgoing_battery_cca,
      "outgoingNumber": checklistData.outgoing_number,
      "outgoingBatteryReplaced": checklistData.outgoing_battery_replaced,
      "allianceColor": checklistData.alliance_color,
      "notes": checklistData.note,
    };
  }
}
