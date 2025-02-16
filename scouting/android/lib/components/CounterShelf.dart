// lib/components/CounterShelf.dart

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class CounterSettings {
  final IconData icon;
  final int number;
  final String counterText;
  final Color color;
  final Function(int) onIncrement;
  final Function(int) onDecrement;

  CounterSettings(
    this.onIncrement,
    this.onDecrement, {
    required this.icon,
    required this.number,
    required this.counterText,
    required this.color,
  });
}

// ignore: avoid_types_as_parameter_names
void defaultIncrement(int) {
  print('Incremented');
}

void defaultDecrement(int) {
  print('Decremented');
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
            offset: const Offset(1, 3),
          ),
        ],
      ),
      child: Column(
        children: counterSettings.map((settings) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
                    settings.onDecrement(settings.number);
                  },
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  '${settings.number}', // Display starting number
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    settings.onIncrement(settings.number);
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

Widget buildCounter(String title, int value, Function(int) onChanged,
    {required MaterialColor color}) {
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
                  color: color,
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
