import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:scouting_app/Experiment/experiment.dart';
import 'package:scouting_app/logs.dart';
import 'package:scouting_app/main.dart';
import '../about_page.dart';
import '../Match_Pages/match_page.dart';
import '../Qualitative/qualitative.dart';
import '../Pit_Recorder/Pit_Recorder.dart';
import '../Pit_Checklist/Pit_Checklist.dart';
import '../settings_page.dart';
import '../home_page.dart';

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = !islightmode();
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final scouterName =
        Hive.box('settings').get('deviceName', defaultValue: 'Scout') ??
            'Scout';
    final alliance =
        Hive.box('userData').get('alliance', defaultValue: '') ?? '';

    return Drawer(
      backgroundColor: dark ? Colors.black : Colors.white,
      width: isLandscape
          ? MediaQuery.of(context).size.width * 0.35
          : MediaQuery.of(context).size.width,
      child: Column(
        children: [
          // ── HEADER (extends behind status bar) ─────
          _buildHeader(context, dark, scouterName, alliance),

          // ── SCROLLABLE NAV ITEMS ───────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              physics: const BouncingScrollPhysics(),
              children: [
                // ── SECTION: Scouting
                _buildSectionLabel('SCOUTING', dark),
                _buildNavTile(context, dark,
                    icon: Icons.home_rounded,
                    title: 'Home',
                    subtitle: 'Dashboard overview',
                    color: Colors.grey,
                    page: const HomePage()),
                _buildNavTile(context, dark,
                    icon: Icons.sports_score_rounded,
                    title: 'Match Scouting',
                    subtitle: 'Quantitative data',
                    color: Colors.blue,
                    page: const MatchPage()),
                _buildNavTile(context, dark,
                    icon: Icons.analytics_rounded,
                    title: 'Qualitative',
                    subtitle: 'Strategic analysis',
                    color: Colors.purple,
                    page: const Qualitative()),

                // ── SECTION: Pit
                _buildSectionLabel('PIT', dark),
                _buildNavTile(context, dark,
                    icon: Icons.precision_manufacturing_rounded,
                    title: 'Pit Scouting',
                    subtitle: 'Robot specifications',
                    color: Colors.teal,
                    page: const PitRecorder()),
                _buildNavTile(context, dark,
                    icon: Icons.checklist_rtl_rounded,
                    title: 'Pit Checklist',
                    subtitle: 'Pre-match inspections',
                    color: Colors.orange,
                    page: const PitCheckListPage()),

                // ── SECTION: Tools
                _buildSectionLabel('TOOLS', dark),
                _buildNavTile(context, dark,
                    icon: Icons.list_alt_rounded,
                    title: 'Logs',
                    subtitle: 'Match history',
                    color: Colors.indigo,
                    page: const LogsPage()),
              ],
            ),
          ),

          // ── BOTTOM ITEMS (pinned) ──────────────────
          Divider(
              color: dark ? Colors.white10 : Colors.grey.shade200, height: 1),
          _buildCompactTile(context, dark,
              icon: Icons.settings_rounded,
              title: 'Settings',
              page: const SettingsPage()),
          _buildCompactTile(context, dark,
              icon: Icons.info_outline_rounded,
              title: 'About',
              page: const AboutPage()),
          _buildCompactTile(context, dark,
              icon: Icons.science_rounded,
              title: 'Experimental',
              page: const Experiment()),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────
  Widget _buildHeader(
      BuildContext context, bool dark, String scouterName, String alliance) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, statusBarHeight + 12, 20, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [
                  const Color.fromARGB(255, 194, 82, 82),
                  const Color.fromARGB(255, 88, 88, 180),
                ]
              : [
                  const Color.fromARGB(255, 255, 3, 3),
                  const Color.fromARGB(255, 0, 119, 255),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // ── Logo + Title side-by-side
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38, width: 2),
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.white12,
                  radius: 24,
                  child: Image(
                    image: AssetImage('assets/logo.png'),
                    height: 34,
                    width: 34,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FEDS 201',
                      style: GoogleFonts.museoModerno(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Scout Ops v5.0.0',
                          style: GoogleFonts.museoModerno(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF1100), Color(0xFF005194)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'MK2',
                            style: GoogleFonts.museoModerno(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Scouter info bar — full width
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Person icon + name
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.person_rounded,
                      size: 18, color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Scout',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.5),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        scouterName,
                        style: GoogleFonts.museoModerno(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                    ],
                  ),
                ),

                // Alliance badge
                if (alliance.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (alliance.toLowerCase() == 'red'
                              ? Colors.red
                              : Colors.blue)
                          .withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (alliance.toLowerCase() == 'red'
                                ? Colors.redAccent
                                : Colors.blueAccent)
                            .withOpacity(0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: alliance.toLowerCase() == 'red'
                                ? Colors.redAccent
                                : Colors.blueAccent,
                            boxShadow: [
                              BoxShadow(
                                color: (alliance.toLowerCase() == 'red'
                                        ? Colors.red
                                        : Colors.blue)
                                    .withOpacity(0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          alliance.toUpperCase(),
                          style: GoogleFonts.museoModerno(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION LABEL ──────────────────────────────────────
  Widget _buildSectionLabel(String label, bool dark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: Text(
        label,
        style: GoogleFonts.museoModerno(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: dark ? Colors.white30 : Colors.grey.shade500,
          letterSpacing: 1.8,
        ),
      ),
    );
  }

  // ─── PRIMARY NAV TILE ───────────────────────────────────
  Widget _buildNavTile(BuildContext context, bool dark,
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required Widget page}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          onTap: () {
            Navigator.pop(context); // close drawer
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Icon container with colored background
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(dark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.museoModerno(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: dark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: dark ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: dark ? Colors.white : Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── COMPACT BOTTOM TILE ────────────────────────────────
  Widget _buildCompactTile(BuildContext context, bool dark,
      {required IconData icon, required String title, required Widget page}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          splashColor: Colors.grey.withOpacity(0.1),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(icon,
                    size: 20,
                    color: dark ? Colors.white38 : Colors.grey.shade600),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: GoogleFonts.museoModerno(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: dark ? Colors.white54 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
