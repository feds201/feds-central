import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../templateBuilder/builder.dart';
import 'components/nav.dart';
import 'match_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        drawer: const NavBar(),
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.extension),
              onPressed: () {
                // Navigate to the search page
              },
            ),
          ],
        ),
        body: homePage(),
        bottomSheet: _buildPersistentBottomSheet(),
      ),
    );
  }

  Widget _buildPersistentBottomSheet() {
    return BottomSheet(
      onClosing: () {},
      builder: (BuildContext context) {
        return Container(
          height: 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Center(
                  child: Column(
                    children: [
                      buildButton(
                        context: context,
                        text: 'Start a match',
                        color: Colors.green.shade100,
                        borderColor: Colors.green.shade800,
                        icon: Icons.play_arrow_outlined,
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const MatchPage()));
                        },
                      ),
                      const SizedBox(height: 10),
                      buildButton(
                        context: context,
                        text: 'Record pit data',
                        color: Colors.blue.shade100,
                        borderColor: Colors.blueAccent,
                        icon: Icons.bookmark_add_outlined,
                        onPressed: () {
                          // Navigator.push(context, MaterialPageRoute(builder: (context) => const Te()));
                          },
                      ),
                      const SizedBox(height: 10),
                      buildButton(
                        context: context,
                        text: 'Create a template',
                        color: Colors.red.shade100,
                        borderColor: Colors.redAccent,
                        icon: Icons.style_outlined,
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => TemplateEditor()));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget homePage() {
    return HOME();
  }

  Widget HOME() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0, left: 30.0),
          child: Text(
            'Scouting',
            style: GoogleFonts.chivoMono(
              fontSize: 60,
              fontWeight: FontWeight.w100,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 30.0),
          child: Text(
            'CREATED BY PYINTEL',
            style: GoogleFonts.chivoMono(
              fontSize: 20,
              fontWeight: FontWeight.w100,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget buildButton({
    required BuildContext context,
    required String text,
    required Color color,
    Color? borderColor,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width - 60,
      height: 70,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: borderColor != null
                ? BorderSide(color: borderColor)
                : BorderSide.none,
          ),
        ),
        icon: Icon(icon, size: 24),
        label: Text(
          text,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
