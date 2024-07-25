import 'package:flutter/material.dart';

Widget buildCounterShelf(int count) {
  // Step 1: Define base height for a single counter (adjust based on your UI)
  final double baseHeightPerCounter = 56.0; // Example: 56.0 pixels per counter
  final double verticalPadding = 16.0; // Padding above and below the list

  // Step 2 & 3: Calculate total height
  final double totalHeight = count * baseHeightPerCounter + verticalPadding * 2;

  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      // Step 4: Set the calculated height
      height: totalHeight,
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
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(), // Since we're manually setting the height
        itemCount: count,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome),
                const SizedBox(width: 16),
                Text(
                  'Counter ${index + 1}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () {
                    // Decrement counter value logic here
                  },
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  '0', // Placeholder for counter value
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
        },
      ),
    ),
  );
}