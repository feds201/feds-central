import 'package:flutter/material.dart';
import 'package:scouting_app/components/Button.dart';
import 'package:scouting_app/components/DataBase.dart';
import 'package:scouting_app/components/TextBox.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Match_Pages/match.dart';

class QualitativePage extends StatefulWidget {
  const QualitativePage({super.key});

  @override
  State<StatefulWidget> createState() => _QualitativePage();
}

class _QualitativePage extends State<QualitativePage> {
  TextEditingController robotMatchStrategy = TextEditingController();
  TextEditingController defensePlay = TextEditingController();
  TextEditingController humanPlayerRole = TextEditingController();
  late var matchKey;

  @override
  void initState() {
    super.initState();

    try {
      print(matchKey);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [],
        title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.red, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
            child: Text(
              "teamNumber",
              style: GoogleFonts.museoModerno(
                fontSize: 40,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            )),
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildQuestions(),
          SizedBox(height: 20),
          buildButton(
              context: context,
              text: "Hello",
              color: Color(0xFF1AC510),
              icon: Icons.person,
              onPressed: () => _recordData()),
        ],
      ),
    );
  }

  Widget _buildQuestions() {
    final List<Map<String, dynamic>> categories = [
      {
        "title": "Robot Match Strategy",
        "icon": Icon(Icons.smart_toy),
        "question": "What's the robot's match strategy?",
        "observation": "Observe: Scoring method, role in alliance",
        "controller": robotMatchStrategy
      },
      {
        "title": "Defensive Play",
        "icon": Icon(Icons.shield),
        "question": "How are they playing defense?",
        "observation": "Observe: Blocking, pushing, positioning",
        "controller": defensePlay
      },
      {
        "title": "Human Player Role",
        "icon": Icon(Icons.person),
        "question": "What does the human player do?",
        "observation": "Observe: Feeding, controlling, assisting",
        "controller": humanPlayerRole
      }
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: categories.map((category) {
          return buildTextBoxs(
            category["title"],
            [
              buildTextBox(category["question"], category["observation"],
                  category["icon"], category["controller"]),
            ],
            category["icon"],
          );
        }).toList(),
      ),
    );
  }

  void _recordData() {
    QualitativeRecord record = QualitativeRecord(
      matchKey: matchKey,
      q1: robotMatchStrategy.text,
      q2: defensePlay.text,
      q3: humanPlayerRole.text,
      q4: "",
      scouterName: "Ritesh",
    );

    QualitativeDataBase.PutData(matchKey, record.toJson());
    QualitativeDataBase.PrintAll();
  }

  void PopBoard(BuildContext context) {
    Navigator.pop(context);
  }
}
