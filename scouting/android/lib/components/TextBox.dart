import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scouting_app/main.dart';
import 'package:scouting_app/services/Colors.dart';

import 'CounterShelf.dart';

Widget buildTextBoxs(
    String title, List<dynamic> widgetChildren, Icon titleIcon) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      decoration: BoxDecoration(
        color: islightmode()
            ? lightColors.white
            : const Color.fromARGB(255, 34, 34, 34),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: islightmode()
                ? Colors.grey.withOpacity(0.2)
                : const Color.fromARGB(255, 25, 25, 25),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              children: [
                IconTheme(
                  data: IconThemeData(
                    color: islightmode() ? Colors.black : lightColors.white,
                  ),
                  child: titleIcon,
                ),
                const SizedBox(width: 8),
                Text(title,
                    style: GoogleFonts.museoModerno(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: islightmode() ? Colors.black : lightColors.white,
                    )),
              ],
            ),
            const SizedBox(height: 8),
            ...widgetChildren.map((child) {
              if (child is Widget) {
                return child;
              } else if (child is CounterSettings) {
                return buildCounterShelf([child]);
              } else {
                return Container(); // Fallback for unexpected types
              }
            }),
          ],
        ),
      ),
    ),
  );
}

Widget buildTextBox(String question, String comment, Icon titleIcon,
    TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      decoration: BoxDecoration(
        color: islightmode() ? lightColors.white : darkColors.goodblack,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: islightmode()
                ? Colors.grey.withOpacity(0.2)
                : const Color.fromARGB(255, 25, 25, 25),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTheme(
                  data: IconThemeData(
                    color: islightmode() ? Colors.black : lightColors.white,
                  ),
                  child: titleIcon,
                ),
                const SizedBox(width: 2),
                Text("SHORT ANSWER",
                    style: GoogleFonts.museoModerno(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
              ],
            ),
            Wrap(
              children: [
                const SizedBox(width: 8),
                Text(question,
                    style: GoogleFonts.museoModerno(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: islightmode() ? Colors.black : lightColors.white,
                    )),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              style: TextStyle(
                color: islightmode() ? Colors.black : lightColors.white,
              ),
              decoration: InputDecoration(
                hintText: comment,
                hintStyle: TextStyle(
                  color: islightmode() ? Colors.grey : Colors.grey.shade400,
                ),
                filled: true,
                fillColor: islightmode()
                    ? Colors.white
                    : darkColors.goodblack.withOpacity(0.7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: islightmode() ? Colors.grey : lightColors.light_grey,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: islightmode() ? Colors.grey : lightColors.light_grey,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: islightmode()
                        ? lightColors.light_blue
                        : darkColors.advay_dark_blue,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildNumberBox(
    String question, double number, Icon titleIcon, Function onchange) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      decoration: BoxDecoration(
        color: islightmode() ? lightColors.white : darkColors.goodblack,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: islightmode()
                ? Colors.grey.withOpacity(0.2)
                : Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTheme(
                  data: IconThemeData(
                    color: islightmode() ? Colors.black : lightColors.white,
                  ),
                  child: titleIcon,
                ),
                const SizedBox(width: 2),
                Text("NUMBER INPUT",
                    style: GoogleFonts.museoModerno(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
              ],
            ),
            Wrap(
              children: [
                const SizedBox(width: 8),
                Text(question,
                    style: GoogleFonts.museoModerno(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: islightmode() ? Colors.black : lightColors.white,
                    )),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: islightmode() ? Colors.black : lightColors.white,
              ),
              decoration: InputDecoration(
                hintText: number.toString(),
                hintStyle: TextStyle(
                  color: islightmode() ? Colors.grey : Colors.grey.shade400,
                ),
                filled: true,
                fillColor: islightmode()
                    ? Colors.white
                    : darkColors.goodblack.withOpacity(0.7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: islightmode() ? Colors.grey : lightColors.light_grey,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: islightmode() ? Colors.grey : lightColors.light_grey,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: islightmode()
                        ? lightColors.light_blue
                        : darkColors.advay_dark_blue,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                onchange(value.toString());
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildDualBox(String question, Icon titleIcon, List<String> choices,
    String selectedValue, Function(String) onchange) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      decoration: BoxDecoration(
        color: islightmode() ? lightColors.white : darkColors.goodblack,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: islightmode()
                ? Colors.grey.withOpacity(0.2)
                : Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTheme(
                  data: IconThemeData(
                    color: islightmode() ? Colors.black : lightColors.white,
                  ),
                  child: titleIcon,
                ),
                const SizedBox(width: 2),
                Text("YES/NO QUESTION",
                    style: GoogleFonts.museoModerno(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
              ],
            ),
            Wrap(
              children: [
                const SizedBox(width: 8),
                Text(question,
                    style: GoogleFonts.museoModerno(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: islightmode() ? Colors.black : lightColors.white,
                    )),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: choices.map((String choice) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          choice,
                          style: GoogleFonts.museoModerno(
                            fontSize: 25,
                            color: selectedValue == choice
                                ? Colors.white
                                : (islightmode() ? Colors.black : Colors.white),
                          ),
                        ),
                      ),
                      selectedColor: islightmode()
                          ? darkColors.dark_green
                          : darkColors.advay_dark_green,
                      backgroundColor: islightmode()
                          ? Colors.grey.shade200
                          : darkColors.goodblack.withOpacity(0.7),
                      selected: selectedValue == choice,
                      side: BorderSide(
                        color: islightmode() ? Colors.black : Colors.white,
                      ),
                      onSelected: (bool selected) {
                        if (selected) {
                          onchange(choice);
                        }
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

Widget buildChoiceBox(String question, Icon titleIcon, List<String> choices,
    String selectedValue, Function(String) onchange) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      decoration: BoxDecoration(
        color: islightmode() ? lightColors.white : darkColors.goodblack,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: islightmode()
                ? Colors.grey.withOpacity(0.2)
                : Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTheme(
                  data: IconThemeData(
                    color: islightmode() ? Colors.black : lightColors.white,
                  ),
                  child: titleIcon,
                ),
                const SizedBox(width: 2),
                Text("MULTIPLE CHOICE",
                    style: GoogleFonts.museoModerno(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
              ],
            ),
            Wrap(
              children: [
                const SizedBox(width: 8),
                Text(question,
                    style: GoogleFonts.museoModerno(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: islightmode() ? Colors.black : lightColors.white,
                    )),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: choices.map((String choice) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: islightmode()
                              ? Colors.grey.withOpacity(0.4)
                              : Colors.black.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          choice,
                          style: GoogleFonts.museoModerno(
                            fontSize: 25,
                            color: choice == selectedValue
                                ? Colors.white
                                : (islightmode() ? Colors.black : Colors.white),
                          ),
                        ),
                      ),
                      selectedColor: islightmode()
                          ? darkColors.advay_dark_blue
                          : darkColors.dark_blue,
                      backgroundColor: islightmode()
                          ? Colors.grey.shade200
                          : darkColors.goodblack.withOpacity(0.7),
                      selected: choice == selectedValue,
                      side: BorderSide(
                        color: islightmode() ? Colors.black : Colors.white,
                      ),
                      onSelected: (bool selected) {
                        onchange(choice);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildMultiChoiceBox(
    String question,
    Icon titleIcon,
    List<String> choices,
    List<String>
        selectedValues, // Change to List<String> to track multiple selected choices
    Function(List<String>) onchange) {
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                titleIcon,
                const SizedBox(width: 2),
                Text("MULTIPLE CHOICE",
                    style: GoogleFonts.museoModerno(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
              ],
            ),
            Wrap(
              children: [
                const SizedBox(width: 8),
                Text(question,
                    style: GoogleFonts.museoModerno(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
            const SizedBox(height: 16),
            // Fixed structure and selection logic
            Column(
              children: choices.map((String choice) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.4),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          choice,
                          style: GoogleFonts.museoModerno(fontSize: 25),
                        ),
                      ),
                      selectedColor: const Color.fromARGB(147, 0, 122, 248),
                      backgroundColor: Colors.grey.shade200,
                      selected: selectedValues.contains(choice),
                      side: const BorderSide(color: Colors.black),
                      onSelected: (bool selected) {
                        List<String> newSelectedValues =
                            List.from(selectedValues);
                        if (selected) {
                          newSelectedValues.add(choice);
                        } else {
                          newSelectedValues.remove(choice);
                        }
                        onchange(newSelectedValues);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ),
  );
}
