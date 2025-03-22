import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scouting_app/Pit_Checklist/CheckLists.dart';
import 'package:scouting_app/Pit_Checklist/Pit_Checklist.dart';
import 'package:scouting_app/Qualitative/qualitative.dart';
import 'package:scouting_app/services/DataBase.dart';

import 'Experiment/ExpStateManager.dart';
import 'Match_Pages/match_page.dart';
import 'Pit_Recorder/Pit_Recorder.dart';
import 'Plugins/plugins.dart';
import 'References.dart';
import 'components/Animator/GridPainter.dart';
import 'components/Button.dart';
import 'components/nav.dart';
import 'main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  bool isExperimentBoxOpen = false;
  bool isCardBuilderOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: Colors.red,
      end: Colors.blue,
    ).animate(_controller);

    _checkExperimentBox();
  }

  Future<void> _checkExperimentBox() async {
    bool isOpen = await isExperimentBoxOpenFunc();
    bool isCardBuilderOpen = await isCardBuilderOpenFunc();
    setState(() {
      isExperimentBoxOpen = isOpen;
      isCardBuilderOpen = isCardBuilderOpen;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor:
            isdarkmode() ? const Color(0xFFFFFFFF) : const Color(0xFF151515),
      ),
      home: Scaffold(
        drawer: const NavBar(),
        body: Stack(
          children: [
            const Positioned.fill(
              child: WaveGrid(),
            ),
            Column(
              children: [
                _buildCustomAppBar(context),
                Expanded(child: homePage()),
              ],
            ),
          ],
        ),
        bottomSheet: _buildPersistentBottomSheet(),
      ),
    );
  }

  Widget _buildPersistentBottomSheet() {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return BottomSheet(
          enableDrag: false,
          onClosing: () {},
          builder: (BuildContext context) {
            List<Widget> children = [
              const SizedBox(height: 20),
              buildButton(
                context: context,
                text: 'Qualitative Scouting',
                color: const Color.fromARGB(192, 241, 131, 131),
                borderColor: const Color.fromARGB(255, 255, 0, 0),
                icon: Icons.question_answer_outlined,
                textColor: const Color.fromARGB(255, 172, 18, 18),
                iconColor: const Color.fromARGB(255, 172, 18, 18),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const Qualitative(),
                          fullscreenDialog: true));
                },
              ),
              const SizedBox(height: 12),
              buildButton(
                context: context,
                text: 'Match Scouting',
                color: Colors.green.shade100,
                borderColor: Colors.green.shade800,
                icon: Icons.play_arrow_outlined,
                textColor: Colors.green.shade800,
                iconColor: Colors.green.shade800,
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MatchPage(),
                          fullscreenDialog: true));
                },
              ),
              const SizedBox(height: 12),
              buildButton(
                context: context,
                text: 'Record Pit',
                color: Colors.blue.shade100,
                borderColor: Colors.blueAccent,
                icon: Icons.bookmark_add_outlined,
                textColor: Colors.blueAccent,
                iconColor: Colors.blueAccent,
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PitRecorder(),
                          fullscreenDialog: true));
                },
              ),
              const SizedBox(height: 12),
              buildButton(
                context: context,
                text: 'Pit Checklist',
                color: const Color.fromARGB(255, 230, 187, 251),
                borderColor: const Color.fromARGB(255, 59, 24, 84),
                icon: Icons.bookmark_add_outlined,
                textColor: const Color.fromARGB(255, 78, 26, 96),
                iconColor: const Color.fromARGB(255, 106, 31, 113),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PitCheckListPage(),
                          fullscreenDialog: true));
                },
              ),
              const SizedBox(height: 5),
            ];

            double height = 50.0 * children.length;

            return Container(
              width: MediaQuery.of(context).size.width,
              height: height,
              decoration: BoxDecoration(
                color: isdarkmode()
                    ? const Color(0xFFFFFFFF)
                    : const Color.fromARGB(255, 32, 30, 30),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _colorAnimation.value!.withOpacity(0.8),
                    blurRadius: 20.0,
                    spreadRadius: -5.0,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: children,
              ),
            );
          },
        );
      },
    );
  }

  Widget homePage() {
    return HOME();
  }

  // After
  Widget _ReminderWidget() {
    return swipeableCards();
  }

  Widget swipeableCards() {
    if (isCardBuilderOpen) {
      return SizedBox(
        height: 200,
        child: PageView.builder(
          itemCount: 5,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isdarkmode()
                    ? const Color(0xFFFFFFFF)
                    : const Color.fromARGB(255, 1, 1, 1),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    spreadRadius: 2,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Card $index',
                  style: GoogleFonts.chivoMono(
                    fontSize: 30,
                    fontWeight: FontWeight.w300,
                    color: isdarkmode()
                        ? const Color(0xFFFFFFFF)
                        : const Color.fromARGB(255, 179, 25, 25),
                  ),
                ),
              ),
            );
          },
        ),
      );
    } else {
      return Container();
    }
  }

  Widget HOME() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20.0, left: 30.0),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Colors.redAccent,
                  Colors.blue,
                  Colors.blueAccent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Scout-Ops',
                style: GoogleFonts.chivoMono(
                  fontSize: 70,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 15.0,
                      offset: const Offset(5, 5),
                    ),
                  ],
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
                    style: GoogleFonts.museoModerno(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'FEDS201',
                    style: GoogleFonts.museoModerno(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          _ReminderWidget(),
          // Add more content here
        ],
      ),
    );
  }

  Widget buildSnappyListView() {
    return ListView.builder(
      itemCount: Colors.accents.length,
      itemBuilder: (context, index) {
        return Container(
          height: 100,
          color: Colors.accents.elementAt(index),
          child: Text("Index: $index"),
        );
      },
    );
  }

  isExperimentBoxOpenFunc() async {
    final ExpStateManager stateManager = ExpStateManager();
    Map<String, bool> states = await stateManager.loadAllPluginStates([
      'templateStudioEnabled',
      'templateStudioExpanded',
      'cardBuilderEnabled',
      'cardBuilderExpanded'
    ]);
    return states['templateStudioEnabled'];
  }

  isCardBuilderOpenFunc() async {
    final ExpStateManager stateManager = ExpStateManager();
    Map<String, bool> states = await stateManager
        .loadAllPluginStates(['cardBuilderEnabled', 'cardBuilderExpanded']);
    return states['cardBuilderEnabled'];
  }
}

Widget _buildCustomAppBar(BuildContext context) {
  return AppBar(
    leading: Builder(builder: (context) {
      return IconButton(
          icon: const Icon(Icons.menu),
          color: !isdarkmode()
              ? const Color.fromARGB(193, 255, 255, 255)
              : const Color.fromARGB(105, 36, 33, 33),
          onPressed: () => Scaffold.of(context).openDrawer());
    }),
    backgroundColor: Colors.transparent, // Transparent to show the animation
    elevation: 0, // Remove shadow for a cleaner look
    actions: [
      IconButton(
        icon: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.redAccent, Colors.lightBlueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Icon(Icons.attach_file_rounded,
              size: 30, color: Colors.white),
        ),
        onPressed: () {
          Route route = MaterialPageRoute(
              builder: (context) => const InfiniteZoomImage());
          Navigator.push(context, route);
        },
      ),
      IconButton(
        icon: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.red, Colors.lightBlueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomLeft,
          ).createShader(bounds),
          child: const Icon(Icons.extension, size: 30, color: Colors.white),
        ),
        onPressed: () {
          Route route = MaterialPageRoute(
              builder: (context) => const Plugins(), fullscreenDialog: true);
          Navigator.push(context, route);
        },
      ),
    ],
  );
}
