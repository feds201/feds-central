import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildClimb() {
  return Container(
    height: 450,
    width: double.infinity,
    color: const Color(0xFF222222),
    child: Column(children: [
      DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        padding: const EdgeInsets.all(6),
        color: const Color(0xFF00FF04),
        dashPattern: const [8, 4],
        strokeWidth: 2,
        child: Center(
          child: Text(
            "Climb",
            style: GoogleFonts.museoModerno(
              fontSize: 25,
              color: const Color(0xFFFFFFFF),
            ),
          ),
        ),
      ),
      DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        padding: const EdgeInsets.all(6),
        color: const Color(0xFF00FF04),
        dashPattern: const [8, 4],
        strokeWidth: 2,
        child:
            new Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
            height: 20,
          ),
          Container(
            height: 40,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {},
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    padding: const EdgeInsets.all(6),
                    color: Colors.red,
                    dashPattern: const [8, 4],
                    strokeWidth: 2,
                    child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(0, 255, 255, 255),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "L",
                            style: GoogleFonts.museoModerno(
                              fontSize: 25,
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                        )),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    padding: const EdgeInsets.all(6),
                    color: Colors.red,
                    dashPattern: const [8, 4],
                    strokeWidth: 2,
                    child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "Middle",
                            style: GoogleFonts.museoModerno(
                              fontSize: 25,
                              color: const Color(0xFFFFFFFF),
                            ),
                          ),
                        )),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    padding: const EdgeInsets.all(6),
                    color: Colors.red,
                    dashPattern: const [8, 4],
                    strokeWidth: 2,
                    child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "R",
                            style: GoogleFonts.museoModerno(
                              fontSize: 25,
                              color: const Color(0xFFFFFFFF),
                            ),
                          ),
                        )),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Container(
            height: 40,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {},
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    padding: const EdgeInsets.all(6),
                    color: Colors.red,
                    dashPattern: const [8, 4],
                    strokeWidth: 2,
                    child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "L",
                            style: GoogleFonts.museoModerno(
                              fontSize: 25,
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                        )),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    padding: const EdgeInsets.all(6),
                    color: Colors.red,
                    dashPattern: const [8, 4],
                    strokeWidth: 2,
                    child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "Middle",
                            style: GoogleFonts.museoModerno(
                              fontSize: 25,
                              color: const Color(0xFFFFFFFF),
                            ),
                          ),
                        )),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    padding: const EdgeInsets.all(6),
                    color: Colors.red,
                    dashPattern: const [8, 4],
                    strokeWidth: 2,
                    child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "R",
                            style: GoogleFonts.museoModerno(
                              fontSize: 25,
                              color: const Color(0xFFFFFFFF),
                            ),
                          ),
                        )),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Container(
            height: 40,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {},
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    padding: const EdgeInsets.all(6),
                    color: Colors.red,
                    dashPattern: const [8, 4],
                    strokeWidth: 2,
                    child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "L",
                            style: GoogleFonts.museoModerno(
                              fontSize: 25,
                              color: const Color(0xFFFFFFFF),
                            ),
                          ),
                        )),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    padding: const EdgeInsets.all(6),
                    color: Colors.red,
                    dashPattern: const [8, 4],
                    strokeWidth: 2,
                    child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "Middle",
                            style: GoogleFonts.museoModerno(
                              fontSize: 25,
                              color: const Color(0xFFFFFFFF),
                            ),
                          ),
                        )),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    padding: const EdgeInsets.all(6),
                    color: Colors.red,
                    dashPattern: const [8, 4],
                    strokeWidth: 2,
                    child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "R",
                            style: GoogleFonts.museoModerno(
                              fontSize: 25,
                              color: const Color(0xFFFFFFFF),
                            ),
                          ),
                        )),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    ]),
  );
}
