import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget buildWinAfterAuton() {
  return Container(
    width: 400,
    height: 144,
    child: Stack(
      children: [
        Positioned(
          left: 10.60,
          top: 9,
          child: Container(
            width: 31.81,
            height: 31.81,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(),
            child: Stack(),
          ),
        ),
        Positioned(
          left: 52.05,
          top: 10.63,
          child: SizedBox(
            width: 310.36,
            height: 29.96,
            child: Text(
              'What Alliance was in the Lead?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontFamily: 'MuseoModerno',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Positioned(
          left: 13.49,
          top: 54.12,
          child: Container(
            width: 120.48,
            height: 69.58,
            decoration: ShapeDecoration(
              color: const Color(0xFFFF0000),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
        Positioned(
          left: 139.76,
          top: 54.12,
          child: Container(
            width: 120.48,
            height: 69.58,
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
        Positioned(
          left: 266.02,
          top: 54.12,
          child: Container(
            width: 120.48,
            height: 69.58,
            decoration: ShapeDecoration(
              color: const Color(0xFF0083FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
        Positioned(
          left: 31.81,
          top: 54.05,
          child: Text(
            'RED',
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.38),
              fontSize: 44,
              fontFamily: 'MuseoModerno',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Positioned(
          left: 272.77,
          top: 53.09,
          child: Text(
            'BLUE',
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.46),
              fontSize: 44,
              fontFamily: 'MuseoModerno',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Positioned(
          left: 164.82,
          top: 54.05,
          child: Text(
            'TIE',
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.44),
              fontSize: 44,
              fontFamily: 'MuseoModerno',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildHelloWorld() {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: new Container(
      height: 144,
      width: double.infinity,
      color: Color.fromRGBO(34, 34, 34, 1),
      child: new Column(
        children: [
          new Text("hello", style: TextStyle(color: Colors.white, fontSize: 30),),
          new Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              new Container(
                width: 120, height: 70, color: Colors.red
              ),
              new Container(
                  width: 120, height: 70, color: Colors.white
              ),
              new Container(
                  width: 120, height: 70, color: Colors.blue
              ),

            ],
          )
        ],
      ),
    ),
  );
}
