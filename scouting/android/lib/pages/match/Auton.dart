import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:scouting_app/pages/components/DataBase.dart';
import '../match.dart';

class Auton extends StatefulWidget {
  const Auton({super.key});

  @override
  AutonState createState() => AutonState();
}

class AutonState extends State<Auton> {
  final LocalDataBase dataMaster = LocalDataBase();
  late Offset? _circlePosition =
      LocalDataBase.getData(AutoType.StartPosition) ??
          const Offset(10, 10); // Default value;
  late int ampPlacementValue;
  late int speakerValue;
  late int autonRating;
  late List<String> comments;

  late String assignedTeam;
  late String assignedStation;
  late String matchKey;
  late String allianceColor;

  bool isChip1Clicked = false;
  bool isChip2Clicked = false;
  bool isChip3Clicked = false;

  // Match Variables
  @override
  void initState() {
    super.initState();
    assignedTeam = LocalDataBase.getData(Types.team) ?? "Null";
    assignedStation = LocalDataBase.getData(Types.selectedStation) ?? "Null";
    autonRating = LocalDataBase.getData(AutoType.AutonRating) ?? 0;

    ampPlacementValue = LocalDataBase.getData(AutoType.AmpPlacement) ?? 0;
    speakerValue = LocalDataBase.getData(AutoType.Speaker) ?? 0;
    autonRating = LocalDataBase.getData(AutoType.AutonRating) ?? 0;
    String comment = LocalDataBase.getData(AutoType.Comments) ?? ["No Comments"];
    comments = [comment];

    isChip1Clicked = comments.contains('Encountered issues');
    isChip2Clicked = comments.contains('Fast and efficient');
    isChip3Clicked = comments.contains('No issues');
  }

  void UpdateData(
      ampPlacementValue, speakerValue, _circlePosition, autonRating, comments) {
    LocalDataBase.putData(AutoType.AmpPlacement, ampPlacementValue);
    LocalDataBase.putData(AutoType.Speaker, speakerValue);
    LocalDataBase.putData(AutoType.StartPosition, _circlePosition);
    LocalDataBase.putData(AutoType.AutonRating, autonRating);
    LocalDataBase.putData(AutoType.Comments, comments);
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      assignedTeam = LocalDataBase.getData(Types.team) ?? "Null";
      assignedStation = LocalDataBase.getData(Types.selectedStation) ?? "Null";
      matchKey = LocalDataBase.getData(Types.matchKey) ?? "Null";
      allianceColor = LocalDataBase.getData(Types.allianceColor) ?? "Null";
    });
    return Container(child: _buildAuto(context));
  }

  Widget _buildAuto(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTeamInfo(),
          _buildBotField(),
          _buildActions(),
          _buildComments()
        ],
      ),
    );
  }

  Widget _buildTeamInfo() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.category,
                  color: Colors.grey,
                  size: 40,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignedTeam,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$allianceColor Alliance, Station $assignedStation',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'START',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotField() {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(7.0),
            child: Stack(
              children: [
                GestureDetector(
                  onTapUp: _updatePosition,
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(10.0), // Add border radius here
                    child: Image.asset(
                      'assets/${LocalDataBase.getData(Types.allianceColor)}Alliance_StartPosition.png',
                    ),
                  ),
                ),
                if (_circlePosition != null)
                  Positioned(
                    left: _circlePosition!.dx - 10, // Center the circle
                    top: _circlePosition!.dy - 10, // Center the circle
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(0), // Add border radius here
                        child: Image.asset(
                          'assets/Swerve.png',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ));
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome),
                  const SizedBox(width: 16),
                  const Text(
                    'Amp Placement',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            ampPlacementValue = ampPlacementValue - 1;
                            UpdateData(ampPlacementValue, speakerValue,
                                _circlePosition, autonRating, comments);
                          });
                        },
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        '$ampPlacementValue',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            ampPlacementValue = ampPlacementValue + 1;
                            UpdateData(ampPlacementValue, speakerValue,
                                _circlePosition, autonRating, comments);
                          });
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.speaker),
                  const SizedBox(width: 16),
                  const Text(
                    'Speaker',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            speakerValue = speakerValue - 1;
                            UpdateData(ampPlacementValue, speakerValue,
                                _circlePosition, autonRating, comments);
                          });
                        },
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        '$speakerValue',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            speakerValue = speakerValue + 1;
                            UpdateData(ampPlacementValue, speakerValue,
                                _circlePosition, autonRating, comments);
                          });
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComments() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.sports_soccer_rounded),
                  SizedBox(width: 16),
                  Text(
                    'Auton Rating',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: RatingBar.builder(
                  initialRating: autonRating.toDouble(),
                  minRating: 0,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  glow: false,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      autonRating = rating.toInt();
                      UpdateData(ampPlacementValue, speakerValue,
                          _circlePosition, autonRating, comments);
                    });
                  },
                ),
              ),
              const SizedBox(height: 22),
              const Row(
                children: [
                  Icon(Icons.comment),
                  SizedBox(width: 16),
                  Text(
                    'Your Comments',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          UpdateData(ampPlacementValue, speakerValue,
                              _circlePosition, autonRating, "Encountered issues");
                          setState(() {
                            isChip1Clicked = !isChip1Clicked;
                            isChip2Clicked = false;
                            isChip3Clicked = false;
                          });
                        },
                        child: Chip(
                          label: const Text('Encountered issues'),
                          backgroundColor:
                              isChip1Clicked ? Colors.red : Colors.white,
                          labelStyle: TextStyle(
                              color:
                                  isChip1Clicked ? Colors.white : Colors.black),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          UpdateData(ampPlacementValue, speakerValue,
                              _circlePosition, autonRating, "Fast and efficient");
                          setState(() {
                            isChip2Clicked = !isChip2Clicked;
                            isChip1Clicked = false;
                            isChip3Clicked = false;
                          });
                        },
                        child: Chip(
                          label: const Text('Fast and efficient'),
                          backgroundColor:
                              isChip2Clicked ? Colors.green : Colors.white,
                          labelStyle: TextStyle(
                              color:
                                  isChip2Clicked ? Colors.white : Colors.black),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          UpdateData(ampPlacementValue, speakerValue, _circlePosition, autonRating, "No issues");
                          setState(() {
                            isChip3Clicked = !isChip3Clicked;
                            isChip1Clicked = false;
                            isChip2Clicked = false;
                          });
                        },
                        child: Chip(
                          label: const Text('No issues'),
                          backgroundColor:
                              isChip3Clicked ? Colors.blue : Colors.white,
                          labelStyle: TextStyle(
                              color:
                                  isChip3Clicked ? Colors.white : Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _updatePosition(TapUpDetails details) {
    setState(() {
      _circlePosition = details.localPosition;
      LocalDataBase.putData(AutoType.StartPosition, _circlePosition);
    });
  }
}

enum AutoType { AmpPlacement, Speaker, StartPosition, AutonRating, Comments }
