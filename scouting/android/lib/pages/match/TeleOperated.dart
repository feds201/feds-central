import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:scouting_app/components/CommentBox.dart';
import 'package:scouting_app/components/CounterShelf.dart';

import '../../components/CheckBox.dart';

class TeleOperated extends StatefulWidget {
  const TeleOperated({Key? key}) : super(key: key);

  @override
  _TeleOperatedState createState() => _TeleOperatedState();
}

class _TeleOperatedState extends State<TeleOperated> {
  bool hi = false;
  int hi3 = 2;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          buildComments(
              "Pick Up",
              [
                CounterSettings(
                    icon: Icons.grass_outlined,
                    startingNumber: 0,
                    counterText: "Ground",
                    color: Colors.green),
                CounterSettings(
                    icon: Icons.shopping_basket_outlined,
                    startingNumber: 0,
                    counterText: "Source",
                    color: Colors.blue),
              ],
              const Icon(Icons.add_comment)),
          buildComments(
              "Scoring",
              [
                CounterSettings(
                    icon: Icons.grass_outlined,
                    startingNumber: 0,
                    counterText: "Speaker Notes",
                    color: Colors.green),
                CounterSettings(
                    icon: Icons.shopping_basket_outlined,
                    startingNumber: 0,
                    counterText: "Amp Placement",
                    color: Colors.blue),
                CounterSettings(
                    icon: Icons.shopping_basket_outlined,
                    startingNumber: 0,
                    counterText: "Trap Placement",
                    color: Colors.red),
              ],
              const Icon(Icons.add_comment)),
          buildCounterShelf([
            CounterSettings(
                icon: Icons.grass_outlined,
                startingNumber: 0,
                counterText: "Amplified Speaker Notes",
                color: Colors.green),
          ]),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              buildCheckBox("Co-Op Bonus", hi, (bool value) {
                setState(() {
                  print(value);
                  hi = value;
                });
              }),
              buildCounter("Assists", hi3, (int value) {
                setState(() {
                  hi3 = value;
                  print(hi3);
                });
              }),
            ]),
          )
        ],
      ),
    );
  }
}

