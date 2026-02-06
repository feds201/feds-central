import 'package:flutter/material.dart';

Widget buildWinner(BuildContext context, Function(String winner) onclick,
    String selectedWinner) {
  // Helper function to build the styled buttons to avoid code repetition
  Widget buildSelectionButton({
    required String label,
    required String value,
    required Color baseColor,
    required bool isSelected,
  }) {
    return Expanded(
      // Ensures buttons share width equally
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: GestureDetector(
          onTap: () => onclick(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200), // Smooth transition
            curve: Curves.easeInOut,
            height: 70,
            decoration: BoxDecoration(
              // If selected, use full color. If not, use a very dark transparent version.
              color: isSelected ? baseColor : baseColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                // Add a subtle border to unselected items so they are visible
                color: isSelected
                    ? Colors.transparent
                    : baseColor.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      // The "Glow" effect when selected
                      BoxShadow(
                        color: baseColor.withOpacity(0.6),
                        blurRadius: 15,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [], // No shadow when inactive
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    // Text is bright white when selected, dimmed when not
                    color: isSelected
                        ? (value == "Tie" ? Colors.black : Colors.white)
                        : Colors.white38,
                    fontSize: 30, // Slightly reduced base size for safety
                    fontFamily: 'MuseoModerno',
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      height: 160, // Slightly taller to accommodate the glow/shadows
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(34, 34, 34, 1),
        borderRadius: BorderRadius.circular(20),
        // Subtle shadow for the main container card
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Who Won?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontFamily: 'MuseoModerno',
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Red Button
                buildSelectionButton(
                  label: "RED",
                  value: "Red",
                  baseColor: Colors.redAccent,
                  isSelected: selectedWinner == "Red",
                ),

                // Tie Button
                buildSelectionButton(
                  label: "TIE",
                  value: "Tie",
                  baseColor: Colors.white,
                  isSelected: selectedWinner == "Tie",
                ),

                // Blue Button
                buildSelectionButton(
                  label: "BLUE",
                  value: "Blue",
                  baseColor: Colors.blueAccent,
                  isSelected: selectedWinner == "Blue",
                ),
              ],
            ),
          )
        ],
      ),
    ),
  );
}
