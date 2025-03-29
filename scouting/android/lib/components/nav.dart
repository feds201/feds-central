import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scouting_app/Experiment/experiment.dart';
import 'package:scouting_app/logs.dart';
import 'package:scouting_app/main.dart';
import '../services/Colors.dart';
import '../about_page.dart';
import '../Match_Pages/match_page.dart';
import '../settings_page.dart';
import '../home_page.dart';

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Drawer(
      backgroundColor: islightmode() ? lightColors.white : darkColors.goodblack,
      width: isLandscape
          ? MediaQuery.of(context).size.width * 0.3 // Half width in landscape
          : MediaQuery.of(context).size.width, // Full width otherwise
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red, Colors.grey, Colors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SizedBox(
              height: 300,
              width: double.infinity,
              // This makes the width of the header fill the drawer
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white30, // Red avatar background
                    radius: 30,
                    child: Image(
                        image: AssetImage('assets/logo.png'),
                        height: 50,
                        width: 50,
                        fit: BoxFit.fill),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'FEDS 201',
                    style: GoogleFonts.museoModerno(
                      fontSize: 24,
                      color: islightmode()
                          ? const Color.fromARGB(255, 255, 255, 255)
                          : invertColor(
                              const Color.fromARGB(255, 255, 255, 255)),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Scout Ops v.3.0.0',
                        style: GoogleFonts.museoModerno(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(width: 4),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color.fromARGB(255, 255, 17, 0),
                            Color.fromARGB(255, 0, 81, 148)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          'MK1',
                          style: GoogleFonts.museoModerno(
                            fontSize: 14,
                            color: const Color.fromARGB(255, 255, 255, 255),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.home_outlined,
                  title: 'Home',
                  page: const HomePage(),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.sports_score_outlined,
                  title: 'Match',
                  page: const MatchPage(),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.list_alt_outlined,
                  title: 'Logs',
                  page: const LogsPage(),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  page: const SettingsPage(),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.info_outline,
                  title: 'About',
                  page: const AboutPage(),
                ),
              ],
            ),
          ),
          _buildNavItem(context,
              icon: Icons.science_outlined,
              title: 'Experimental',
              page: const Experiment()),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context,
      {required IconData icon, required String title, required Widget page}) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      leading: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Colors.red, Colors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
      title: Text(
        title,
        style: GoogleFonts.museoModerno(
          fontSize: 18,
          color: !islightmode()
              ? const Color.fromARGB(255, 255, 255, 255)
              : invertColor(const Color.fromARGB(255, 255, 255, 255)),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }
}
