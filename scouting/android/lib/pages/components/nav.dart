import 'package:flutter/material.dart';

import '../about_page.dart';
import '../home_page.dart';
import '../logs.dart';
import '../match_page.dart';
import '../settings_page.dart';

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListView(
        padding: const EdgeInsets.all(0),
        physics: const BouncingScrollPhysics(),
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              color: Color.fromARGB(255, 51, 109, 216),
            ),
            child: Column(
              // Use a Column to arrange heading and description vertically
              children: [
                Text(
                  'FEDS 2024', // Heading
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ), // Removed italic for a stronger heading
                ),
                SizedBox(
                    height: 1), // Add spacing between heading and description
                Text(
                  'Scouting App', // Description
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16, // Reduced font size for description
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('Home'),
            tileColor: const Color.fromARGB(255, 185, 206, 252),
            minVerticalPadding: 20,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            selectedColor: const Color.fromARGB(255, 0, 55, 173),
            onTap: () {
              Navigator.push(
                  context,
                  // MaterialPageRoute(builder: (context) => const HomePage()),
                  MaterialPageRoute(builder: (context) => const HomePage()));
            },
          ),
          const SizedBox(height: 5),
          ListTile(
            title: const Text('Match'),
            tileColor: const Color.fromARGB(255, 185, 206, 252),
            minVerticalPadding: 20,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MatchPage()),
              );
            },
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 5),
          ListTile(
            title: const Text('Logs'),
            tileColor: const Color.fromARGB(255, 185, 206, 252),
            minVerticalPadding: 20,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LogsPage()),
              );
            },
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 5),
          ListTile(
            title: const Text('Settings'),
            tileColor: const Color.fromARGB(255, 185, 206, 252),
            minVerticalPadding: 20,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 5),
          ListTile(
            title: const Text('About'),
            tileColor: const Color.fromARGB(255, 185, 206, 252),
            minVerticalPadding: 20,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ],
      ),
    );
  }
}
