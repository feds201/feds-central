import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:scouting_app/main.dart';

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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                // Add a subtle border to unselected items so they are visible
                color: isSelected
                    ? Colors.transparent
                    : baseColor.withOpacity(0.3),
                width: 2,
              ),
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
                        : (islightmode() ? Colors.black54 : Colors.white38),
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
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Container(
      // Keep height minimal or remove it to let content expand
      // height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: islightmode()
            ? const Color.fromARGB(255, 255, 255, 255)
            : const Color.fromRGBO(34, 34, 34, 1),
        borderRadius: BorderRadius.circular(12),
        // Subtle shadow for the main container card
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: DottedBorder(
          borderType: BorderType.RRect,
          radius: const Radius.circular(12),
          dashPattern: const [8, 4],
          strokeWidth: 2,
          color: const Color(0xBF254EEA),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Who is in the lead?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: islightmode() ? Colors.black : Colors.white,
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
                        baseColor: islightmode() ? Colors.grey : Colors.white,
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
        ),
      ),
    ),
  );
}
