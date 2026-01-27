import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:scouting_app/main.dart';

Widget buildCheckBox(String title, bool value, Function(bool) onChanged,
    {bool IconOveride = false}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      double screenWidth = MediaQuery.of(context).size.width - 25;
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: screenWidth / 2,
          decoration: BoxDecoration(
            color: islightmode()
                ? const Color.fromARGB(255, 255, 255, 255)
                : const Color.fromARGB(255, 34, 34, 34),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    onChanged(!value);
                  },
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    padding: const EdgeInsets.all(6),
                    color: value ? Colors.green : Colors.red,
                    dashPattern: const [8, 4],
                    strokeWidth: 2,
                    child: Container(
                      width: double.infinity,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                          child: value
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                  size: 50,
                                )
                              : IconOveride
                                  ? const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                      size: 50,
                                    )
                                  : const SizedBox.shrink()),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontStyle: FontStyle.italic,
                    color: !islightmode()
                        ? const Color.fromARGB(255, 255, 255, 255)
                        : const Color.fromARGB(255, 34, 34, 34),
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

Widget buildCheckBoxFull(String title, bool value, Function(bool) onChanged,
    {bool IconOveride = false}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      double screenWidth = MediaQuery.of(context).size.width - 15;
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: screenWidth,
          decoration: BoxDecoration(
            color: islightmode()
                ? const Color.fromARGB(255, 255, 255, 255)
                : const Color.fromARGB(255, 34, 34, 34),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    onChanged(!value);
                  },
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    padding: const EdgeInsets.all(6),
                    color: value ? Colors.green : Colors.red,
                    dashPattern: const [8, 4],
                    strokeWidth: 2,
                    child: Container(
                      width: double.infinity,
                      height: 100,
                      decoration: BoxDecoration(
                        color: islightmode()
                            ? const Color.fromARGB(255, 255, 255, 255)
                            : const Color.fromARGB(255, 34, 34, 34),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                          child: value
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                  size: 50,
                                )
                              : IconOveride
                                  ? const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                      size: 50,
                                    )
                                  : const SizedBox.shrink()),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontStyle: FontStyle.italic,
                    color: !islightmode()
                        ? const Color.fromARGB(255, 255, 255, 255)
                        : const Color.fromARGB(255, 0, 0, 0),
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
