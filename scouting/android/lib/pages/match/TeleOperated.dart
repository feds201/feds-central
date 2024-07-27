import 'package:flutter/material.dart';
import 'package:scouting_app/components/CommentBox.dart';
import 'package:scouting_app/components/CounterShelf.dart';

class TeleOperated extends StatefulWidget {
  const TeleOperated({Key? key}) : super(key: key);

  @override
  _TeleOperatedState createState() => _TeleOperatedState();
}

class _TeleOperatedState extends State<TeleOperated> {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [

            ],
          )
        ],
      ),
    );
  }
}
