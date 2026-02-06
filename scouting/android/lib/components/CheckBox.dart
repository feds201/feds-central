import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:scouting_app/main.dart';

Widget buildCheckBox(String title, bool value, Function(bool) onChanged,
    {bool IconOveride = false}) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
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
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: RadialGradient(
                            radius: 1.0,
                            colors: [
                              Color.fromARGB(255, 34, 34, 34),
                              Colors.black.withOpacity(0.45),
                            ],
                          ),
                        ),
                      ),
                      Center(
                          child: value
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.green,
                                  size: 80,
                                  weight: 1700,
                                )
                              : IconOveride
                                  ? const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                      size: 80,
                                    )
                                  : const SizedBox.shrink()),
                    ],
                  ),
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
}

Widget buildCheckBoxFull(String title, bool value, Function(bool) onChanged,
    {bool IconOveride = false}) {
  return Builder(builder: (context) {
    double screenWidth = MediaQuery.of(context).size.width - 15;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: RadialGradient(
                              radius: 1.0,
                              colors: [
                                Color.fromARGB(255, 34, 34, 34),
                                Colors.black.withOpacity(0.45),
                              ],
                            ),
                          ),
                        ),
                        Center(
                            child: value
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.green,
                                    weight: 1700,
                                    size: 80,
                                  )
                                : IconOveride
                                    ? const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                        size: 50,
                                      )
                                    : const SizedBox.shrink()),
                      ],
                    ),
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
  });
}

Widget buildCheckBoxHalf(String title, bool value, Function(bool) onChanged,
    {bool IconOveride = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Container(
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
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: RadialGradient(
                            radius: 1.0,
                            colors: [
                              Color.fromARGB(255, 34, 34, 34),
                              Colors.black.withOpacity(0.45),
                            ],
                          ),
                        ),
                      ),
                      Center(
                          child: value
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.green,
                                  size: 80,
                                  weight: 1700,
                                )
                              : IconOveride
                                  ? const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                      size: 80,
                                    )
                                  : const SizedBox.shrink()),
                    ],
                  ),
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
}
