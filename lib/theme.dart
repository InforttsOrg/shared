import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global switch that flips the Acoustic palette between dark and light.
/// The terminal app paints the whole UI from [AcousticColors], so flipping
/// this and rebuilding MaterialApp re-skins every screen (not just Material
/// widgets).
final ValueNotifier<Brightness> acousticBrightness =
    ValueNotifier<Brightness>(Brightness.dark);

/// Global dynamic theme override configuration for OTA theming
final ValueNotifier<AcousticDynamicThemeConfig?> acousticDynamicTheme =
    ValueNotifier<AcousticDynamicThemeConfig?>(null);

/// Configuration model for OTA dynamic theming and per-app styling.
///
/// Extended 2026-10-06 so a per-app design skill can drive the FULL palette.
/// Previously only 7 slots were overridable, which meant `AcousticColors.activeCard`,
/// `.steel`, `.titanium`, `.midGray` and `.sonarCyanDim` — all referenced by
/// `InforttsAppShell` — stayed hardcoded sonar/titanium, so an app could change
/// its accent but not actually look like a different design.
///
/// Every slot is nullable and falls back to the canonical Rocky-Vision value,
/// so existing callers and OTA payloads that only set the original 7 fields
/// behave exactly as before.
class AcousticDynamicThemeConfig {
  final Color? primaryColor;
  final Color? secondaryColor;
  final Color? darkBg;
  final Color? darkPanelBg;
  final Color? lightBg;
  final Color? lightPanelBg;
  final Color? warnColor;
  final String? fontFamily;
  final double? cardBorderRadius;

  // --- added 2026-10-06: full-palette per-app theming ---
  final Color? activeCardColor;
  final Color? steelColor;
  final Color? titaniumColor;
  final Color? midGrayColor;
  final Color? obsidianColor;
  final Color? primaryDimColor;
  final Color? dangerColor;
  final Color? successColor;
  final Color? textOnSurface;

  /// Light-mode subtext. Separate from [steelColor] because that slot is the
  /// DARK-mode body colour — using it on a light surface left subtext near
  /// invisible (a skill's dark subtext is tuned for a dark panel).
  final Color? lightSubTextColor;
  final Color? outlineColor;
  final String? monoFamily;
  final String? displayFamily;
  final double? bodyTextSize;
  final double? headingTextSize;
  final double? radiusSm;

  const AcousticDynamicThemeConfig({
    this.primaryColor,
    this.secondaryColor,
    this.darkBg,
    this.darkPanelBg,
    this.lightBg,
    this.lightPanelBg,
    this.warnColor,
    this.fontFamily,
    this.cardBorderRadius,
    this.activeCardColor,
    this.steelColor,
    this.titaniumColor,
    this.midGrayColor,
    this.obsidianColor,
    this.primaryDimColor,
    this.dangerColor,
    this.successColor,
    this.textOnSurface,
    this.lightSubTextColor,
    this.outlineColor,
    this.monoFamily,
    this.displayFamily,
    this.bodyTextSize,
    this.headingTextSize,
    this.radiusSm,
  });

  factory AcousticDynamicThemeConfig.fromJson(Map<String, dynamic> json) {
    // A malformed colour must degrade to the canonical palette, never throw:
    // this runs on the OTA path during app startup, so an unhandled
    // FormatException here would take the whole app down over one bad hex.
    Color? parseColor(dynamic val) {
      if (val is String && val.startsWith("#")) {
        final hex = val.substring(1);
        final normalised = hex.length == 3
            ? hex.split('').map((c) => '$c$c').join()
            : hex;
        if (normalised.length == 6 || normalised.length == 8) {
          try {
            return normalised.length == 6
                ? Color(int.parse('FF$normalised', radix: 16))
                : Color(int.parse(normalised, radix: 16));
          } on FormatException {
            return null;
          }
        }
        return null;
      }
      // `toJson` emits a 32-bit ARGB int, so accept ints too — otherwise a
      // round-trip through toJson/fromJson silently drops every colour.
      if (val is int) return Color(val);
      return null;
    }

    double? num_(String k) {
      final v = json[k];
      return (v is num) ? v.toDouble() : (v is String ? double.tryParse(v) : null);
    }

    return AcousticDynamicThemeConfig(
      primaryColor: parseColor(json['primary_color']),
      secondaryColor: parseColor(json['secondary_color']),
      darkBg: parseColor(json['dark_bg']),
      darkPanelBg: parseColor(json['dark_panel_bg']),
      lightBg: parseColor(json['light_bg']),
      lightPanelBg: parseColor(json['light_panel_bg']),
      warnColor: parseColor(json['warn_color']),
      // Typed as String? by a plain cast: a non-String (e.g. a stray number in an
      // OTA payload) raised a TypeError that took the app down at startup. Same
      // "degrade, never crash" rule as parseColor above.
      fontFamily: json['font_family'] is String ? json['font_family'] as String : null,
      // Accept both spellings: `border_radius` is the original OTA key (and what
      // toJson emits), `card_border_radius` matches the Dart field name that the
      // generated skins use.
      cardBorderRadius: num_('border_radius') ?? num_('card_border_radius'),
      activeCardColor: parseColor(json['active_card_color']),
      steelColor: parseColor(json['steel_color']),
      titaniumColor: parseColor(json['titanium_color']),
      midGrayColor: parseColor(json['mid_gray_color']),
      obsidianColor: parseColor(json['obsidian_color']),
      primaryDimColor: parseColor(json['primary_dim_color']),
      dangerColor: parseColor(json['danger_color']),
      successColor: parseColor(json['success_color']),
      textOnSurface: parseColor(json['text_on_surface']),
      lightSubTextColor: parseColor(json['light_sub_text_color']),
      outlineColor: parseColor(json['outline_color']),
      monoFamily: json['mono_family'] is String ? json['mono_family'] as String : null,
      displayFamily: json['display_family'] is String ? json['display_family'] as String : null,
      bodyTextSize: num_('body_text_size'),
      headingTextSize: num_('heading_text_size'),
      radiusSm: num_('radius_sm'),
    );
  }

  // `.toARGB32()` rather than the deprecated `.value`: same 32-bit ARGB int,
  // no deprecation warning, and it round-trips through `fromJson` unchanged.
  Map<String, dynamic> toJson() => {
        'primary_color': primaryColor?.toARGB32(),
        'secondary_color': secondaryColor?.toARGB32(),
        'dark_bg': darkBg?.toARGB32(),
        'dark_panel_bg': darkPanelBg?.toARGB32(),
        'light_bg': lightBg?.toARGB32(),
        'light_panel_bg': lightPanelBg?.toARGB32(),
        'warn_color': warnColor?.toARGB32(),
        'font_family': fontFamily,
        'border_radius': cardBorderRadius,
        'active_card_color': activeCardColor?.toARGB32(),
        'steel_color': steelColor?.toARGB32(),
        'titanium_color': titaniumColor?.toARGB32(),
        'mid_gray_color': midGrayColor?.toARGB32(),
        'obsidian_color': obsidianColor?.toARGB32(),
        'primary_dim_color': primaryDimColor?.toARGB32(),
        'danger_color': dangerColor?.toARGB32(),
        'success_color': successColor?.toARGB32(),
        'text_on_surface': textOnSurface?.toARGB32(),
        'light_sub_text_color': lightSubTextColor?.toARGB32(),
        'outline_color': outlineColor?.toARGB32(),
        'mono_family': monoFamily,
        'display_family': displayFamily,
        'body_text_size': bodyTextSize,
        'heading_text_size': headingTextSize,
        'radius_sm': radiusSm,
      };

  /// Copy-with so a skin can layer on top of an existing OTA config.
  AcousticDynamicThemeConfig merge(AcousticDynamicThemeConfig? base) {
    if (base == null) return this;
    Color? pick(Color? a, Color? b) => a ?? b;
    double? pickD(double? a, double? b) => a ?? b;
    String? pickS(String? a, String? b) => a ?? b;
    return AcousticDynamicThemeConfig(
      primaryColor: pick(primaryColor, base.primaryColor),
      secondaryColor: pick(secondaryColor, base.secondaryColor),
      darkBg: pick(darkBg, base.darkBg),
      darkPanelBg: pick(darkPanelBg, base.darkPanelBg),
      lightBg: pick(lightBg, base.lightBg),
      lightPanelBg: pick(lightPanelBg, base.lightPanelBg),
      warnColor: pick(warnColor, base.warnColor),
      fontFamily: pickS(fontFamily, base.fontFamily),
      cardBorderRadius: pickD(cardBorderRadius, base.cardBorderRadius),
      activeCardColor: pick(activeCardColor, base.activeCardColor),
      steelColor: pick(steelColor, base.steelColor),
      titaniumColor: pick(titaniumColor, base.titaniumColor),
      midGrayColor: pick(midGrayColor, base.midGrayColor),
      obsidianColor: pick(obsidianColor, base.obsidianColor),
      primaryDimColor: pick(primaryDimColor, base.primaryDimColor),
      dangerColor: pick(dangerColor, base.dangerColor),
      successColor: pick(successColor, base.successColor),
      textOnSurface: pick(textOnSurface, base.textOnSurface),
      lightSubTextColor: pick(lightSubTextColor, base.lightSubTextColor),
      outlineColor: pick(outlineColor, base.outlineColor),
      monoFamily: pickS(monoFamily, base.monoFamily),
      displayFamily: pickS(displayFamily, base.displayFamily),
      bodyTextSize: pickD(bodyTextSize, base.bodyTextSize),
      headingTextSize: pickD(headingTextSize, base.headingTextSize),
      radiusSm: pickD(radiusSm, base.radiusSm),
    );
  }
}

/// The official, trademarked Infortts™ Acoustic-Refraction™ / Rocky-Vision™ Color Palette.
class AcousticColors {
  static bool get isLight => acousticBrightness.value == Brightness.light;
  static AcousticDynamicThemeConfig? get _dynamic => acousticDynamicTheme.value;

  static void applyDynamicTheme(AcousticDynamicThemeConfig config) {
    acousticDynamicTheme.value = config;
  }

  static void resetDynamicTheme() {
    acousticDynamicTheme.value = null;
  }

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

  // ---- Dynamic Base Getters (OTA + per-app skill adaptive) ----
  // Extended 2026-10-06. These slots used to ignore `_dynamic`
  // (activeCard / obsidian / midGray / steel / titanium / sonarCyanDim and the
  // light-mode consts), so a per-app skin could only recolour the accent while
  // `InforttsAppShell` kept painting canonical sonar/titanium. They now resolve,
  // with the original Rocky-Vision constants retained as fallbacks.
  static Color get black => isLight ? (_dynamic?.lightBg ?? blackLight) : (_dynamic?.darkBg ?? blackDark);
  static Color get obsidian => isLight ? obsidianLight : (_dynamic?.obsidianColor ?? obsidianDark);
  static Color get darkCarbon => isLight ? (_dynamic?.lightBg ?? darkCarbonLight) : (_dynamic?.darkBg ?? darkCarbonDark);
  static Color get panelBg => isLight ? (_dynamic?.lightPanelBg ?? panelBgLight) : (_dynamic?.darkPanelBg ?? panelBgDark);
  static Color get activeCard => _dynamic?.activeCardColor ?? (isLight ? activeCardLight : activeCardDark);

  // ---- Desaturated Midtones (Cool Slate) ----
  static const Color midGrayDark = Color(0xFF64748B);       // Borders and subtext (Slate 500)
  static const Color midGrayLight = Color(0xFF94A3B8);      // Borders and subtext in light (Slate 400)
  static Color get midGray => isLight ? midGrayLight : (_dynamic?.midGrayColor ?? midGrayDark);

  static const Color steelDark = Color(0xFF94A3B8);         // Body copy (Slate 400)
  static const Color steelLight = Color(0xFF475569);        // Body copy in light (Slate 600)
  static Color get steel => isLight ? (_dynamic?.lightSubTextColor ?? steelLight) : (_dynamic?.steelColor ?? steelDark);

  static const Color titaniumDark = Color(0xFFE2E8F0);      // High-contrast titles (Slate 200)
  static const Color titaniumLight = Color(0xFF0F172A);     // High-contrast titles in light (Slate 900)
  static Color get titanium => isLight ? (_dynamic?.textOnSurface ?? titaniumLight) : (_dynamic?.titaniumColor ?? titaniumDark);

  // ---- Motivated Emissives (Acoustic Cyan & Warm Warnings) ----
  static Color get sonarCyan => _dynamic?.primaryColor ?? const Color(0xFF00D2FF);     // Active state
  static Color get sonarCyanDim => _dynamic?.primaryDimColor ?? const Color(0xFF005566);  // Idle/ambient shadow glow
  static Color get sonarBlue => _dynamic?.secondaryColor ?? const Color(0xFF0066FF);     // Low-frequency active state
  static Color get warnOrange => _dynamic?.warnColor ?? const Color(0xFFF97316);    // Low-saturation warning

  // Semantic status colours — used by shared/ status + notification widgets so a
  // skin's success/danger read correctly instead of always being the sonar ramp.
  static Color get danger => _dynamic?.dangerColor ?? const Color(0xFFEA2143);
  static Color get success => _dynamic?.successColor ?? const Color(0xFF00FF9D);

  // ---- Typography slots (skill-driven; resolved via google_fonts at build) ----
  static String? get fontFamily => _dynamic?.fontFamily;
  static String? get monoFamily => _dynamic?.monoFamily;
  static String? get displayFamily => _dynamic?.displayFamily;
  static double? get bodyTextSize => _dynamic?.bodyTextSize;
  static double? get headingTextSize => _dynamic?.headingTextSize;

  // ---- Geometry slots ----
  static double get cardBorderRadius => _dynamic?.cardBorderRadius ?? 16.0;
  static double get cornerRadiusSm => _dynamic?.radiusSm ?? 8.0;

  // Light theme colors
  static Color get lightBackground => _dynamic?.lightBg ?? const Color(0xFFF8FAFC);   // Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF);      // White
  static Color get lightSurfaceVariant => _dynamic?.lightPanelBg ?? const Color(0xFFF1F5F9); // Slate 100
  static Color get lightOnBackground => _dynamic?.textOnSurface ?? const Color(0xFF0F172A);  // Slate 900
  static Color get lightOnSurface => _dynamic?.textOnSurface ?? const Color(0xFF1E293B);     // Slate 800
  static Color get lightOutline => _dynamic?.outlineColor ?? const Color(0xFFCBD5E1);      // Slate 300
  static Color get lightOnSurfaceVariant => _dynamic?.lightSubTextColor ?? const Color(0xFF475569); // Slate 600
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
          bodyLarge: TextStyle(
            color: AcousticColors.lightOnSurfaceVariant,
            letterSpacing: 0.1,
          ),
          bodyMedium: TextStyle(
            color: AcousticColors.lightOutline,
          ),
        ),
      ),
    );
  }
  
  // Spacious padding/margin definitions for premium youth-focused minimalist layouts.
  // Canonical Rocky-Vision rhythm; per-app skins may scale these via
  // `AcousticSpacing.of(context)` (see design.dart).
  static const double spacingXS = 8.0;
  static const double spacingS = 16.0;
  static const double spacingM = 24.0;
  static const double spacingL = 36.0;
  static const double spacingXL = 48.0;
  static const double spacingXXL = 64.0;

  // ---- Skill-aware ThemeData --------------------------------------------
  // `darkTheme`/`lightTheme` above are preserved verbatim as the canonical
  // Rocky-Vision themes. These variants additionally honour the per-app skill
  // typography/geometry slots so a skin changes more than colour.
  static ThemeData themedDark({AcousticDynamicThemeConfig? skin}) {
    final base = darkTheme;
    return _applySkin(base, skin);
  }

  static ThemeData themedLight({AcousticDynamicThemeConfig? skin}) {
    final base = lightTheme;
    return _applySkin(base, skin);
  }

  /// Overlay an app's skin onto ANY existing ThemeData.
  ///
  /// Sixteen apps in this monorepo define their own theme (EdiacaraTheme.dark(),
  /// PrismTheme.darkTheme, buildJarvisTheme, inline `ThemeData(...)`) rather than
  /// using `AcousticTheme`. Those apps still get the accent from
  /// `AcousticColors`, but their ThemeData would otherwise keep the local
  /// palette. Wrapping their existing theme with this is a one-line, non-
  /// destructive change: the original theme is preserved as the base and only
  /// the colour scheme, typography and card geometry are overridden.
  static ThemeData applySkinTo(ThemeData base, AcousticDynamicThemeConfig? skin) {
    if (skin == null) return base;
    return _applySkin(
      base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: skin.primaryColor ?? base.colorScheme.primary,
          secondary: skin.secondaryColor ?? base.colorScheme.secondary,
          error: skin.dangerColor ?? base.colorScheme.error,
          surface: skin.darkPanelBg ?? base.colorScheme.surface,
        ),
      ),
      skin,
    );
  }

  static ThemeData _applySkin(ThemeData base, AcousticDynamicThemeConfig? skin) {
    if (skin == null) return base;

    final bodyFamily = skin.fontFamily;
    final headingFamily = skin.displayFamily ?? skin.fontFamily;

    var text = base.textTheme;

    // Headings and body are scaled independently of the font family. Keying
    // both on `family != null` meant a skill that set a size but no family
    // applied its typography at all — and that is the common case, since 61 of
    // the 67 source skills specify a display font but no body font override.
    if (headingFamily != null || skin.headingTextSize != null) {
      final h = headingFamily;
      text = text.copyWith(
        displayLarge: _retype(text.displayLarge, h, skin.headingTextSize),
        displayMedium: _retype(text.displayMedium, h, skin.headingTextSize),
        displaySmall: _retype(text.displaySmall, h, skin.headingTextSize),
        // `headline*` are the styles Material actually uses for section
        // headings; without them the skill's heading size was invisible in
        // practice even though it was set.
        headlineLarge: _retype(text.headlineLarge, h, skin.headingTextSize),
        headlineMedium: _retype(text.headlineMedium, h, skin.headingTextSize),
        headlineSmall: _retype(text.headlineSmall, h, skin.headingTextSize),
        titleLarge: _retype(text.titleLarge, h, null),
        titleMedium: _retype(text.titleMedium, h, null),
      );
    }
    if (bodyFamily != null || skin.bodyTextSize != null) {
      final b = bodyFamily;
      text = text.copyWith(
        bodyLarge: _retype(text.bodyLarge, b, skin.bodyTextSize),
        bodyMedium: _retype(text.bodyMedium, b, skin.bodyTextSize),
        bodySmall: _retype(text.bodySmall, b, skin.bodyTextSize),
        labelLarge: _retype(text.labelLarge, b, null),
      );
    }

    return base.copyWith(
      textTheme: text,
      cardTheme: base.cardTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(skin.cardBorderRadius ?? 16.0),
          side: BorderSide(color: AcousticColors.midGray),
        ),
      ),
    );
  }

  /// [family] and [size] are both independently optional: a skin may specify
  /// a size without a family (or vice versa), and each null means "leave this
  /// aspect of the base style alone".
  static TextStyle? _retype(TextStyle? style, String? family, double? size) {
    if (style == null) return style;
    if (family == null && size == null) return style;
    final resolved = family == null ? null : _resolveFont(family);
    return style.copyWith(
      fontFamily: resolved ?? style.fontFamily,
      fontSize: size ?? style.fontSize,
    );
  }

  /// Resolve a skill's font name to something Flutter can render.
  ///
  /// Deliberately does NOT call `GoogleFonts.getFont`: that helper fetches font
  /// files from fonts.gstatic.com at runtime when a family is not already in the
  /// asset cache. Calling it from a `ThemeData` builder means up to nine network
  /// fetches during the first frame, which fails silently offline and stalls
  /// CI. Assigning the family name directly lets Flutter use it when the font is
  /// bundled and fall back to the platform default when it is not — no crash,
  /// no network, and the skill still applies wherever the font is available.
  static String? _resolveFont(String family) {
    final trimmed = family.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// Unified Infortts Theme State provided by [InforttsThemeProvider].
class InforttsThemeData {
  final ThemeMode themeMode;
  final Brightness resolvedBrightness;
  final AcousticDynamicThemeConfig? skin;
  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final void Function() toggleTheme;
  final void Function(ThemeMode mode) setThemeMode;
  final void Function(Brightness brightness) setBrightness;

  const InforttsThemeData({
    required this.themeMode,
    required this.resolvedBrightness,
    required this.skin,
    required this.lightTheme,
    required this.darkTheme,
    required this.toggleTheme,
    required this.setThemeMode,
    required this.setBrightness,
  });

  bool get isDark => resolvedBrightness == Brightness.dark;
  bool get isLight => resolvedBrightness == Brightness.light;
}

class _InforttsThemeInherited extends InheritedWidget {
  final InforttsThemeData data;

  const _InforttsThemeInherited({
    required this.data,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InforttsThemeInherited oldWidget) {
    return data.themeMode != oldWidget.data.themeMode ||
        data.resolvedBrightness != oldWidget.data.resolvedBrightness ||
        data.skin != oldWidget.data.skin;
  }
}

/// A unified, cross-application theme controller and provider for the Infortts ecosystem.
///
/// Automatically synchronizes [acousticBrightness], [acousticDynamicTheme],
/// persists user preference across app restarts via SharedPreferences,
/// and allows toggling between Dark, Light, and System modes.
class InforttsThemeProvider extends StatefulWidget {
  final Widget child;
  final AcousticDynamicThemeConfig? skin;
  final ThemeMode initialThemeMode;

  const InforttsThemeProvider({
    super.key,
    required this.child,
    this.skin,
    this.initialThemeMode = ThemeMode.dark,
  });

  static InforttsThemeData of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<_InforttsThemeInherited>();
    if (inherited == null) {
      throw FlutterError('InforttsThemeProvider.of() called with a context that does not contain InforttsThemeProvider.');
    }
    return inherited.data;
  }

  static InforttsThemeData? maybeOf(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<_InforttsThemeInherited>();
    return inherited?.data;
  }

  @override
  State<InforttsThemeProvider> createState() => InforttsThemeProviderState();
}

class InforttsThemeProviderState extends State<InforttsThemeProvider> {
  static const String _kThemePrefKey = 'infortts_theme_mode';
  late ThemeMode _themeMode;
  AcousticDynamicThemeConfig? _skin;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
    _skin = widget.skin;
    if (_skin != null) {
      AcousticColors.applyDynamicTheme(_skin!);
    }
    _loadPersistedTheme();
  }

  Future<void> _loadPersistedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kThemePrefKey);
      if (saved != null) {
        if (saved == 'light') {
          _setModeInternal(ThemeMode.light, persist: false);
        } else if (saved == 'dark') {
          _setModeInternal(ThemeMode.dark, persist: false);
        } else if (saved == 'system') {
          _setModeInternal(ThemeMode.system, persist: false);
        }
      } else {
        _syncAcousticBrightness();
      }
    } catch (_) {
      _syncAcousticBrightness();
    }
  }

  void _syncAcousticBrightness() {
    Brightness target;
    if (_themeMode == ThemeMode.light) {
      target = Brightness.light;
    } else if (_themeMode == ThemeMode.dark) {
      target = Brightness.dark;
    } else {
      try {
        target = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      } catch (_) {
        target = Brightness.dark;
      }
    }
    if (acousticBrightness.value != target) {
      acousticBrightness.value = target;
    }
  }

  void _setModeInternal(ThemeMode mode, {bool persist = true}) {
    if (_themeMode == mode) return;
    setState(() {
      _themeMode = mode;
      _syncAcousticBrightness();
    });
    if (persist) {
      SharedPreferences.getInstance().then((prefs) {
        final val = mode == ThemeMode.light ? 'light' : (mode == ThemeMode.dark ? 'dark' : 'system');
        prefs.setString(_kThemePrefKey, val);
      }).catchError((_) {});
    }
  }

  void toggleTheme() {
    final next = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _setModeInternal(next);
  }

  void setThemeMode(ThemeMode mode) {
    _setModeInternal(mode);
  }

  void setBrightness(Brightness brightness) {
    _setModeInternal(brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedBrightness = _themeMode == ThemeMode.light ? Brightness.light : Brightness.dark;

    final themeData = InforttsThemeData(
      themeMode: _themeMode,
      resolvedBrightness: resolvedBrightness,
      skin: _skin,
      lightTheme: AcousticTheme.themedLight(skin: _skin),
      darkTheme: AcousticTheme.themedDark(skin: _skin),
      toggleTheme: toggleTheme,
      setThemeMode: setThemeMode,
      setBrightness: setBrightness,
    );

    return _InforttsThemeInherited(
      data: themeData,
      child: widget.child,
    );
  }
}

