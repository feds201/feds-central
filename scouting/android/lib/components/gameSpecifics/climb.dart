import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:scouting_app/main.dart';

// IDs for all buttons
const int L1 = 4;
const int L2 = 5;
const int L3 = 6;
const int R1 = 7;
const int R2 = 8;
const int R3 = 9;

Widget buildClimbImage(
    int? selectedLevel, bool park, ValueChanged<int?> onLevelChanged) {
  // Theme helpers
  final bool isLight = islightmode();
  final Color backgroundColor = isLight
      ? const Color.fromARGB(255, 255, 255, 255)
      : const Color.fromARGB(255, 34, 34, 34);
  final Color textColor = !isLight
      ? const Color.fromARGB(255, 255, 255, 255)
      : const Color.fromARGB(255, 34, 34, 34);
  final Color barColor =
      isLight ? Colors.grey.shade300 : const Color(0xFF444444);

  // Matches the blue dotted border from the Timer widget
  final Color dottedBorderColor = const Color(0xBF254EEA);

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10.0),
    child: Container(
      constraints: const BoxConstraints(maxWidth: 600),
      // Outer container with background color, like the Timer widget
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        // Padding separating the outer container edge from the dotted border
        padding: const EdgeInsets.all(12.0),
        child: DottedBorder(
          borderType: BorderType.RRect,
          radius: const Radius.circular(12),
          dashPattern: const [10, 4],
          strokeWidth: 3,
          color: dottedBorderColor,
          child: Padding(
            // Inner padding for content spacing away from border
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 5),
                Text(
                  'Climb',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 32,
                    fontFamily: 'MuseoModerno',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.yellow.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'If parked, leave blank',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFEFC80C),
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                      fontFamily: 'MuseoModerno',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Stack(
                    children: [
                      // Background Cage Bars (Continuous Line)
                      Positioned.fill(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(width: 70), // Matches Left Button
                            const SizedBox(width: 8), // Gap
                            Container(width: 10, color: barColor),
                            const SizedBox(width: 8), // Gap
                            const Expanded(child: SizedBox()),
                            const SizedBox(width: 8), // Gap
                            Container(width: 10, color: barColor), // Right Bar
                            const SizedBox(width: 8), // Gap
                            const SizedBox(width: 70), // Matches Right Button
                          ],
                        ),
                      ),
                      // Buttons
                      Column(
                        children: [
                          _buildLevelRow('LEVEL 3', Colors.red, L3, 3, R3,
                              selectedLevel, onLevelChanged, isLight),
                          const SizedBox(height: 15),
                          _buildLevelRow('LEVEL 2', Colors.orange, L2, 2, R2,
                              selectedLevel, onLevelChanged, isLight),
                          const SizedBox(height: 15),
                          _buildLevelRow('LEVEL 1', Colors.green, L1, 1, R1,
                              selectedLevel, onLevelChanged, isLight),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildLevelRow(
    String label,
    Color labelColor,
    int leftId,
    int midId,
    int rightId,
    int? selectedLevel,
    ValueChanged<int?> onLevelChanged,
    bool isLight) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Center(
        child: Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 14,
            fontFamily: 'MuseoModerno',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
      const SizedBox(height: 4),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
                width: 70,
                child: _buildClimbButton("L", leftId,
                    selectedLevel: selectedLevel,
                    onChanged: onLevelChanged,
                    color: labelColor,
                    isLight: isLight)),
            const SizedBox(
                width: 26), // Transparent for background bar (8+10+8)
            Expanded(
              child: _buildClimbButton("Middle", midId,
                  selectedLevel: selectedLevel,
                  onChanged: onLevelChanged,
                  color: labelColor,
                  isMiddle: true,
                  isLight: isLight),
            ),
            const SizedBox(
                width: 26), // Transparent for background bar (8+10+8)
            SizedBox(
                width: 70,
                child: _buildClimbButton("R", rightId,
                    selectedLevel: selectedLevel,
                    onChanged: onLevelChanged,
                    color: labelColor,
                    isLight: isLight)),
          ],
        ),
      ),
    ],
  );
}

Widget _buildClimbButton(String text, int id,
    {required int? selectedLevel,
    required ValueChanged<int?> onChanged,
    required Color color,
    required bool isLight,
    bool isMiddle = false}) {
  final isSelected = selectedLevel == id;

  // Dynamic colors based on theme
  final Color unselectedBg =
      isLight ? Colors.grey.shade100 : const Color(0xFF333333);
  final Color unselectedBorder =
      isLight ? Colors.grey.shade300 : Colors.white24;
  final Color unselectedText = isLight ? Colors.black54 : Colors.white60;

  // Use slightly dimmer colors for unselected state
  final displayColor = isSelected ? color : unselectedBg;
  final textColor = isSelected ? Colors.black : unselectedText;
  final borderColor = isSelected ? color : unselectedBorder;

  return GestureDetector(
    onTap: () => onChanged(isSelected ? null : id),
    child: Container(
      height: 55,
      decoration: BoxDecoration(
        color: displayColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        boxShadow: isSelected
            ? [
                BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 1)
              ]
            : [],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: isMiddle ? 18 : 22,
          fontFamily: 'MuseoModerno',
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}
