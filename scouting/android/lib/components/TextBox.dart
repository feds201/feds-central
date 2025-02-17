import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'CounterShelf.dart';

Widget buildTextBoxs(
    String title, List<dynamic> widgetChildren, Icon titleIcon) {
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
            Wrap(
              children: [
                titleIcon,
                const SizedBox(width: 8),
                Text(title,
                    style: GoogleFonts.museoModerno(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
                    )),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: comment,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
