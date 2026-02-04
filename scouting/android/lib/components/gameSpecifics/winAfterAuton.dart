import 'package:flutter/material.dart';

Widget buildWinner(BuildContext context, Function(String winner) onclick, String selectedWinner) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      height: 144,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(34, 34, 34, 1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const SizedBox(
            height: 5,
          ),
          const Text(
            'What Alliance was in the Lead?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontFamily: 'MuseoModerno',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  onclick("Red");
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                ),
                child: Container(
                  alignment: Alignment.center,
                  width: 120,
                  height: 70,
                  decoration: BoxDecoration(
                      color: selectedWinner == "Red" ? Colors.red : Colors.red.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('RED',
                      style: TextStyle(
                          color: selectedWinner == "Red" ? Colors.white : Colors.black38,
                          fontSize: 35,
                          fontFamily: 'MuseoModerno',
                          fontWeight: FontWeight.w700)),
                ),
              ),
              TextButton(
                onPressed: () {
                  onclick("Tie");
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                ),
                child: Container(
                  alignment: Alignment.center,
                  width: 120,
                  height: 70,
                  decoration: BoxDecoration(
                      color: selectedWinner == "Tie" ? Colors.white : Colors.grey,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('TIE',
                      style: TextStyle(
                          color: selectedWinner == "Tie" ? Colors.black : Colors.black38,
                          fontSize: 35,
                          fontFamily: 'MuseoModerno',
                          fontWeight: FontWeight.w700)),
                ),
              ),
              TextButton(
                onPressed: () {
                  onclick("Blue");
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                ),
                child: Container(
                  alignment: Alignment.center,
                  width: 120,
                  height: 70,
                  decoration: BoxDecoration(
                      color: selectedWinner == "Blue" ? Colors.blue : Colors.blue.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('BLUE',
                      style: TextStyle(
                          color: selectedWinner == "Blue" ? Colors.white : Colors.black38,
                          fontSize: 35,
                          fontFamily: 'MuseoModerno',
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          )
        ],
      ),
    ),
  );
}
