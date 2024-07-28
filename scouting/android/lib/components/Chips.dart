import 'package:flutter/material.dart';

void DefaultonChipUpdate(String label) {
  print('Chip clicked: ' + label);
}

Widget buildChips(List<String> chipLabels, List<List<Color>> chipColors, List<bool> isChipClicked, {List<Function(String)>? onTapList}) {
  assert(chipLabels.length == chipColors.length);
  assert(onTapList == null || chipLabels.length == onTapList.length);

  List<Widget> chips = List<Widget>.generate(chipLabels.length, (index) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return GestureDetector(
          onTap: () {
            setState(() {
              isChipClicked[index] = !isChipClicked[index];
            });
            if (onTapList != null) {
              onTapList[index](chipLabels[index]);
            } else {
              DefaultonChipUpdate(chipLabels[index]);
            }
          },
          child: buildChip(chipLabels[index], chipColors[index], isChipClicked[index]),
        );
      },
    );
  });

  return Wrap(
    spacing: 8.0, // Horizontal space between chips.
    runSpacing: 4.0, // Vertical space between lines of chips.
    children: chips,
  );
}

Widget buildChip(String label, List<Color> color, bool isChipClicked) {
  return Chip(
    label: Text(label),
    backgroundColor: isChipClicked ? color[0].withOpacity(0.2) : color[1].withOpacity(0.2),
    labelStyle: TextStyle(color: isChipClicked ? Colors.black : Colors.black),
  );
}