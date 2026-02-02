
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


@override
Widget buildPhaseSele(BuildContext context, Function(int shift) onclick) {
  return Column(
    children: [
      Container(
        width: 415,
        height: 276,
        child: Stack(
          children: [
            // ... (Title and Icon positions remain the same) ...

            // Position 0 (The Large 'T' Box)
            Positioned(
              left: 15,
              top: 66,
              child: TextButton(
                onPressed: () => onclick(0), // Passing 0 for T
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Container(
                  width: 103,
                  height: 191,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFE5623A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                  ),
                  child: Center(
                    child: Text('T', style: TextStyle(color: Colors.black.withOpacity(0.47), fontSize: 97)),
                  ),
                ),
              ),
            ),

            // Position 1 (Top Green Box)
            Positioned(
              left: 134,
              top: 66,
              child: TextButton(
                onPressed: () => onclick(1),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Container(
                  width: 125,
                  height: 88,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF4F7835),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                  ),
                  child: Center(
                    child: Text('A1', style: TextStyle(color: Colors.black.withOpacity(0.47), fontSize: 58)),
                  ),
                ),
              ),
            ),

            // Position 2 (Top Green Box Right)
            Positioned(
              left: 275,
              top: 66,
              child: TextButton(
                onPressed: () => onclick(2),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Container(
                  width: 125,
                  height: 88,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF4F7835),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                  ),
                  child: Center(
                    child: Text('I1', style: TextStyle(color: Colors.black.withOpacity(0.47), fontSize: 58)),
                  ),
                ),
              ),
            ),

            // Position 3 (Bottom Yellow Box Left)
            Positioned(
              left: 134,
              top: 169,
              child: TextButton(
                onPressed: () => onclick(3),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Container(
                  width: 125,
                  height: 88,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFE7B462),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                  ),
                  child: Center(
                    child: Text('A2', style: TextStyle(color: Colors.black.withOpacity(0.47), fontSize: 58)),
                  ),
                ),
              ),
            ),

            // Position 4 (Bottom Yellow Box Right)
            Positioned(
              left: 275,
              top: 169,
              child: TextButton(
                onPressed: () => onclick(4),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Container(
                  width: 125,
                  height: 88,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFE7B462),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                  ),
                  child: Center(
                    child: Text('I2', style: TextStyle(color: Colors.black.withOpacity(0.47), fontSize: 58)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}