// lib/components/CounterShelf.dart

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