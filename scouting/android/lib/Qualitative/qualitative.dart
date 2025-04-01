import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:scouting_app/components/Insults.dart';
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
            backgroundColor:
                islightmode() ? lightColors.white : darkColors.goodblack,
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
        QualitativeDataBase.LoadAll();

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

        return _buildQualitativeMatchCard(
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

  Widget _buildQualitativeMatchCard(
    BuildContext context,
    dynamic match,
    String matchTypeName,
    IconData matchIcon,
    Color themeColor,
    int matchNumber,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: islightmode() ? Colors.white : Colors.grey[850],
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
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: themeColor.withOpacity(0.6),
                      size: 18,
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
