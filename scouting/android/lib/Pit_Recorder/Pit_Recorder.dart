import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:scouting_app/Pit_Recorder/Send_Pitdata.dart';
import 'package:scouting_app/main.dart';
import 'package:scouting_app/services/DataBase.dart';

import 'CheckLists.dart';

class PitRecorder extends StatefulWidget {
  const PitRecorder({super.key});

  @override
  PitRecorderState createState() => PitRecorderState();
}

class PitRecorderState extends State<PitRecorder>
    with SingleTickerProviderStateMixin {
  List<Team> _teams = [];
  List<Team> _filteredTeams = [];
  List<int> _recorded_team = [];
  List<int> _assignedTeams = [];
  late AnimationController _animController;
  final TextEditingController _searchController = TextEditingController();
  bool _showScoutedOnly = false;
  bool _showUnscoutedOnly = false;
  bool _showAssignedOnly = false;

  @override
  void initState() {
    _recorded_team = PitDataBase.GetRecorderTeam();
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _initAssignments();
    _fetchTeams();
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _recorded_team = PitDataBase.GetRecorderTeam();
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterTeams(String query) {
    setState(() {
      _filteredTeams = _teams.where((team) {
        final matchesQuery = query.isEmpty ||
            team.nickname.toLowerCase().contains(query.toLowerCase()) ||
            team.teamNumber.toString().contains(query);
        final scouted = isScouted(team.teamNumber, _recorded_team);
        final assigned = _assignedTeams.contains(team.teamNumber);
        
        if (_showScoutedOnly) return matchesQuery && scouted;
        if (_showUnscoutedOnly) return matchesQuery && !scouted;
        if (_showAssignedOnly) return matchesQuery && assigned;
        return matchesQuery;
      }).toList();
    });
  }

  void _selectTeam(BuildContext context, Team team) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Record(team: team), fullscreenDialog: true),
    ).then((_) {
      // Refresh recorded teams when returning
      setState(() {
        _recorded_team = PitDataBase.GetRecorderTeam();
      });
    });
  }

  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Error',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'An error occurred while loading teams: $errorMessage\n\n'
              'To resolve this issue, please navigate to Settings > Load Match, '
              'enter the event key, and press Load Event. If the indicator turns green, '
              'you can return to the home screen and try again.',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _fetchTeams();
              },
              child: Text(
                'Retry',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _initAssignments() async {
    await _loadAssignments();
    _filterTeams(_searchController.text);
  }

  Future<void> _loadAssignments() async {
    final box = await Hive.openBox('pitAssignments');
    final assignments = box.get('assignedTeams');
    if (mounted) {
      setState(() {
        if (assignments is List) {
          _assignedTeams = List<int>.from(assignments);
        } else {
          _assignedTeams = [];
        }
      });
    }
  }

  void _toggleAssignment(int teamNumber) {
    if (!Hive.isBoxOpen('pitAssignments')) return;
    final box = Hive.box('pitAssignments');
    setState(() {
      if (_assignedTeams.contains(teamNumber)) {
        _assignedTeams.remove(teamNumber);
      } else {
        _assignedTeams.add(teamNumber);
      }
      box.put('assignedTeams', _assignedTeams);
    });
    _filterTeams(_searchController.text);
  }

  void _fetchTeams() async {
    try {
      List<Team> teams = await fetchTeams();
      setState(() {
        _teams = teams;
        _filteredTeams = teams;
      });
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = !islightmode();
    final scoutedCount =
        _teams.where((t) => isScouted(t.teamNumber, _recorded_team)).length;
    final totalCount = _teams.length;
    final progress = totalCount > 0 ? scoutedCount / totalCount : 0.0;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF111111) : const Color(0xFFF5F5F7),
      appBar: AppBar(
        leading: Builder(builder: (context) {
          return IconButton(
              icon: const Icon(Icons.arrow_back),
              color: dark ? Colors.white70 : Colors.black54,
              onPressed: () => Navigator.pop(context));
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            color: dark ? Colors.white70 : Colors.black54,
            onPressed: PitDataBase.LoadAll,
          ),
          IconButton(
              icon: const Icon(Icons.share_rounded),
              color: dark ? Colors.white70 : Colors.black54,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SharePITDataScreen(),
                  ),
                );
              }),
        ],
        backgroundColor: dark ? const Color(0xFF111111) : const Color(0xFFF5F5F7),
        elevation: 0,
        title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.red, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
            child: Text(
              'PIT Scouting',
              style: GoogleFonts.museoModerno(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            )),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ─── PROGRESS HEADER ───────────────────────────────
          FadeTransition(
            opacity: _animController,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: dark
                      ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                      : [Colors.blue.shade50, Colors.indigo.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: dark
                      ? Colors.blue.shade900.withOpacity(0.5)
                      : Colors.blue.shade100,
                ),
              ),
              child: Row(
                children: [
                  // Circular progress
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 5,
                          backgroundColor: dark
                              ? Colors.white12
                              : Colors.blue.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress == 1.0
                                ? Colors.green
                                : Colors.blue.shade600,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: GoogleFonts.museoModerno(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: dark ? Colors.white : Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$scoutedCount of $totalCount Teams Scouted',
                          style: GoogleFonts.museoModerno(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: dark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: dark
                                ? Colors.white12
                                : Colors.blue.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress == 1.0
                                  ? Colors.green
                                  : Colors.blue.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${totalCount - scoutedCount} remaining',
                          style: TextStyle(
                            fontSize: 12,
                            color: dark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── SEARCH & FILTER ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                color: dark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Search teams...',
                hintStyle: TextStyle(
                  color: dark ? Colors.white38 : Colors.black38,
                ),
                prefixIcon: Icon(Icons.search,
                    color: dark ? Colors.white54 : Colors.black45),
                suffixIcon: (_searchController.text.isNotEmpty || _showScoutedOnly || _showUnscoutedOnly || _showAssignedOnly)
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: dark ? Colors.white38 : Colors.black38),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _showScoutedOnly = false;
                            _showUnscoutedOnly = false;
                            _showAssignedOnly = false;
                          });
                          _filterTeams('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: dark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: dark ? Colors.white10 : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.blue.shade400,
                    width: 2,
                  ),
                ),
              ),
              onChanged: _filterTeams,
            ),
          ),

          // ─── FILTER CHIPS ─────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip('All', !_showScoutedOnly && !_showUnscoutedOnly && !_showAssignedOnly,
                    Colors.blue, dark, () {
                  setState(() {
                    _showScoutedOnly = false;
                    _showUnscoutedOnly = false;
                    _showAssignedOnly = false;
                  });
                  _filterTeams(_searchController.text);
                }),
                const SizedBox(width: 8),
                _buildFilterChip(
                    'Assigned (${_assignedTeams.length})',
                    _showAssignedOnly,
                    Colors.purple,
                    dark, () {
                  setState(() {
                    _showAssignedOnly = !_showAssignedOnly;
                    _showScoutedOnly = false;
                    _showUnscoutedOnly = false;
                  });
                  _filterTeams(_searchController.text);
                }),
                const SizedBox(width: 8),
                _buildFilterChip(
                    'Scouted ($scoutedCount)',
                    _showScoutedOnly,
                    Colors.green,
                    dark, () {
                  setState(() {
                    _showScoutedOnly = !_showScoutedOnly;
                    _showUnscoutedOnly = false;
                    _showAssignedOnly = false;
                  });
                  _filterTeams(_searchController.text);
                }),
                const SizedBox(width: 8),
                _buildFilterChip(
                    'Remaining (${totalCount - scoutedCount})',
                    _showUnscoutedOnly,
                    Colors.orange,
                    dark, () {
                  setState(() {
                    _showUnscoutedOnly = !_showUnscoutedOnly;
                    _showScoutedOnly = false;
                    _showAssignedOnly = false;
                  });
                  _filterTeams(_searchController.text);
                }),
              ],
            ),
          ),

          // ─── TEAM LIST ────────────────────────────────────
          Expanded(
            child: _filteredTeams.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 48,
                            color: dark ? Colors.white24 : Colors.black26),
                        const SizedBox(height: 12),
                        Text(
                          'No teams found',
                          style: TextStyle(
                            fontSize: 16,
                            color: dark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    itemCount: _filteredTeams.length,
                    itemBuilder: (context, index) {
                      final team = _filteredTeams[index];
                      final scouted =
                          isScouted(team.teamNumber, _recorded_team);
                      return Dismissible(
                        key: Key('team_${team.teamNumber}'),
                        direction: DismissDirection.horizontal,
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: Colors.green.shade600.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.assignment_ind, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: Colors.red.shade600.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.assignment_return, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            if (!_assignedTeams.contains(team.teamNumber)) {
                              _toggleAssignment(team.teamNumber);
                              ScaffoldMessenger.of(context).removeCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Assigned Team ${team.teamNumber}'),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.green.shade700,
                                ),
                              );
                            }
                          } else {
                            if (_assignedTeams.contains(team.teamNumber)) {
                              _toggleAssignment(team.teamNumber);
                              ScaffoldMessenger.of(context).removeCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Unassigned Team ${team.teamNumber}'),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.red.shade700,
                                ),
                              );
                            }
                          }
                          return false; // Don't actually remove from list
                        },
                        child: _buildTeamCard(team, scouted, dark, index),
                      );
                    },
                  ),
          ),

          // ─── DELETE BUTTON ────────────────────────────────
          _buildDeleteButton(dark),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String label, bool selected, Color color, bool dark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(dark ? 0.3 : 0.15)
              : (dark ? const Color(0xFF1E1E1E) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color.withOpacity(0.7) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.museoModerno(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? color
                : (dark ? Colors.white54 : Colors.black45),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamCard(Team team, bool scouted, bool dark, int index) {
    // Load existing pit data for preview
    PitRecord? existingRecord = PitDataBase.GetData(team.teamNumber);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: scouted ? 3 : 1,
        color: _assignedTeams.contains(team.teamNumber)
            ? (dark ? const Color(0xFF1E1E30) : Colors.indigo.shade50)
            : (dark ? const Color(0xFF1A1A1A) : Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: scouted
                ? Colors.green.withOpacity(0.5)
                : (dark ? Colors.white10 : Colors.grey.shade200),
            width: scouted ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _selectTeam(context, team),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Team number badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: scouted
                              ? [Colors.green.shade600, Colors.teal.shade500]
                              : [Colors.blue.shade700, Colors.blue.shade400],
                        ),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: (scouted ? Colors.green : Colors.blue)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          team.teamNumber.toString(),
                          style: GoogleFonts.museoModerno(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: team.teamNumber > 9999 ? 13 : 15,
                          ),
                        ),
                      ),
                    ),
                    if (_assignedTeams.contains(team.teamNumber))
                      Positioned(
                        top: -5,
                        right: -5,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                            border: Border.all(color: dark ? const Color(0xFF1A1A1A) : Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.star, size: 10, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // Team info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.nickname,
                        style: GoogleFonts.museoModerno(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: dark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 13,
                              color: dark ? Colors.white38 : Colors.black38),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              '${team.city}, ${team.stateProv}',
                              style: TextStyle(
                                fontSize: 12,
                                color: dark ? Colors.white38 : Colors.black45,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Data preview chips
                      if (scouted && existingRecord != null)
                        Wrap(
                          spacing: 6,
                          runSpacing: 3,
                          children: [
                            if (existingRecord.driveTrainType.isNotEmpty)
                              _miniChip(existingRecord.driveTrainType,
                                  Colors.blue, dark),
                            if (existingRecord.weight > 0)
                              _miniChip(
                                  '${existingRecord.weight.toStringAsFixed(0)} lbs',
                                  Colors.teal,
                                  dark),
                            if (existingRecord.speed > 0)
                              _miniChip(
                                  '${existingRecord.speed.toStringAsFixed(1)} ft/s',
                                  Colors.orange,
                                  dark),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Icon(Icons.edit_note,
                                size: 14,
                                color: dark ? Colors.white24 : Colors.black26),
                            const SizedBox(width: 4),
                            Text(
                              'Tap to start scouting',
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: dark ? Colors.white24 : Colors.black26,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Status indicator + chevron
                Column(
                  children: [
                    if (scouted)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.green, size: 18),
                      )
                    else
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: dark ? Colors.white24 : Colors.black26),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniChip(String label, Color color, bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(dark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDeleteButton(bool dark) {
    return GestureDetector(
      onTap: () async {
        int tapCount = 0;
        bool confirmed = false;
        while (tapCount < 5) {
          confirmed = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: dark ? const Color(0xFF1E1E1E) : Colors.white,
                title: Text('Confirm Delete',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: dark ? Colors.white : Colors.black,
                    )),
                content: Text(
                    'Are you sure you want to delete all data? Tap ${5 - tapCount} more times to confirm.',
                    style: TextStyle(
                      color: dark ? Colors.white70 : Colors.black87,
                    )),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Yes',
                        style: TextStyle(color: Colors.red)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('No',
                        style: TextStyle(
                            color: dark ? Colors.white54 : Colors.black54)),
                  ),
                ],
              );
            },
          );
          if (confirmed) {
            tapCount++;
          } else {
            break;
          }
        }
        if (tapCount == 5) {
          PitDataBase.ClearData();
          Hive.openBox('pitAssignments').then((box) => box.clear());
          setState(() {
            _recorded_team = PitDataBase.GetRecorderTeam();
            _assignedTeams = [];
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: dark
              ? Colors.red.shade900.withOpacity(0.3)
              : Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline,
                color: Colors.red.shade400, size: 18),
            const SizedBox(width: 8),
            Text(
              'Delete All Data',
              style: GoogleFonts.museoModerno(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<List<Team>> fetchTeams() async {
  var dd =
      '[{"team_number": 201, "nickname": "Team 1", "city": "City 1", "state_prov": "State 1", "country": "Country 1", "website": "Website 1"}, {"team_number": 2, "nickname": "Team 2", "city": "City 2", "state_prov": "State 2", "country": "Country 2", "website": "Website 2"}]';
  dd = await Hive.box('pitData').get('teams');
  List<dynamic> teamsJson = json.decode(dd);
  return teamsJson.map((json) => Team.fromJson(json)).toList();
}

bool isScouted(int teamNumber, List<int> recorderTeam) {
  return recorderTeam.contains(teamNumber);
}
