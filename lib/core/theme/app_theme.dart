import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Warm colour palette ───────────────────────────────────────────────────
  static const Color primary       = Color(0xFFB5651D); // warm sienna brown
  static const Color primaryLight  = Color(0xFFD4845A); // terracotta
  static const Color primaryDark   = Color(0xFF7B3F0E); // deep mahogany
  static const Color secondary     = Color(0xFFE8C99A); // sand gold
  static const Color accent        = Color(0xFFF4A261); // warm amber
  static const Color background    = Color(0xFFFAF6F1); // warm off-white
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color surfaceWarm   = Color(0xFFFDF0E0); // warm cream card
  static const Color textPrimary   = Color(0xFF2C1810); // dark brown
  static const Color textSecondary = Color(0xFF7A5C4F); // muted brown
  static const Color textHint      = Color(0xFFBBA99F); // soft tan
  static const Color divider       = Color(0xFFEDD9C5); // warm divider
  static const Color error         = Color(0xFFB00020);
  static const Color success       = Color(0xFF4CAF50);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF8F0), Color(0xFFF5E6D3), Color(0xFFEDD9C5)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary, primaryDark],
  );

  // ── Text styles ───────────────────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.playfairDisplay(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get headlineMedium => GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.lato(
        fontSize: 16,
        color: textPrimary,
        letterSpacing: 0.1,
      );

  static TextStyle get bodyMedium => GoogleFonts.lato(
        fontSize: 14,
        color: textSecondary,
      );

  static TextStyle get labelLarge => GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.5,
      );

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.latoTextTheme().copyWith(
        displayLarge: displayLarge,
        headlineMedium: headlineMedium,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        labelLarge: labelLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWarm,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: divider, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        hintStyle: GoogleFonts.lato(color: textHint, fontSize: 15),
        labelStyle: GoogleFonts.lato(color: textSecondary, fontSize: 15),
        prefixIconColor: textHint,
        suffixIconColor: textHint,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: labelLarge,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
