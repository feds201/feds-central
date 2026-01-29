import 'package:flutter/material.dart';

Widget buildTklKeyboard(BuildContext context, Function(double time) onHold) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      height: 450,
      width: 400,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(34, 34, 34, 1),
        borderRadius: BorderRadius.circular(25), // Outer rounded edges
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Grey margin before the line
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(34, 34, 34, 1), // Inner grey
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF0032FB), // Blue line
              width: 2,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              const Text('00:99',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 70)),
              const SizedBox(
                height: 50,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () {
                      onHold(-2.0);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: const Text("-2",
                          style: TextStyle(color: Colors.black, fontSize: 20)),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () {
                      onHold(0.0);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: 180,
                      height: 180,
                      decoration: const BoxDecoration(
                          color: Colors.green, shape: BoxShape.circle),
                      child: const Text("HOLD",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 40,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () {
                      onHold(2.0);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                          color: Colors.lightGreenAccent,
                          shape: BoxShape.circle),
                      child: const Text("+2",
                          style: TextStyle(color: Colors.black, fontSize: 20)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    ),
  );
}
