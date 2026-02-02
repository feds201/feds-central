import 'package:flutter/material.dart';

Widget buildWinner(BuildContext context, Function(String winner) onclick) {
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
                child: Container(
                  alignment: Alignment.center,
                  width: 120,
                  height: 70,
                  decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Text('RED',
                      style: TextStyle(
                          color: Colors.black38,
                          fontSize: 35,
                          fontFamily: 'MuseoModerno',
                          fontWeight: FontWeight.w700)),
                ),
              ),
              TextButton(
                onPressed: () {
                  onclick("Tie");
                },
                child: Container(
                  alignment: Alignment.center,
                  width: 120,
                  height: 70,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Text('TIE',
                      style: TextStyle(
                          color: Colors.black38,
                          fontSize: 35,
                          fontFamily: 'MuseoModerno',
                          fontWeight: FontWeight.w700)),
                ),
              ),
              TextButton(
                onPressed: () {
                  onclick("Blue");
                },
                child: Container(
                  alignment: Alignment.center,
                  width: 120,
                  height: 70,
                  decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Text('BLUE',
                      style: TextStyle(
                          color: Colors.black38,
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
