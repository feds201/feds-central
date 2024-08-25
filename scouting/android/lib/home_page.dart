import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

import 'Match_Pages/match_page.dart';
import 'Pit_Recorder/Pit_Recorder.dart';
import 'Plugins/plugins.dart';
import 'References.dart';
import 'components/Animator/GridPainter.dart';
import 'components/Button.dart';
import 'components/nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        drawer: const NavBar(), // Drawer navigation
        body: Stack(
          children: [
            const Positioned.fill(
              child: WaveGrid(), // Animated Background
            ),
            Column(
              children: [
                _buildCustomAppBar(context), // Custom AppBar with animation
                Expanded(child: homePage()), // Main content area
              ],
            ),
          ],
        ),
        bottomSheet: _buildPersistentBottomSheet(),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent, // Transparent to show the animation
      elevation: 0, // Remove shadow for a cleaner look
      actions: [
        IconButton(
          icon: const Icon(Icons.attach_file_rounded),
          onPressed: () {
            Route route =
                MaterialPageRoute(builder: (context) => InfiniteZoomImage());
            Navigator.push(context, route);
          },
        ),
        IconButton(
          icon: const Icon(Icons.extension),
          onPressed: () {
            Route route =
                MaterialPageRoute(builder: (context) => const Plugins());
            Navigator.push(context, route);
          },
        ),
      ],
    );
  }

  Widget _buildPersistentBottomSheet() {
    return BottomSheet(
      onClosing: () {},
      builder: (BuildContext context) {
        return Container(
          height: 200,
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
                const SizedBox(height: 5),
                buildButton(
                  context: context,
                  text: 'Start a match',
                  color: Colors.green.shade100,
                  borderColor: Colors.green.shade800,
                  icon: Icons.play_arrow_outlined,
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MatchPage()));
                  },
                ),
                const SizedBox(height: 5),
                buildButton(
                  context: context,
                  text: 'Record Pit',
                  color: Colors.blue.shade100,
                  borderColor: Colors.blueAccent,
                  icon: Icons.bookmark_add_outlined,
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Pit_Recorder()));
                  },
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
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.red, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              'Scout-Ops',
              style: GoogleFonts.chivoMono(
                fontSize: 70,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 30.0),
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.red, Colors.blue, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Row(
              children: [
                Text(
                  'DEVELOPED BY ',
                  style: GoogleFonts.chivoMono(
                    fontSize: 20,
                    fontWeight: FontWeight.w100,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'FEDS201',
                  style: GoogleFonts.chivoMono(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
