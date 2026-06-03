import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The official, trademarked Infortts™ Acoustic-Refraction™ / Rocky-Vision™ Color Palette.
class AcousticColors {
  // ACES Crushed Blacks & Carbon Base
  static const Color black = Color(0xFF05070C);         // Deepest desaturated base
  static const Color darkCarbon = Color(0xFF090D1A);    // Standard background
  static const Color panelBg = Color(0xFF121B2D);       // Volumetric card fill
  static const Color activeCard = Color(0xFF1D2A44);     // Highlighted panel base

  // Desaturated Midtones (Cool Slate)
  static const Color midGray = Color(0xFF64748B);       // Borders and subtext
  static const Color steel = Color(0xFF94A3B8);         // Body copy
  static const Color titanium = Color(0xFFE2E8F0);      // High-contrast titles

  // Motivated Emissives (Acoustic Cyan & Warm Warnings)
  static const Color sonarCyan = Color(0xFF00D2FF);     // High-frequency active state
  static const Color sonarCyanDim = Color(0xFF005566);  // Idle/ambient shadow glow
  static const Color sonarBlue = Color(0xFF0066FF);     // Low-frequency active state
  static const Color warnOrange = Color(0xFFF97316);    // Low-saturation warning
}

/// The official, trademarked Infortts™ Acoustic-Refraction™ / Rocky-Vision™ Design Theme.
class AcousticTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AcousticColors.black,
      colorScheme: const ColorScheme.dark(
        background: AcousticColors.black,
        surface: AcousticColors.darkCarbon,
        primary: AcousticColors.sonarCyan,
        secondary: AcousticColors.sonarBlue,
        error: AcousticColors.warnOrange,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        TextTheme(
          displayLarge: TextStyle(
            color: AcousticColors.titanium,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.2,
          ),
          titleLarge: TextStyle(
            color: AcousticColors.titanium,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          bodyLarge: const TextStyle(
            color: AcousticColors.steel,
            letterSpacing: 0.1,
          ),
          bodyMedium: const TextStyle(
            color: AcousticColors.midGray,
          ),
        ),
      ),
    );
  }
  
  // Spacious padding/margin definitions for premium youth-focused minimalist layouts
  static const double spacingXS = 8.0;
  static const double spacingS = 16.0;
  static const double spacingM = 24.0;
  static const double spacingL = 36.0;
  static const double spacingXL = 48.0;
  static const double spacingXXL = 64.0;
}
