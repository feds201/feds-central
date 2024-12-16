import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scouting_app/templateBuilder/builder.dart';

import 'Experiment/ExpStateManager.dart';
import 'Match_Pages/match_page.dart';
import 'Pit_Recorder/Pit_Recorder.dart';
import 'Plugins/plugins.dart';
import 'References.dart';
import 'components/Animator/GridPainter.dart';
import 'components/Button.dart';
import 'components/nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

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
          onClosing: () {},
          builder: (BuildContext context) {
            List<Widget> children = [
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
              const SizedBox(height: 5),
            ];

            if (isExperimentBoxOpen) {
              children.add(
                buildButton(
                  context: context,
                  text: 'Template Creator',
                  color: Colors.red.shade100,
                  borderColor: Colors.redAccent,
                  icon: Icons.info_outline,
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const TemplateBuilder()));
                  },
                ),
              );
            }

            double height = 55.0 * children.length;

            return Container(
              height: height,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _colorAnimation.value!.withOpacity(0.6),
                    blurRadius: 10.0,
                    spreadRadius: 2.0,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: children,
                ),
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
      return Container(
        height: 200,
        child: PageView.builder(
          itemCount: 5,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
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
                    color: Colors.black,
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
        _ReminderWidget(),
      ],
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
    final ExpStateManager _stateManager = ExpStateManager();
    Map<String, bool> states = await _stateManager.loadAllPluginStates([
      'templateStudioEnabled',
      'templateStudioExpanded',
      'cardBuilderEnabled',
      'cardBuilderExpanded'
    ]);
    return states['templateStudioEnabled'];
  }

  isCardBuilderOpenFunc() async {
    final ExpStateManager _stateManager = ExpStateManager();
    Map<String, bool> states = await _stateManager
        .loadAllPluginStates(['cardBuilderEnabled', 'cardBuilderExpanded']);
    return states['cardBuilderEnabled'];
  }
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
