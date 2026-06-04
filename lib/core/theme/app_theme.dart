import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ── Warm colour palette ───────────────────────────────────────────────────
  static const Color primary = Color(0xFFB5651D); // warm sienna brown
  static const Color primaryLight = Color(0xFFD4845A); // terracotta
  static const Color primaryDark = Color(0xFF7B3F0E); // deep mahogany
  static const Color secondary = Color(0xFFE8C99A); // sand gold
  static const Color accent = Color(0xFFF4A261); // warm amber
  static const Color background = Color(0xFFFAF6F1); // warm off-white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceWarm = Color(0xFFFDF0E0); // warm cream card
  static const Color textPrimary = Color(0xFF2C1810); // dark brown
  static const Color textSecondary = Color(0xFF7A5C4F); // muted brown
  static const Color textHint = Color(0xFFBBA99F); // soft tan
  static const Color divider = Color(0xFFEDD9C5); // warm divider
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF4CAF50);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF8F0), Color(0xFFF5E6D3), Color(0xFFEDD9C5)],
  );

  // ── Text styles ───────────────────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.playfairDisplay(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get headlineMedium => GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyLarge =>
      GoogleFonts.lato(fontSize: 16, color: AppColors.textPrimary);

  static TextStyle get bodyMedium =>
      GoogleFonts.lato(fontSize: 14, color: AppColors.textSecondary);

  static TextStyle get labelLarge => GoogleFonts.lato(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.latoTextTheme(),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWarm,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        hintStyle: GoogleFonts.lato(color: AppColors.textHint, fontSize: 15),
        labelStyle: GoogleFonts.lato(
          color: AppColors.textSecondary,
          fontSize: 15,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
