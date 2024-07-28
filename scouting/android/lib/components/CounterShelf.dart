// lib/components/CounterShelf.dart

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class CounterSettings {
  final IconData icon;
  final int startingNumber;
  final String counterText;
  final Color color;

  CounterSettings({
    required this.icon,
    required this.startingNumber,
    required this.counterText,
    required this.color,
  });
}

Widget buildCounterShelf(List<CounterSettings> counterSettings) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: counterSettings.map((settings) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              children: [
                Icon(settings.icon, color: settings.color),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    settings.counterText,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Decrement counter value logic here
                  },
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  '${settings.startingNumber}', // Display starting number
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Increment counter value logic here
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ),
  );
}

Widget buildCounter(String title, int value, Function(int) onChanged) {
  return LayoutBuilder(
    builder: (context, constraints) {
      double screenWidth = MediaQuery.of(context).size.width - 25;
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: screenWidth / 2,
          decoration: BoxDecoration(
            color: Colors.white,
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
                  color: Colors.black,
                  dashPattern: const [8, 4],
                  strokeWidth: 2,
                  child: Container(
                    width: double.infinity,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        GestureDetector(
                          onTap: () {
                            onChanged(value - 1);
                          },
                          child: const Icon(
                            Icons.remove,
                            color: Colors.black,
                            size: 40,
                          ),
                        ),
                        Text(
                          '$value',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            onChanged(value + 1);
                          },
                          child: const Icon(
                            Icons.add,
                            color: Colors.black,
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
                  style: const TextStyle(
                    fontSize: 24,
                    fontStyle: FontStyle.italic,
                    color: Colors.black,
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