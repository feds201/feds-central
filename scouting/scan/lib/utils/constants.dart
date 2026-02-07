import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBackground = Color(0xFF1C1C1C);
  static const Color secondaryBackground = Color(0xFF2C2C2C);
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Colors.white70;
  static const Color accent = Colors.red;
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color error = Colors.red;
  static const Color batteryGreen = Colors.green;
  static const Color batteryYellow = Colors.yellow;
  static const Color batteryOrange = Colors.orange;
  static const Color batteryRed = Colors.red;
}

class AppConstants {
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const double largeBorderRadius = 12.0;
  static const double headerHeight = 80.0;
  static const double shutterButtonSize = 80.0;
  static const double batteryIndicatorWidth = 100.0;
  static const double controlButtonWidth = 80.0;
  static const double controlButtonHeight = 40.0;
}

class AppStrings {
  static const String appTitle = 'SCOUT OPS DATA';
  static const String moduleBattery = 'MODULE BATTERY';
  static const String targetBattery = 'TARGET BATTERY';
  static const String resetButton = 'RESET';
  static const String testButton = 'TEST';
  static const String qrCodeDetected = 'QR Code Detected';
  static const String noQrCode = 'No QR code found';
  static const String unknownCode = 'Unknown';
}
