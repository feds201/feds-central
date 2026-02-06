import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
// IDs for all buttons
const int L1 = 4;
const int L2 = 5;
const int L3 = 6;
const int R1 = 7;
const int R2 = 8;
const int R3 = 9;
Widget buildClimbImage(int? selectedLevel, bool park, ValueChanged<int?> onLevelChanged) {
  return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Container(
          height: 500,
          width:  550,
          decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(25)
          ),
          child: DottedBorder(
            color: const Color(0xFFEFC80C),
            borderType: BorderType.RRect,
            radius: const Radius.circular(20),
            padding: EdgeInsets.zero,
            child:
            Container(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 5,
                    ),
                    const Text(
                      'Climb',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        fontSize: 30,
                        fontFamily: 'MuseoModerno',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      '*If parked, leave blank*',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.yellow,
                        fontStyle: FontStyle.italic,
                        fontSize: 15,
                        fontFamily: 'MuseoModerno',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Text('Level 3', style: TextStyle(color: Colors.white, fontSize: 15),),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => {
                            print("object"),
                            onLevelChanged(selectedLevel == L3 ? null : L3)
                          },
                          child: DottedBorder(
                            color: selectedLevel ==L3 ? Colors.green : const Color(0xFFFB0000),
                            strokeWidth: 5,
                            dashPattern: const [6, 4],
                            borderType: BorderType.RRect,
                            radius: const Radius.circular(10),
                            padding: EdgeInsets.zero,
                            child:  Container(
                              alignment: Alignment.center,
                              height: 55,
                              width:  65,
                              decoration: BoxDecoration(
                                color: const Color(0xFF222222),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xFF222222),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                    offset: Offset(0, 4),
                                    blurStyle: BlurStyle.inner,
                                  ),
                                ],
                              ),
                              child: const Text('L',
                                  style: TextStyle(
                                      color: Color(0xFFDEDEDE),
                                      fontSize: 35,
                                      fontFamily: 'MuseoModerno',
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        TextButton( onPressed: () => onLevelChanged(selectedLevel == 3 ? null : 3),
                        child: DottedBorder(
                        color: selectedLevel ==3 ? Colors.green : const Color(0xFFFB0000),
                        strokeWidth: 5,
                        dashPattern: const [6, 4],
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(10),
                        padding: EdgeInsets.zero,
                            child:  Container(
                              alignment: Alignment.center,
                              height: 45,
                              width:  245,
                              decoration: BoxDecoration(
                                  color:  const Color(0xFF222222),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                              BoxShadow(
                              color: Color(0xFF222222),
                              blurRadius: 16,
                              spreadRadius: 2,
                              offset: Offset(0, 4),
                              blurStyle: BlurStyle.inner,
                            ),
                        ],
                        ),
                              child: const Text('Middle',
                                  style: TextStyle(
                                      color: Color(0xFFDEDEDE),
                                      fontSize: 30,
                                      fontFamily: 'MuseoModerno',
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        TextButton( onPressed: () => onLevelChanged(selectedLevel == R3 ? null : R3),
                            child: DottedBorder(
                                color: selectedLevel ==R3 ? Colors.green : const Color(0xFFFB0000),
                                strokeWidth: 5,
                                dashPattern: const [6, 4],
                                borderType: BorderType.RRect,
                                radius: const Radius.circular(10),
                                padding: EdgeInsets.zero,
                                child:  Container(
                                  alignment: Alignment.center,
                                  height: 55,
                                  width:  65,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF222222),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0xFF353433),
                                        blurRadius: 16,
                                      spreadRadius: 2,
                                        offset: Offset(0, 4),
                                        blurStyle: BlurStyle.inner,
                                      ),
                                    ],
                                  ),
                                  child: const Text('R',
                                      style: TextStyle(
                                          color: Color(0xFFDEDEDE),
                                          fontSize: 35,
                                          fontFamily: 'MuseoModerno',
                                          fontWeight: FontWeight.w700)),
                                )
                            ))],

                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Text('Level 2', style: TextStyle(color: Colors.white, fontSize: 15),),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton( onPressed: () => onLevelChanged(selectedLevel == L2 ? null : L2),
                          child: DottedBorder(
                            color: selectedLevel ==L2 ? Colors.green : const Color(0xFFFB0000),
                            strokeWidth: 5,
                            dashPattern: const [6, 4],
                            borderType: BorderType.RRect,
                            radius: const Radius.circular(10),
                            padding: EdgeInsets.zero,
                            child:  Container(
                              alignment: Alignment.center,
                              height: 55,
                              width:  65,
                              decoration: BoxDecoration(
                                color: const Color(0xFF222222),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xFF353433),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                    offset: Offset(0, 4),
                                    blurStyle: BlurStyle.inner,
                                  ),
                                ],
                              ),
                              child: const Text('L',
                                  style: TextStyle(
                                      color: Color(0xFFDEDEDE),
                                      fontSize: 35,
                                      fontFamily: 'MuseoModerno',
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        TextButton(onPressed: () => onLevelChanged(selectedLevel == 2 ? null : 2),
                          child: DottedBorder(
                            color: selectedLevel == 2 ? Colors.green : const Color(0xFFFB0000),
                            strokeWidth: 5,
                            dashPattern: const [6, 4],
                            borderType: BorderType.RRect,
                            radius: const Radius.circular(10),
                            padding: EdgeInsets.zero,
                            child:  Container(
                              alignment: Alignment.center,
                              height: 45,
                              width:  245,
                              decoration: BoxDecoration(
                                  color:  const Color(0xFF222222),
                                  borderRadius: BorderRadius.circular(10),
                                boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFF222222),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                  offset: Offset(0, 4),
                                  blurStyle: BlurStyle.inner,
                              ),
                              ],
                              ),
                              child: const Text('Middle',
                                  style: TextStyle(
                                      color: Color(0xFFDEDEDE),
                                      fontSize: 30,
                                      fontFamily: 'MuseoModerno',
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        TextButton( onPressed: () => onLevelChanged(selectedLevel == R2 ? null : R2),
                            child: DottedBorder(
                                color: selectedLevel ==R2 ? Colors.green : const Color(0xFFFB0000),
                                strokeWidth: 5,
                                dashPattern: const [6, 4],
                                borderType: BorderType.RRect,
                                radius: const Radius.circular(10),
                                padding: EdgeInsets.zero,
                                child:  Container(
                                  alignment: Alignment.center,
                                  height: 55,
                                  width:  65,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF222222),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0xFF353433),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                        offset: Offset(0, 4),
                                        blurStyle: BlurStyle.inner,
                                      ),
                                    ],
                                  ),
                                  child: const Text('R',
                                      style: TextStyle(
                                          color: Color(0xFFDEDEDE),
                                          fontSize: 35,
                                          fontFamily: 'MuseoModerno',
                                          fontWeight: FontWeight.w700)),
                                )
                            ))],

                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    Text('Level 1', style: TextStyle(color: Colors.white, fontSize: 15),),
                    const SizedBox(
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(onPressed: () => onLevelChanged(selectedLevel == L1 ? null : L1),
                          child: DottedBorder(
                            color: selectedLevel ==L1 ? Colors.green : const Color(0xFFFB0000),
                            strokeWidth: 5,
                            dashPattern: const [6, 4],
                            borderType: BorderType.RRect,
                            radius: const Radius.circular(10),
                            padding: EdgeInsets.zero,
                            child:  Container(
                              alignment: Alignment.center,
                              height: 55,
                              width:  65,
                              decoration: BoxDecoration(
                                color: const Color(0xFF222222),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xFF353433),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                    offset: Offset(0, 4),
                                    blurStyle: BlurStyle.inner,
                                  ),
                                ],
                              ),
                              child: const Text('L',
                                  style: TextStyle(
                                      color: Color(0xFFDEDEDE),
                                      fontSize: 35,
                                      fontFamily: 'MuseoModerno',
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        TextButton(onPressed: () => onLevelChanged(selectedLevel == 1 ? null : 1),
                          child: DottedBorder(
                            color: selectedLevel == 1 ? Colors.green : const Color(0xFFFB0000),
                            strokeWidth: 5,
                            dashPattern: const [6, 4],
                            borderType: BorderType.RRect,
                            radius: const Radius.circular(10),
                            padding: EdgeInsets.zero,
                            child:  Container(
                              alignment: Alignment.center,
                              height: 45,
                              width:  245,
                              decoration: BoxDecoration(
                                  color:  const Color(0xFF222222),
                                  borderRadius: BorderRadius.circular(10),
                                boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFF222222),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                  offset: Offset(0, 4),
                                  blurStyle: BlurStyle.inner,
                              ),
                              ],
                              ),
                              child: const Text('Middle',
                                  style: TextStyle(
                                      color: Color(0xFFDEDEDE),
                                      fontSize: 30,
                                      fontFamily: 'MuseoModerno',
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        TextButton( onPressed: () => onLevelChanged(selectedLevel == R1 ? null : R1),
                          child: DottedBorder(
                              color: selectedLevel ==R1 ? Colors.green : const Color(0xFFFB0000),
                              strokeWidth: 5,
                              dashPattern: const [6, 4],
                              borderType: BorderType.RRect,
                              radius: const Radius.circular(10),
                              padding: EdgeInsets.zero,
                                child:  Container(
                                  alignment: Alignment.center,
                                  height: 55,
                                  width:  65,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF222222),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0xFF353433),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                        offset: Offset(0, 4),
                                        blurStyle: BlurStyle.inner,
                                      ),
                                    ],
                                  ),
                                  child: const Text('R',
                                      style: TextStyle(
                                          color: Color(0xFFDEDEDE),
                                          fontSize: 35,
                                          fontFamily: 'MuseoModerno',
                                          fontWeight: FontWeight.w700)),
                                )
                            ))],

                    ),

                  ],
                )
            ),
          )));
}
