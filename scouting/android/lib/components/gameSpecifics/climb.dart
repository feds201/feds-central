import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildClimb() {
  return Container(
    height: 450,
    width: double.infinity,
    color: const Color.fromRGBO(34, 34, 34, 1),
    child: new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
                            color: const Color(0xA1CCC2C2),
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
                            color: const Color(0xA1CCC2C2),
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
                            color: const Color(0xA1CCC2C2),
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
          color: const Color.fromARGB(255, 198, 243, 33),
        ),
        SizedBox(
          height: 20,
        ),
        Container(
          height: 40,
          width: double.infinity,
          color: const Color.fromARGB(255, 243, 33, 243),
        ),
      ],
    ),
  );
}
