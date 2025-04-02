import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import 'CounterShelf.dart';

Widget buildComments(
    String title, List<dynamic> widgetChildren, Icon titleIcon) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      decoration: BoxDecoration(
        color: islightmode()
            ? const Color.fromARGB(255, 255, 255, 255)
            : const Color.fromARGB(255, 34, 34, 34),
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
                const SizedBox(width: 8),
                Text(title,
                    style: GoogleFonts.museoModerno(
                      fontSize: 20,
                      color: islightmode()
                          ? const Color.fromARGB(255, 0, 0, 0)
                          : const Color.fromARGB(255, 255, 255, 255),
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

Widget buildCommentsBox(
    String title, String comment, Icon titleIcon, Function(String) onChanged) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      decoration: BoxDecoration(
        color: islightmode()
            ? const Color.fromARGB(255, 255, 255, 255)
            : const Color.fromARGB(255, 34, 34, 34),
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
                const SizedBox(width: 8),
                Text(title,
                    style: GoogleFonts.museoModerno(
                      fontSize: 20,
                      color: !islightmode()
                          ? const Color.fromARGB(255, 255, 255, 255)
                          : const Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment,
              style: GoogleFonts.museoModerno(
                fontSize: 16,
                color: !islightmode()
                    ? const Color.fromARGB(255, 255, 255, 255)
                    : const Color.fromARGB(255, 0, 0, 0),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
