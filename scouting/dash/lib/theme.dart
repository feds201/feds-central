import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Palette (placeholder — will swap to Team 201 brand) ──────────
  static const Color bg        = Color(0xFF0C1017);
  static const Color surface   = Color(0xFF12161F);
  static const Color surfaceHi = Color(0xFF1A1F2E);
  static const Color border    = Color(0xFF252B3B);
  static const Color muted     = Color(0xFF5C6478);
  static const Color text      = Color(0xFFE1E4ED);
  static const Color accent    = Color(0xFF38BDF8);   // sky — placeholder
  static const Color accent2   = Color(0xFFA78BFA);   // violet — slot 2
  static const Color accent3   = Color(0xFF34D399);   // emerald — slot 3
  static const Color gold      = Color(0xFFFBBF24);
  static const Color red       = Color(0xFFF87171);
  static const Color green     = Color(0xFF4ADE80);

  /// Colors assigned to each of the 3 comparison slots.
  static const List<Color> slotColors = [accent, accent2, accent3];

  // ── Theme Data ───────────────────────────────────────────────────
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        surface: surface,
        primary: accent,
        secondary: gold,
        error: red,
        onSurface: text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _heading(18, text),
        iconTheme: const IconThemeData(color: text),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHi,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        labelStyle: _body(13, muted),
        hintStyle: _body(13, muted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: bg,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: _heading(14, bg),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      textTheme: TextTheme(
        headlineLarge: _heading(28, text),
        headlineMedium: _heading(22, text),
        headlineSmall: _heading(18, text),
        titleLarge: _heading(16, text),
        titleMedium: _heading(14, text),
        titleSmall: _heading(13, text),
        bodyLarge: _body(15, text),
        bodyMedium: _body(13, text),
        bodySmall: _body(11, muted),
        labelLarge: _label(13, text),
        labelMedium: _label(11, text),
        labelSmall: _label(10, muted),
      ),
    );
  }

  // ── Typography ───────────────────────────────────────────────────
  static TextStyle _heading(double size, Color color) =>
      GoogleFonts.outfit(
          fontSize: size, fontWeight: FontWeight.w600, color: color);

  static TextStyle _body(double size, Color color) =>
      GoogleFonts.inter(
          fontSize: size, fontWeight: FontWeight.w400, color: color);

  static TextStyle _label(double size, Color color) =>
      GoogleFonts.jetBrainsMono(
          fontSize: size, fontWeight: FontWeight.w500, color: color);

  static TextStyle mono(double size, {Color color = text}) =>
      GoogleFonts.jetBrainsMono(
          fontSize: size, color: color, fontWeight: FontWeight.w400);
}
