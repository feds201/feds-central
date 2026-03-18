import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBackground = Color(0xFF0A0A0F);
  static const Color secondaryBackground = Color(0xFF16162A);
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Colors.white70;
  static const Color accent = Color(0xFF6C63FF);
  static const Color success = Color(0xFF00E676);
  static const Color warning = Colors.orangeAccent;
  static const Color error = Color(0xFFFF5252);
  static const Color batteryGreen = Color(0xFF00E676);
  static const Color batteryYellow = Colors.yellow;
  static const Color batteryOrange = Colors.orangeAccent;
  static const Color batteryRed = Color(0xFFFF5252);
}

class AppConstants {
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 14.0;
  static const double largeBorderRadius = 18.0;
  static const double headerHeight = 56.0;
  static const double actionButtonSize = 50.0;
  static const double batteryIndicatorWidth = 100.0;
  static const double controlButtonWidth = 80.0;
  static const double controlButtonHeight = 40.0;
}

class AppStrings {
  static const String appTitle = 'SCOUT-UP SCAN';
  static const String moduleBattery = 'MODULE';
  static const String targetBattery = 'TARGET';
  static const String resetButton = 'Reset';
  static const String syncButton = 'Sync';
  static const String exportButton = 'Export';
  static const String historyButton = 'History';
  static const String qrCodeDetected = 'QR Code Detected';
  static const String noQrCode = 'No QR code found';
  static const String unknownCode = 'Unknown';
}
