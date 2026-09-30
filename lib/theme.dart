import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Global switch that flips the Acoustic palette between dark and light.
/// The terminal app paints the whole UI from [AcousticColors], so flipping
/// this and rebuilding MaterialApp re-skins every screen (not just Material
/// widgets).
final ValueNotifier<Brightness> acousticBrightness =
    ValueNotifier<Brightness>(Brightness.dark);

/// The official, trademarked Infortts™ Acoustic-Refraction™ / Rocky-Vision™ Color Palette.
class AcousticColors {
  static bool get isLight => acousticBrightness.value == Brightness.light;

  // ---- ACES Crushed Blacks & Carbon Base (Dark palette) ----
  static const Color blackDark = Color(0xFF05070C);        // Deepest desaturated base
  static const Color obsidianDark = Color(0xFF0D1117);     // Obsidian surface base
  static const Color darkCarbonDark = Color(0xFF090D1A);   // Standard background
  static const Color panelBgDark = Color(0xFF121B2D);      // Volumetric card fill
  static const Color activeCardDark = Color(0xFF1D2A44);   // Highlighted panel base

  // ---- Crisp Clean Light Base (Light palette) ----
  static const Color blackLight = Color(0xFFF8FAFC);       // Slate 50 canvas
  static const Color obsidianLight = Color(0xFFFFFFFF);    // Pure white surface
  static const Color darkCarbonLight = Color(0xFFFFFFFF);  // Clean white surface/card
  static const Color panelBgLight = Color(0xFFF1F5F9);     // Slate 100 panel fill
  static const Color activeCardLight = Color(0xFFE2E8F0);  // Slate 200 highlighted panel

  // Dynamic Base Getters
  static Color get black => isLight ? blackLight : blackDark;
  static Color get obsidian => isLight ? obsidianLight : obsidianDark;
  static Color get darkCarbon => isLight ? darkCarbonLight : darkCarbonDark;
  static Color get panelBg => isLight ? panelBgLight : panelBgDark;
  static Color get activeCard => isLight ? activeCardLight : activeCardDark;

  // ---- Desaturated Midtones (Cool Slate) ----
  static const Color midGrayDark = Color(0xFF64748B);       // Borders and subtext (Slate 500)
  static const Color midGrayLight = Color(0xFF94A3B8);      // Borders and subtext in light (Slate 400)
  static Color get midGray => isLight ? midGrayLight : midGrayDark;

  static const Color steelDark = Color(0xFF94A3B8);         // Body copy (Slate 400)
  static const Color steelLight = Color(0xFF475569);        // Body copy in light (Slate 600)
  static Color get steel => isLight ? steelLight : steelDark;

  static const Color titaniumDark = Color(0xFFE2E8F0);      // High-contrast titles (Slate 200)
  static const Color titaniumLight = Color(0xFF0F172A);     // High-contrast titles in light (Slate 900)
  static Color get titanium => isLight ? titaniumLight : titaniumDark;

  // ---- Motivated Emissives (Acoustic Cyan & Warm Warnings) ----
  static const Color sonarCyan = Color(0xFF00D2FF);     // Active state
  static const Color sonarCyanDim = Color(0xFF005566);  // Idle/ambient shadow glow
  static const Color sonarBlue = Color(0xFF0066FF);     // Low-frequency active state
  static const Color warnOrange = Color(0xFFF97316);    // Low-saturation warning

  // Light theme colors
  static const Color lightBackground = Color(0xFFF8FAFC);   // Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF);      // White
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9); // Slate 100
  static const Color lightOnBackground = Color(0xFF0F172A);  // Slate 900
  static const Color lightOnSurface = Color(0xFF1E293B);     // Slate 800
  static const Color lightOutline = Color(0xFFCBD5E1);       // Slate 300
  static const Color lightOnSurfaceVariant = Color(0xFF475569); // Slate 600
}

/// The official, trademarked Infortts™ Acoustic-Refraction™ / Rocky-Vision™ Design Theme.
class AcousticTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AcousticColors.black,
      colorScheme: ColorScheme.dark(
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
          bodyLarge: TextStyle(
            color: AcousticColors.steel,
            letterSpacing: 0.1,
          ),
          bodyMedium: TextStyle(
            color: AcousticColors.midGray,
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AcousticColors.lightBackground,
      colorScheme: ColorScheme.light(
        background: AcousticColors.lightBackground,
        surface: AcousticColors.lightSurface,
        surfaceContainerHighest: AcousticColors.lightSurfaceVariant,
        primary: AcousticColors.sonarBlue,
        secondary: AcousticColors.sonarCyan,
        error: AcousticColors.warnOrange,
        onBackground: AcousticColors.lightOnBackground,
        onSurface: AcousticColors.lightOnSurface,
        onSurfaceVariant: AcousticColors.lightOnSurfaceVariant,
        outline: AcousticColors.lightOutline,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        TextTheme(
          displayLarge: TextStyle(
            color: AcousticColors.lightOnBackground,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.2,
          ),
          titleLarge: TextStyle(
            color: AcousticColors.lightOnSurface,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          bodyLarge: const TextStyle(
            color: AcousticColors.lightOnSurfaceVariant,
            letterSpacing: 0.1,
          ),
          bodyMedium: const TextStyle(
            color: AcousticColors.lightOutline,
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
