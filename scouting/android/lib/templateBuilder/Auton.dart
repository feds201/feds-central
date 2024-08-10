import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// Assuming these imports exist and are correctly implemented
import 'package:scouting_app/components/Map.dart';
import 'package:scouting_app/components/ratings.dart';

import '../components/Chips.dart';
import '../components/CommentBox.dart';
import '../components/CounterShelf.dart';
import '../components/RatingsBox.dart';
import '../components/TeamInfo.dart';

class AutonBuilder extends StatefulWidget {
  const AutonBuilder({super.key});

  @override
  AutonState createState() => AutonState();
}

class AutonState extends State<AutonBuilder> {
  Offset? _circlePosition;
  Size size = const Size(30, 30);

  // List to hold current widgets
  List<Widget> currentWidgets = [];

  @override
  void initState() {
    super.initState();
    // Initialize with some default widgets
    currentWidgets = [

    ];
  }

  void onTap(Offset position) {
    setState(() {
      _circlePosition = position;
      if (kDebugMode) {
        print(_circlePosition);
      }
    });
  }

  // Function to replace a widget
  void replaceWidget(int index, Widget newWidget) {
    setState(() {
      currentWidgets[index] = newWidget;
    });
  }

  // Function to show available widgets and handle replacement
  void showAvailableWidgets(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "Available Widgets",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: double.infinity),
                  ListTile(
                    title: MatchInfo(
                      assignedTeam: "201",
                      assignedStation: "R1",
                      allianceColor: "Red",
                      onPressed: () {},
                    ),
                    onTap: () {
                      replaceWidget(
                          index,
                          MatchInfo(
                            assignedTeam: "201",
                            assignedStation: "R1",
                            allianceColor: "Red",
                            onPressed: () {},
                          ));
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: buildCounterShelf([
                      CounterSettings((int value) {
                        if (kDebugMode) {
                          if (kDebugMode) {
                            print(value);
                          }
                        }
                      }, (int value) {},
                          icon: Icons.star,
                          number: 0,
                          counterText: 'Counter 1',
                          color: Colors.yellowAccent),
                    ]),
                    onTap: () {
                      replaceWidget(
                          index,
                          buildCounterShelf([
                            CounterSettings((int value) {
                              if (kDebugMode) {
                                if (kDebugMode) {
                                  print(value);
                                }
                              }
                            }, (int value) {},
                                icon: Icons.star,
                                number: 0,
                                counterText: 'Counter 1',
                                color: Colors.yellowAccent)
                          ]));
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: buildMap(context, _circlePosition, size,  "Blue"),
                    onTap: () {
                      replaceWidget(index, buildMap(context, _circlePosition, size,  "Blue"));
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: buildComments(
                      "Auton Comments",

                      [
                        buildChips(
                            ["Moved", "Did Not Move"],
                            [
                              [Colors.green, Colors.red],
                              [Colors.green, Colors.red]
                            ],
                            [true, false]
                        ),
                      ],
                      const Icon(Icons.comment_bank),
                    ),
                    onTap: () {
                      replaceWidget(index, buildComments(
                        "Auton Comments",
                        [
                          buildChips(
                              ["Moved", "Did Not Move"],
                              [
                                [Colors.green, Colors.red],
                                [Colors.green, Colors.red]
                              ],
                              [true, false]
                          ),
                        ],
                        const Icon(Icons.comment_bank),
                      ));
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title:  buildRatings([
                      buildRating("RatingBar", Icons.access_alarm_outlined, 1.5, 7, Colors.blue),
                    ]),
                    onTap: () {
                      replaceWidget(index, buildRatings([
                        buildRating("RatingBar", Icons.access_alarm_outlined, 1.5, 7, Colors.blue),
                      ]));
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Column(
            children: currentWidgets.asMap().entries.map((entry) {
              int index = entry.key;
              Widget widget = entry.value;
              return GestureDetector(
                onTap: () => showAvailableWidgets(index),
                child: widget,
              );
            }).toList(),
          ),

          InkWell(
            onTap: () {
              setState(() {
                currentWidgets.add(
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      DottedBorder(
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(12),
                        padding: const EdgeInsets.all(6),
                        color: Colors.blue,
                        dashPattern: const [8, 4],
                        strokeWidth: 2,
                        child: Container(
                          width: MediaQuery.of(context).size.width - 36,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.add,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              });
            },
            child: Column(
              children: [
                const SizedBox(height: 10),
                DottedBorder(
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(12),
                  padding: const EdgeInsets.all(6),
                  color: Colors.blue,
                  dashPattern: const [8, 4],
                  strokeWidth: 2,
                  child: Container(
                    width: MediaQuery.of(context).size.width - 36,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
