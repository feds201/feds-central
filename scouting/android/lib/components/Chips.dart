import 'package:flutter/material.dart';

Widget buildChips(List<String> chipLabels, List<List<Color>> chipColors, List<bool> isChipClicked ) {
  assert(chipLabels.length == chipColors.length);

  List<Widget> chips = List<Widget>.generate(chipLabels.length, (index) {
    // This is a placeholder for actual state management logic.
    // In a real application, you would use a StatefulWidget or another state management solution
    // to manage the state of each chip's clicked status.


    return GestureDetector(
      onTap: () {},
      child: buildChip(chipLabels[index], chipColors[index], isChipClicked[index]),
    );
  });

  return Wrap(
    spacing: 8.0, // Horizontal space between chips.
    runSpacing: 4.0, // Vertical space between lines of chips.
    children: chips,
  );
}

Widget buildChip(String label, List<Color> color, bool isChipClicked) {
  return GestureDetector(
    onTap: () {
      // Placeholder for onTap functionality. In a real application, this should update the state
      // of the chip to reflect the clicked status.
    },
    child: Chip(
      label: Text(label),
      backgroundColor: isChipClicked ? color[0].withOpacity(0.2) : color[1].withOpacity(0.2),
      labelStyle: TextStyle(color: isChipClicked ? Colors.black : Colors.black),
    ),
  );
}