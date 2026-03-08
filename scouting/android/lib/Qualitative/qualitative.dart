import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:scouting_app/components/Facts.dart';
import 'package:scouting_app/home_page.dart';
import 'package:scouting_app/Qualitative/QualitativePage.dart';
import 'package:scouting_app/main.dart';
import '../services/Colors.dart';
import '../services/DataBase.dart';

class Qualitative extends StatefulWidget {
  const Qualitative({super.key});

  @override
  QualitativeState createState() => QualitativeState();
}

class QualitativeState extends State<Qualitative>
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
    var manualData = _loadManualMatches();

    List<dynamic> allMatches = [];
    if (data != null) {
      allMatches.addAll(jsonDecode(jsonEncode(data)));
    }
    allMatches.addAll(manualData);

    return Scaffold(
      backgroundColor: islightmode() ? lightColors.white : darkColors.goodblack,
      appBar: _buildAppBar(),
      body: matchSelection(context, selectedMatchType, (int index) {
        setState(() {
          selectedMatchType = index;
          _animationController.reset();
          _animationController.forward();
        });
      }, allMatches),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      leading: Builder(builder: (context) {
        return IconButton(
            icon: const Icon(Icons.menu),
            color: !islightmode()
                ? const Color.fromARGB(193, 219, 196, 196)
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
            'Qualitative Scouting',
            style: GoogleFonts.museoModerno(
              fontSize: 30,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          )),
      centerTitle: true,
    );
  }

  Widget matchSelection(BuildContext context, int currentSelectedMatchType,
      Function onMatchTypeSelected, List<dynamic> allMatches) {
    return Row(
      children: [
        // Enhanced Navigation Rail
        Container(
          decoration: BoxDecoration(
            color: islightmode()
                ? Colors.white
                : Colors
                    .black, // Pure black background for Container in dark mode
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: NavigationRail(
            backgroundColor: islightmode()
                ? lightColors.white
                : Colors
                    .black, // Pure black background for NavigationRail in dark mode
            selectedIndex: currentSelectedMatchType,
            onDestinationSelected: (int index) {
              onMatchTypeSelected(index);
            },
            indicatorShape: SnakeShapeBorder(),
            labelType: NavigationRailLabelType.all,
            selectedLabelTextStyle: GoogleFonts.museoModerno(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelTextStyle: GoogleFonts.museoModerno(
              color:
                  islightmode() ? Colors.grey.shade600 : Colors.grey.shade400,
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
            child: _buildMatchList(currentSelectedMatchType, allMatches),
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

  Widget _buildMatchList(int selectedMatchType, List<dynamic> matches) {
    switch (selectedMatchType) {
      case 0:
        var filteredMatches = matches
            .where((match) => match['comp_level'] == 'qm')
            .toList()
          ..sort((a, b) => int.parse(a['match_number'].toString())
              .compareTo(int.parse(b['match_number'].toString())));
        QualitativeDataBase.LoadAll();

        return _buildMatchListView(
          filteredMatches,
          'Qualification',
          Icons.sports_soccer,
          Colors.blue,
          (match) => int.parse(match['match_number'].toString()),
        );

      case 1:
        var filteredMatches = matches
            .where((match) =>
                match['comp_level'] == 'sf' ||
                match['comp_level'] == 'f' ||
                match['comp_level'] == 'qf')
            .toList()
          ..sort((a, b) {
            // First sort by comp_level (qf before sf before f)
            int getCompLevelValue(String comp) {
              if (comp.startsWith('qf')) return 0;
              if (comp.startsWith('sf')) return 1;
              if (comp.startsWith('f')) return 2;
              return 3;
            }

            int compLevelComparison = getCompLevelValue(a['comp_level'])
                .compareTo(getCompLevelValue(b['comp_level']));
            if (compLevelComparison != 0) return compLevelComparison;

            int aValue = a['comp_level'].startsWith('sf') ||
                    a['comp_level'].startsWith('qf')
                ? (a['set_number'] != null
                    ? int.parse(a['set_number'].toString())
                    : 1)
                : int.parse(a['match_number'].toString());
            int bValue = b['comp_level'].startsWith('sf') ||
                    b['comp_level'].startsWith('qf')
                ? (b['set_number'] != null
                    ? int.parse(b['set_number'].toString())
                    : 1)
                : int.parse(b['match_number'].toString());

            int setComparison = aValue.compareTo(bValue);
            if (setComparison != 0) return setComparison;

            int aMatch = int.parse(a['match_number'].toString());
            int bMatch = int.parse(b['match_number'].toString());
            return aMatch.compareTo(bMatch);
          });

        return _buildPlayoffMatchListView(
          filteredMatches,
          'Playoff',
          Icons.sports_basketball,
          Colors.orange,
          (match) => match['comp_level'].startsWith('sf') ||
                  match['comp_level'].startsWith('qf')
              ? (match['set_number'] != null
                  ? int.parse(match['set_number'].toString())
                  : int.parse(match['match_number'].toString()))
              : int.parse(match['match_number'].toString()),
        );

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
                color:
                    islightmode() ? Colors.grey.shade600 : Colors.grey.shade400,
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

        String dynamicMatchTypeName = matchTypeName;
        if (matchTypeName == 'Playoff' && match['comp_level'] != null) {
          String comp = match['comp_level'].toString();
          if (comp.startsWith('f')) {
            dynamicMatchTypeName = 'Final';
          } else if (comp.startsWith('sf')) {
            dynamicMatchTypeName = 'Semifinal';
          } else if (comp.startsWith('qf')) {
            dynamicMatchTypeName = 'Quarterfinal';
          }
        }

        return _buildQualitativeMatchCard(
          context,
          match,
          dynamicMatchTypeName,
          matchIcon,
          themeColor,
          matchNumber,
          index,
        );
      },
    );
  }

  Widget _buildPlayoffMatchListView(
    List<dynamic> matches,
    String matchTypeName,
    IconData matchIcon,
    Color themeColor,
    Function(dynamic) getMatchNumber,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Create Manual Match'),
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
                        'No $matchTypeName Matches',
                        style: GoogleFonts.museoModerno(
                          fontSize: 20,
                          color: islightmode()
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
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
                    final bool isManual = match['manual_entry'] == true;

                    String dynamicMatchTypeName = matchTypeName;
                    if (matchTypeName == 'Playoff' &&
                        match['comp_level'] != null) {
                      String comp = match['comp_level'].toString();
                      if (comp.startsWith('f')) {
                        dynamicMatchTypeName = 'Final';
                      } else if (comp.startsWith('sf')) {
                        dynamicMatchTypeName = 'Semifinal';
                      } else if (comp.startsWith('qf')) {
                        dynamicMatchTypeName = 'Quarterfinal';
                      }
                    }

                    final card = _buildQualitativeMatchCard(
                      context,
                      match,
                      dynamicMatchTypeName,
                      matchIcon,
                      themeColor,
                      matchNumber,
                      index,
                    );

                    if (isManual) {
                      return Dismissible(
                        key: Key(match['key']?.toString() ?? 'manual_$index'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_outline,
                                  color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: islightmode()
                                      ? Colors.white
                                      : Colors.grey.shade900,
                                  title: Text('Delete Match?',
                                      style: TextStyle(
                                          color: islightmode()
                                              ? Colors.black
                                              : Colors.white)),
                                  content: Text(
                                      'Are you sure you want to remove this manual match entry?',
                                      style: TextStyle(
                                          color: islightmode()
                                              ? Colors.black87
                                              : Colors.white70)),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('CANCEL'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text('DELETE',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                        },
                        onDismissed: (direction) {
                          _deleteManualMatch(match['key']);
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Manual match removed')),
                          );
                        },
                        child: card,
                      );
                    }

                    return card;
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildQualitativeMatchCard(
    BuildContext context,
    dynamic match,
    String matchTypeName,
    IconData matchIcon,
    Color themeColor,
    int matchNumber,
    int index,
  ) {
    QualitativeDataBase.LoadAll();
    bool isCompleted = QualitativeDataBase.GetData(match['key']) != null;

    List<dynamic> redTeams = match['alliances']?['red']?['team_keys'] ?? [];
    List<dynamic> blueTeams = match['alliances']?['blue']?['team_keys'] ?? [];

    String formatTeamList(List<dynamic> teams) {
      return teams.map((t) => t.toString().replaceAll('frc', '')).join(', ');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: isCompleted
            ? (islightmode()
                ? Colors.green.withOpacity(0.1)
                : Colors.green.withOpacity(0.05))
            : (islightmode() ? Colors.white : darkColors.goodblack),
        elevation: 4,
        shadowColor: themeColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isCompleted
                ? Colors.green.withOpacity(0.5)
                : themeColor.withOpacity(0.2),
            width: isCompleted ? 2.0 : 1.0,
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
                        color: themeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_circle : matchIcon,
                        color: isCompleted ? Colors.green : themeColor,
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
                              color: isCompleted
                                  ? Colors.green.shade700
                                  : themeColor,
                            ),
                          ),
                          Text(
                            '$matchTypeName Match',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  islightmode() ? Colors.black : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'COMPLETED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: themeColor.withOpacity(0.6),
                        size: 18,
                      ),
                  ],
                ),
                if (redTeams.isNotEmpty || blueTeams.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Alliance Teams Row
                  Row(
                    children: [
                      // Red Alliance
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Red Alliance',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatTeamList(redTeams),
                              style: TextStyle(
                                fontSize: 13,
                                color: islightmode()
                                    ? Colors.black87
                                    : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // VS divider
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'VS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),

                      // Blue Alliance
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Blue Alliance',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatTeamList(blueTeams),
                              style: TextStyle(
                                fontSize: 13,
                                color: islightmode()
                                    ? Colors.black87
                                    : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleMatchSelection(dynamic match) {
    String _scouterName = Hive.box('settings').get('deviceName');
    String _allianceColor = Hive.box('userData').get('alliance');

    try {
      print("${match['key']}");
      print(QualitativeDataBase.GetData(match['key']));
      QualitativeRecord value =
          QualitativeRecord.fromJson(QualitativeDataBase.GetData(match['key']));
      print(value);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QualitativePage(
            record: value,
          ),
        ),
      ).then((value) {
        if (value != null && value == true) {
          setState(() {});
        }
      });
    } catch (e) {
      print("Oops: $e");
      QualitativeRecord record = QualitativeRecord(
        scouterName: _scouterName,
        matchKey: match['key'],
        alliance: _allianceColor,
        matchNumber: match['match_number'],
        q1: '',
        q2: '',
        q3: '',
        q4: '',
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QualitativePage(
            record: record,
          ),
        ),
      ).then((value) {
        if (value != null && value == true) {
          setState(() {});
        }
      });
    }
  }

  // --- Manual Match Management ---

  List<dynamic> _loadManualMatches() {
    final box = Hive.box('matchData');
    final existingData = box.get('manualMatches');
    if (existingData != null) {
      try {
        return jsonDecode(existingData);
      } catch (e) {
        print('Error loading manual matches: $e');
      }
    }
    return [];
  }

  void _saveManualMatch(dynamic match) {
    final box = Hive.box('matchData');
    List<dynamic> manualMatches = _loadManualMatches();

    int existingIndex =
        manualMatches.indexWhere((m) => m['key'] == match['key']);
    if (existingIndex >= 0) {
      manualMatches[existingIndex] = match;
    } else {
      manualMatches.add(match);
    }

    box.put('manualMatches', jsonEncode(manualMatches));
  }

  void _deleteManualMatch(String matchKey) {
    final box = Hive.box('matchData');
    List<dynamic> manualMatches = _loadManualMatches();
    manualMatches.removeWhere((m) => m['key'] == matchKey);
    box.put('manualMatches', jsonEncode(manualMatches));
  }

  void _showCreatePlayoffMatchDialog(BuildContext context) {
    String selectedMatchLevel = 'sf';
    int matchNumber = 1;
    int setNumber = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String matchPreview =
                "2026txbel_${selectedMatchLevel}${selectedMatchLevel == 'f' ? '' : setNumber}m$matchNumber";

            return AlertDialog(
              backgroundColor:
                  islightmode() ? Colors.white : Colors.grey.shade900,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text('Create Manual Match',
                  style: GoogleFonts.museoModerno(
                      color: islightmode() ? Colors.black : Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedMatchLevel,
                      dropdownColor:
                          islightmode() ? Colors.white : Colors.grey.shade900,
                      decoration:
                          const InputDecoration(labelText: 'Match Level'),
                      items: const [
                        DropdownMenuItem(
                            value: 'qf', child: Text('Quarterfinal')),
                        DropdownMenuItem(value: 'sf', child: Text('Semifinal')),
                        DropdownMenuItem(value: 'f', child: Text('Final')),
                        DropdownMenuItem(
                            value: 'practice', child: Text('Practice')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedMatchLevel = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (selectedMatchLevel != 'f') ...[
                      TextFormField(
                        initialValue: setNumber.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Set / Group Number'),
                        onChanged: (val) {
                          setDialogState(
                              () => setNumber = int.tryParse(val) ?? setNumber);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      initialValue: matchNumber.toString(),
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Match Number'),
                      onChanged: (val) {
                        setDialogState(() =>
                            matchNumber = int.tryParse(val) ?? matchNumber);
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Match Key: $matchPreview',
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Create manual match object
                    final manualMatch = {
                      'key': matchPreview,
                      'match_number': matchNumber,
                      'set_number': setNumber,
                      'comp_level': selectedMatchLevel,
                      'event_key': '2026txbel',
                      'manual_entry': true,
                      'alliances': {
                        'red': {'team_keys': []},
                        'blue': {'team_keys': []}
                      }
                    };

                    _saveManualMatch(manualMatch);
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text('CREATE'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class SnakeShapeBorder extends ShapeBorder {
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path();
    path.moveTo(rect.left, rect.top + rect.height * 0.2);
    path.quadraticBezierTo(rect.width * 0.2, rect.top, rect.width * 0.5,
        rect.top + rect.height * 0.3);
    path.quadraticBezierTo(rect.width * 0.8, rect.top + rect.height * 0.6,
        rect.right, rect.top + rect.height * 0.5);
    path.quadraticBezierTo(rect.width * 0.8, rect.bottom, rect.width * 0.5,
        rect.bottom - rect.height * 0.3);
    path.quadraticBezierTo(rect.width * 0.2, rect.bottom - rect.height * 0.6,
        rect.left, rect.bottom - rect.height * 0.2);
    path.close();
    return path;
  }

  @override
  ShapeBorder scale(double t) => this;

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final Paint paint = Paint()..color = Colors.green.withOpacity(0.5);
    canvas.drawPath(getOuterPath(rect), paint);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    throw UnimplementedError();
  }
}
