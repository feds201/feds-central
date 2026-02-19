import 'dart:convert';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:scouting_app/Qualitative/qualitative.dart';
import 'package:scouting_app/components/Facts.dart';
import 'package:scouting_app/components/Inspiration.dart';
import 'package:scouting_app/components/MatchSelection.dart';
import 'package:scouting_app/components/ScoutersList.dart';
import 'package:scouting_app/home_page.dart';
import 'package:scouting_app/main.dart';

import '../services/Colors.dart';
import '../services/DataBase.dart';
import 'match.dart';

class MatchPage extends StatefulWidget {
  const MatchPage({super.key});

  @override
  MatchPageState createState() => MatchPageState();
}

class MatchPageState extends State<MatchPage>
    with SingleTickerProviderStateMixin {
  late int selectedMatchType;
  late AnimationController _animationController;
  final _scrollController = ScrollController();
  final Battery _battery = Battery();

  @override
  void initState() {
    super.initState();
    selectedMatchType = 0;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    // Load default data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDefaultDataIfNeeded();
      MatchDataBase.LoadAll();
      setState(() {});
    });
  }

  Future<void> _loadDefaultDataIfNeeded() async {
    try {
      String jsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/response.json');
      var defaultData = jsonDecode(jsonString);
      Hive.box('matchData').put('matches', defaultData);
      setState(() {}); // Trigger rebuild to show the loaded data
    } catch (e) {
      print('Error loading default match data: $e');
    }
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
      // Load default data from assets
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDefaultDataIfNeeded();
      });
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
            'Match Scouting',
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
            'Loading Default Match Data...',
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
              'Default match data is being loaded from assets',
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
            indicatorShape: SnakeShapeBorder(),
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

        VerticalDivider(
          thickness: 1,
          width: 1,
          color: islightmode() ? lightColors.white : darkColors.goodblack,
        ),
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
        // Using the existing settings page implementation
        return _buildSettingsView(matches);

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
              'No $matchTypeName Matches',
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

    bool isScouted = MatchDataBase.GetData(match['key'].toString()) != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        color: islightmode() ? Colors.white : Colors.grey[850],
        shadowColor: themeColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isScouted ? Colors.green : themeColor.withOpacity(0.2),
            width: isScouted ? 2 : 1,
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
                // Header row with match number and icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isScouted
                            ? Colors.green.withOpacity(0.1)
                            : themeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isScouted ? Icons.check_circle : matchIcon,
                        color: isScouted ? Colors.green : themeColor,
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
                              color: isScouted ? Colors.green : themeColor,
                            ),
                          ),
                          Text(
                            isScouted ? 'Scouted' : '$matchTypeName Match',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  islightmode() ? Colors.black : Colors.white,
                              fontWeight: isScouted
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
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

                // Alliance information
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
                          ...redAlliance
                              .map((team) => Padding(
                                    padding:
                                        const EdgeInsets.only(left: 20, top: 2),
                                    child: Text(
                                      team,
                                      style: TextStyle(
                                        color: islightmode()
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ),
                                  ))
                              .toList(),
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
                          ...blueAlliance
                              .map((team) => Padding(
                                    padding:
                                        const EdgeInsets.only(left: 20, top: 2),
                                    child: Text(
                                      team,
                                      style: TextStyle(
                                        color: islightmode()
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ),
                                  ))
                              .toList(),
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

  Future<int> _getBatteryPercentage() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      return batteryLevel;
    } catch (e) {
      print('Battery plugin unavailable, using fallback: $e');
      try {
        // Fallback: return a reasonable default
        // You may want to implement platform channels for a proper solution
        return 85; // Safe default battery level
      } catch (fallbackError) {
        print('Fallback error: $fallbackError');
        return 85;
      }
    }
  }

  void _handleMatchSelection(dynamic match) async {
    String _scouterName =
        Hive.box('settings').get('deviceName', defaultValue: 'Scout');
    String _allianceColor =
        (Hive.box('userData').get('alliance', defaultValue: 'Red') ?? 'Red')
            .toString()
            .trim();
    String _station =
        (Hive.box('userData').get('position', defaultValue: '1') ?? '1')
            .toString()
            .trim();

    // Ensure non-empty values
    if (_allianceColor.isEmpty) _allianceColor = 'Red';
    if (_station.isEmpty) _station = '1';

    // Safely get the team number based on alliance and position
    String teamNNumber;
    try {
      if (match == null || match['alliances'] == null) {
        throw Exception('Match data is invalid or missing alliances');
      }
      var allianceData = match['alliances'][_allianceColor.toLowerCase()];
      if (allianceData == null) {
        throw Exception('Alliance data is invalid for $_allianceColor');
      }
      var teamKeys = allianceData['team_keys'] as List<dynamic>?;
      if (teamKeys == null || teamKeys.isEmpty) {
        // Use default team numbers if missing
        teamKeys = ['frc0000', 'frc0001', 'frc0002'];
      }
      int positionIndex = int.parse(_station) - 1;
      if (positionIndex < 0 || positionIndex >= teamKeys.length) {
        positionIndex = 0; // Default to first position
      }
      teamNNumber = teamKeys[positionIndex].toString();
    } catch (e) {
      // Handle any errors in accessing team keys
      print('Error accessing team keys: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Unable to determine team number - $e')),
      );
      return;
    }

    // Get actual battery percentage
    int batteryPercentage = await _getBatteryPercentage();

    // Check if match is already scouted
    String matchKey = match['key'].toString();
    var existingData = MatchDataBase.GetData(matchKey);

    MatchRecord matchRecord;

    if (existingData != null) {
      matchRecord = MatchRecord.fromJson(existingData);
      // Ensure we have a valid battery percentage even if loaded from disk
      // matchRecord.batteryPercentage = batteryPercentage; // matchRecord is final fields though?
      // MatchRecord fields are final. So we accept the saved one, or we interpret fromJson.
      // The existing MatchRecord has all fields final except scouterName and auton/tele/end points.
    } else {
      matchRecord = MatchRecord(
        AutonPoints(false, false, false, 0.0, 0, false, "",
            BotLocation(const Offset(0, 0), const Size(0, 0), 0), false),
        TeleOpPoints(
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0,
            0,
            0,
            0,
            0,
            0,
            false,
            false,
            false,
            false,
            false,
            0,
            0,
            0,
            0,
            0,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false),
        EndPoints(0, false, false, false, "", 0.0, 0, []),
        teamNumber: teamNNumber.replaceAll('frc', ''),
        scouterName: _scouterName,
        matchKey: match['key'].toString(),
        allianceColor: _allianceColor,
        station: int.parse(_station),
        matchNumber: match['match_number'],
        eventKey: match['event_key'],
        batteryPercentage: batteryPercentage,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Match(matchRecord: matchRecord),
          fullscreenDialog: true),
    ).then((_) {
      print('Returned to Match Page');
      setState(() {
        // Refresh to update Scouted status icons
      });
    });
  }

  Widget _buildSettingsView(List<dynamic> allMatches) {
    // Extract event information
    int totalMatches = allMatches.length;
    int qualMatches = allMatches.where((m) => m['comp_level'] == 'qm').length;
    int playoffMatches =
        allMatches.where((m) => m['comp_level'] == 'sf').length;
    int finalMatches = allMatches.where((m) => m['comp_level'] == 'f').length;

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

          // Event Information Card with enhanced visual appeal
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

          // Match Statistics Card with enhanced visual appeal
          Card(
            color: islightmode()
                ? Colors.white
                : const Color.fromARGB(255, 33, 31, 31),
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

          // Scouter Configuration with enhanced visual appeal
          Card(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            color: islightmode()
                ? Colors.white
                : const Color.fromARGB(255, 33, 31, 31),
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
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color:
                                    islightmode() ? Colors.black : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Hive.box('userData').get('alliance') ==
                                        'Red'
                                    ? Colors.red.withOpacity(0.2)
                                    : Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${Hive.box('userData').get('alliance', defaultValue: 'Red')} Alliance - Position ${Hive.box('userData').get('position', defaultValue: '1')}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Hive.box('userData').get('alliance') ==
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
            color: !islightmode()
                ? Colors.white
                : const Color.fromARGB(255, 33, 31, 31),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: !islightmode()
                ? color.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
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
}
