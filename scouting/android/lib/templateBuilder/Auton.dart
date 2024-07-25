import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [



        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return Scrollable(
                  viewportBuilder:
                      (BuildContext context, ViewportOffset position) {
                    return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        controller: ScrollController(),
                        child: Column(children: [
                          const SizedBox(
                            width: double.infinity,
                            height: 16,
                          ),
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
                          const SizedBox(
                            width: double.infinity,
                          ),
                          buildTeamInfo("201", "R0", "Test"),
                          buildCounterShelf(1),
                          buildComments(
                              "Auton Comments",
                              [
                                buildChips([
                                  "Moved",
                                  "Did Not Move"
                                ], [
                                  [Colors.green, Colors.red],
                                  [Colors.green, Colors.red]
                                ], [
                                  true,
                                  false
                                ]),
                              ],
                              const Icon(Icons.comment_bank)),
                        ]));
                  },
                );
              },
            );
          },
          child: Column(children: [
            const SizedBox(
              width: double.infinity,
              height: 10,
            ),
            DottedBorder(
              borderType: BorderType.RRect,
              radius: const Radius.circular(12),
              padding: const EdgeInsets.all(6),
              color: Colors.blue, // Border color
              dashPattern: const [8, 4], // Dash pattern for dotted border
              strokeWidth: 2,
              child: Container(
                  width: MediaQuery.of(context).size.width *
                      0.95, // 90% of screen width
                  height: 50, // Fixed height
                  decoration: BoxDecoration(
                    color: Colors.transparent, // Container color
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add, // Plus symbol
                      color: Colors.blue,
                    ),
                  )),
            ),
          ]),
        ),
      ],
    );
  }
}
