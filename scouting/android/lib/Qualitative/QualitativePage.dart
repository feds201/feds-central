import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:scouting_app/components/Button.dart';
import 'package:scouting_app/components/FullScreenQrCodePage.dart';
import 'package:scouting_app/main.dart';
import 'package:scouting_app/services/DataBase.dart';
import 'package:scouting_app/components/TextBox.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/Colors.dart';

class QualitativePage extends StatefulWidget {
  final QualitativeRecord record;
  QualitativePage({super.key, required this.record});

  @override
  State<StatefulWidget> createState() => _QualitativePage();
}

class _QualitativePage extends State<QualitativePage> {
  TextEditingController robotMatchStrategy = TextEditingController();
  TextEditingController defensePlay = TextEditingController();
  TextEditingController humanPlayerRole = TextEditingController();

  @override
  void initState() {
    super.initState();
    print("Qualitative Page");
    print(widget.record.getQ1());
    print(widget.record.getQ2());
    print(widget.record.getQ3());
    print(widget.record.getQ4());
    print(widget.record.getAlliance());
    print(widget.record);

    robotMatchStrategy.text = widget.record.getQ1();
    defensePlay.text = widget.record.getQ2();
    humanPlayerRole.text = widget.record.getQ3();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Colors.transparent;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(builder: (context) {
          return IconButton(
              icon: const Icon(Icons.arrow_back),
              color: !islightmode()
                  ? const Color.fromARGB(193, 255, 255, 255)
                  : const Color.fromARGB(105, 36, 33, 33),
              onPressed: () => Navigator.of(context).pop());
        }),
        title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.red, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
            child: Text(
              widget.record.matchNumber.toString(),
              style: GoogleFonts.museoModerno(
                  fontSize: 40,
                  fontWeight: FontWeight.w500,
                  color: Colors.white),
            )),
        backgroundColor:
            islightmode() ? lightColors.white : darkColors.goodblack,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: backgroundColor,
          child: Column(
            children: [
              _buildQuestions(),
              SizedBox(height: 20),
              SizedBox(height: 20),
              buildButton(
                text: "Qr Code",
                onPressed: () {
                  _recordData();
                  PopBoard(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenQrCodePage(
                        data: json.encode(widget.record.toJson()),
                      ),
                    ),
                  );
                },
                context: context,
                color: Colors.green,
                textColor: !islightmode()
                    ? const Color.fromARGB(255, 255, 255, 255)
                    : const Color.fromARGB(255, 0, 0, 0),
                icon: Icons.qr_code_2,
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _recordData();
          PopBoard(context);
        },
        child: const Icon(Icons.save),
        backgroundColor: Colors.blue,
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
            Icon(
              Icons.help,
              color: Colors.transparent,
            ),
          );
        }).toList(),
      ),
    );
  }

  void _recordData() {
    widget.record.q1 =
        robotMatchStrategy.text.isNotEmpty ? robotMatchStrategy.text : "N/A";
    widget.record.q2 = defensePlay.text.isNotEmpty ? defensePlay.text : "N/A";
    widget.record.q3 =
        humanPlayerRole.text.isNotEmpty ? humanPlayerRole.text : "N/A";
    widget.record.q4 = "N/A";

    QualitativeDataBase.PutData(widget.record.matchKey, widget.record.toJson());
    QualitativeDataBase.PrintAll();
    QualitativeDataBase.SaveAll();
  }

  void PopBoard(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    robotMatchStrategy.dispose();
    defensePlay.dispose();
    humanPlayerRole.dispose();
    super.dispose();
  }
}
