// lib/core/theme/app_theme.dart
// ──────────────────────────────
// Clean, professional black-and-white theme used throughout the app.
// All colour references go through this file — never hard-code colours in widgets.

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color black        = Color(0xFF0A0A0A);
  static const Color white        = Color(0xFFFFFFFF);
  static const Color grey100      = Color(0xFFF5F5F5);
  static const Color grey200      = Color(0xFFEEEEEE);
  static const Color grey400      = Color(0xFFBDBDBD);
  static const Color grey600      = Color(0xFF757575);
  static const Color grey800      = Color(0xFF424242);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color errorRed     = Color(0xFFC62828);
  static const Color warningAmber = Color(0xFFE65100);

  // ── Status chip colours ───────────────────────────────────────────────────
  static const Color chipPresent     = Color(0xFFE8F5E9);
  static const Color chipPresentText = Color(0xFF2E7D32);
  static const Color chipCheckedOut  = Color(0xFFE3F2FD);
  static const Color chipCheckedOutText = Color(0xFF1565C0);
  static const Color chipAbsent      = Color(0xFFFCE4EC);
  static const Color chipAbsentText  = Color(0xFFC62828);

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary:   black,
        onPrimary: white,
        secondary: grey800,
        onSecondary: white,
        surface:   white,
        onSurface: black,
        error:     errorRed,
        onError:   white,
      ),
      scaffoldBackgroundColor: white,

      // ── AppBar ─────────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor:  white,
        foregroundColor:  black,
        elevation:        0,
        scrolledUnderElevation: 1,
        shadowColor:      grey200,
        titleTextStyle: TextStyle(
          color:      black,
          fontSize:   18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: black),
      ),

      // ── Elevated button — PRIMARY action (black background, white text) ───
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:  black,
          foregroundColor:  white,
          disabledBackgroundColor: grey400,
          disabledForegroundColor: grey600,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize:   15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          elevation: 0,
        ),
      ),

      // ── Outlined button — SECONDARY action (white background, black border) ─
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: black,
          side: const BorderSide(color: black, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize:   15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ── Text button ────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: black,
          textStyle: const TextStyle(
            fontSize:   14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ── Card ───────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: grey200, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // ── Input fields ───────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:          true,
        fillColor:       grey100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: black, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
      ),

      // ── ListTile ───────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),

      // ── Divider ────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: grey200,
        thickness: 1,
        space: 1,
      ),

      // ── SnackBar ───────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: black,
        contentTextStyle: const TextStyle(color: white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
