import 'package:flutter/material.dart';

Widget buildTimer(){
  return Container(
    width: 400,
    height: 389,
    child: Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          child: Container(
            width: 400,
            height: 389,
            decoration: ShapeDecoration(
              color: const Color(0xFF222222),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              shadows: [
                BoxShadow(
                  color: Color(0x3F000000),
                  blurRadius: 4,
                  offset: Offset(0, 4),
                  spreadRadius: 0,
                )
              ],
            ),
          ),
        ),
        Positioned(
          left: 12.53,
          top: 14.98,
          child: Container(
            width: 373.98,
            height: 352.41,
            decoration: ShapeDecoration(
              color: const Color(0xFF222222),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 2,
                  color: const Color(0xFF0032FB),
                ),
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
        ),
        Positioned(
          left: 91.57,
          top: 241.65,
          child: SizedBox(
            width: 48.19,
            height: 58.94,
            child: Text(
              'Start',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF222222),
                fontSize: 21,
                fontFamily: 'Istok Web',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Positioned(
          left: 24.10,
          top: 27.92,
          child: Container(
            width: 349.88,
            height: 103.99,
            decoration: ShapeDecoration(
              color: const Color(0xFF261F1F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
        Positioned(
          left: 53.01,
          top: 20.22,
          child: SizedBox(
            width: 302.65,
            height: 79.92,
            child: Text(
              '00:99',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 67,
                fontFamily: 'Grandstander',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        Positioned(
          left: 106.02,
          top: 155.02,
          child: Container(
            width: 187.95,
            height: 187.76,
            decoration: ShapeDecoration(
              color: const Color(0xFF3AD825),
              shape: OvalBorder(),
              shadows: [
                BoxShadow(
                  color: Color(0x3F000000),
                  blurRadius: 16.20,
                  offset: Offset(0, 4),
                  spreadRadius: 15,
                )
              ],
            ),
          ),
        ),
        Positioned(
          left: 144.47,
          top: 222.42,
          child: Text(
            'HOLD',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.29),
              fontSize: 43,
              fontFamily: 'Istok Web',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Positioned(
          left: 26.02,
          top: 222.42,
          child: Container(
            width: 53.98,
            height: 52.96,
            decoration: ShapeDecoration(
              color: const Color(0xFF3AD825),
              shape: OvalBorder(),
              shadows: [
                BoxShadow(
                  color: Color(0x3F000000),
                  blurRadius: 16.20,
                  offset: Offset(0, 4),
                  spreadRadius: 15,
                )
              ],
            ),
          ),
        ),
        Positioned(
          left: 320,
          top: 222.42,
          child: Container(
            width: 53.98,
            height: 52.96,
            decoration: ShapeDecoration(
              color: const Color(0xFFBE2929),
              shape: OvalBorder(),
              shadows: [
                BoxShadow(
                  color: Color(0x3F000000),
                  blurRadius: 16.20,
                  offset: Offset(0, 4),
                  spreadRadius: 15,
                )
              ],
            ),
          ),
        ),
        Positioned(
          left: 323.86,
          top: 233.98,
          child: SizedBox(
            width: 46.27,
            height: 29.85,
            child: Text(
              '+2',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.29),
                fontSize: 24,
                fontFamily: 'Istok Web',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Positioned(
          left: 26.02,
          top: 233.98,
          child: SizedBox(
            width: 46.27,
            height: 29.85,
            child: Text(
              '-2',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.29),
                fontSize: 24,
                fontFamily: 'Istok Web',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}