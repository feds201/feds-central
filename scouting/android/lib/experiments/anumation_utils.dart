import 'package:flutter/material.dart';

double getAnimValue(
    {required double start,
    required double end,
    required Animation animation}) {
  return ((end - start) * animation.value) + start;
}
