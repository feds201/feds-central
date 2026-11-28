import 'package:flutter/material.dart';

Widget buildYesNoToggle(String title, bool value, Function(bool) onChanged) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: value ? Colors.green : Colors.red,
        foregroundColor: Colors.white,
      ),
      onPressed: () {
        onChanged(!value);
      },
      child: Text('$title: ${value ? 'YES' : 'NO'}'),
    ),
  );
}