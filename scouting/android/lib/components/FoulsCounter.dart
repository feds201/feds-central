import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:scout_ops_android/components/CounterShelf.dart';

Widget buildFoulsCounter(String title, int fouls, Function(int) onChanged){
  return Builder(
    builder: (context) {
      double screenWidth = MediaQuery.of(context).size.width - 40;
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: screenWidth / 2,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 34, 34, 34),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DottedBorder(
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(12),
                  padding: const EdgeInsets.all(6),
                  color: const Color.fromARGB(255, 255, 255, 255),
                  dashPattern: const [8, 4],
                  strokeWidth: 2,
                  child: Container(
                    width: double.infinity,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 34, 34, 34),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (fouls >= 0 && fouls <= 10)
                              onChanged(fouls - 1);
                          },
                          child: Icon(
                            Icons.remove,
                            color: const Color.fromARGB(255, 255, 255, 255),
                            size: 40,
                          ),
                        ),
                        Text(
                          '$fouls',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (fouls >= 0 && fouls <= 10)
                              onChanged(fouls + 1);
                          },
                          child: Icon(
                            Icons.add,
                            color: const Color.fromARGB(255, 255, 255, 255),
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontStyle: FontStyle.italic,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}