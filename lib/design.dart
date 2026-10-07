/// Smart, skin-aware design primitives.
///
/// WHY THIS FILE EXISTS
/// ---------------------
/// `projects/shared` is already depended on by 39 of the 47 projects, and
/// `InforttsAppShell` + `AcousticColors` are used by 29 apps each. That makes
/// `shared` the correct place to build generic, composable components: an app
/// should never hand-roll a card or a button, it should compose one of these and
/// let the app's design skin flow through automatically.
///
/// The operator's goal (2026-10-06) was that "each app feels different and clean,
/// not a copy of others". The way to get that without 40 divergent codebases is:
///
///   1. ONE component vocabulary  (this file + card.dart + status.dart)
///   2. ONE token contract        (theme.dart — `AcousticColors`, full-palette)
///   3. PER-APP skin values       (generated `design_skin.dart` per app)
///
/// So every widget here reads colours and geometry from `AcousticColors` /
/// `Theme.of(context)` at BUILD time — never from a hardcoded constant and never
/// from a value captured in a `const` constructor. That is what lets a single
/// component implementation render as a neo-brutalist card in one app and a
/// glassmorphic card in another, with zero per-app code.
///
/// The 3D Infortts brand (logo, emblem, shell chrome) is deliberately NOT
/// re-implemented here — it stays in `shell.dart` / `brand.dart` and is identical
/// across apps. These primitives are the *product surface* layer.

import 'package:flutter/material.dart';

import 'theme.dart';

/// Semantic spacing + geometry for the current skin.
///
/// Falls back to the canonical Rocky-Vision rhythm when no skin is applied, so
/// existing apps are unaffected.
class AcousticSpacing {
  const AcousticSpacing._({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  factory AcousticSpacing.of(BuildContext context) {
    final skin = AcousticColors.cornerRadiusSm;
    // A skin that sets a smaller radius is a "denser" skin: scale the rhythm
    // with it rather than inventing a second spacing source of truth.
    final density = (skin / 8.0).clamp(0.75, 1.5);
    return AcousticSpacing._(
      xs: AcousticTheme.spacingXS * density,
      sm: AcousticTheme.spacingS * density,
      md: AcousticTheme.spacingM * density,
      lg: AcousticTheme.spacingL * density,
      xl: AcousticTheme.spacingXL * density,
    );
  }

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
}

/// Semantic spacing/radius helper extensions for ergonomic call sites.
extension AcousticSpacingX on BuildContext {
  AcousticSpacing get gap => AcousticSpacing.of(this);
}

// ─────────────────────────────── surfaces ───────────────────────────────

/// A generic, skin-aware surface. This is the ONE card primitive apps should
/// reach for instead of `Card`/`Container` with hardcoded decoration.
///
/// It intentionally supports the treatments the design skills describe —
/// outlined, filled, elevated, tinted — without branching on which skill is
/// active. Colours always come from [AcousticColors] so any applied skin
/// restyles it.
enum AcousticSurfaceVariant { filled, outlined, elevated, tinted, ghost }

class AcousticSurface extends StatelessWidget {
  const AcousticSurface({
    super.key,
    required this.child,
    this.padding,
    this.variant = AcousticSurfaceVariant.filled,
    this.accent,
    this.onTap,
    this.borderRadius,
    this.glow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final AcousticSurfaceVariant variant;
  final Color? accent;
  final VoidCallback? onTap;

  /// Overrides the skin radius (rarely needed — leave null to follow the skin).
  final BorderRadius? borderRadius;

  /// Adds an accent glow. Used for "live"/focused states.
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final g = AcousticSpacing.of(context);
    final radius = borderRadius ?? BorderRadius.circular(AcousticColors.cardBorderRadius);
    final primary = accent ?? AcousticColors.sonarCyan;

    final Color bg;
    final Color? borderColor;
    List<BoxShadow> shadows;

    switch (variant) {
      case AcousticSurfaceVariant.filled:
        bg = AcousticColors.panelBg;
        borderColor = null;
        shadows = const [];
      case AcousticSurfaceVariant.outlined:
        bg = Colors.transparent;
        borderColor = AcousticColors.midGray;
        shadows = const [];
      case AcousticSurfaceVariant.elevated:
        bg = AcousticColors.activeCard;
        borderColor = null;
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ];
      case AcousticSurfaceVariant.tinted:
        bg = Color.alphaBlend(primary.withValues(alpha: 0.08), AcousticColors.panelBg);
        borderColor = primary.withValues(alpha: 0.35);
        shadows = const [];
      case AcousticSurfaceVariant.ghost:
        bg = Colors.transparent;
        borderColor = null;
        shadows = const [];
    }

    if (glow) {
      shadows = [
        ...shadows,
        BoxShadow(
          color: primary.withValues(alpha: 0.28),
          blurRadius: 28,
          spreadRadius: -4,
        ),
      ];
    }

    Widget content = Container(
      padding: padding ?? EdgeInsets.all(g.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: borderColor == null ? null : Border.all(color: borderColor, width: 1),
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      );
    }
    return content;
  }
}

// ─────────────────────────────── buttons ───────────────────────────────

enum AcousticButtonKind { primary, secondary, ghost, danger }

/// Skin-aware button. One implementation, every variant.
class AcousticButton extends StatelessWidget {
  const AcousticButton({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = AcousticButtonKind.primary,
    this.icon,
    this.dense = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AcousticButtonKind kind;
  final IconData? icon;
  final bool dense;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final g = AcousticSpacing.of(context);
    final enabled = onPressed != null;
    final radius = BorderRadius.circular(AcousticColors.cornerRadiusSm);

    late final Color bg;
    late final Color fg;
    Color? border;

    switch (kind) {
      case AcousticButtonKind.primary:
        bg = AcousticColors.sonarCyan;
        fg = _onColor(AcousticColors.sonarCyan);
        border = null;
      case AcousticButtonKind.secondary:
        bg = Colors.transparent;
        fg = AcousticColors.titanium;
        border = AcousticColors.midGray;
      case AcousticButtonKind.ghost:
        bg = Colors.transparent;
        fg = AcousticColors.steel;
        border = null;
      case AcousticButtonKind.danger:
        bg = AcousticColors.danger.withValues(alpha: enabled ? 0.14 : 0.06);
        fg = AcousticColors.danger;
        border = AcousticColors.danger.withValues(alpha: 0.45);
    }

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: dense ? 14 : 16, color: fg),
          SizedBox(width: g.xs),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: dense ? 12 : 14,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Material(
        color: bg,
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: dense ? g.sm : g.md,
              vertical: dense ? g.xs : g.sm * 0.75,
            ),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: border == null ? null : Border.all(color: border),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Pick readable foreground for an arbitrary accent (skills may set a light
  /// primary, e.g. the `paper` or `clean` skills).
  static Color _onColor(Color bg) {
    return bg.computeLuminance() > 0.55 ? const Color(0xFF0B0D10) : const Color(0xFFFFFFFF);
  }
}

// ─────────────────────────────── type ───────────────────────────────

/// Skin-aware text styles. Apps should use these instead of hardcoding
/// `TextStyle` + colours so a skin's typography actually lands.
class AcousticText {
  const AcousticText._();

  static TextStyle display(BuildContext context) {
    final base = Theme.of(context).textTheme.displayLarge;
    return (base ?? const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)).copyWith(
      color: AcousticColors.titanium,
      fontSize: AcousticColors.headingTextSize ?? base?.fontSize ?? 40,
    );
  }

  static TextStyle title(BuildContext context) {
    final base = Theme.of(context).textTheme.titleLarge;
    return (base ?? const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)).copyWith(
      color: AcousticColors.titanium,
    );
  }

  static TextStyle body(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyLarge;
    return (base ?? const TextStyle(fontSize: 15)).copyWith(
      color: AcousticColors.steel,
      fontSize: AcousticColors.bodyTextSize ?? base?.fontSize ?? 15,
    );
  }

  static TextStyle caption(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium;
    return (base ?? const TextStyle(fontSize: 13)).copyWith(
      color: AcousticColors.midGray,
    );
  }

  /// Uppercase mono label — the skills use these for section eyebrows and data.
  static TextStyle overline(BuildContext context) {
    return TextStyle(
      color: AcousticColors.sonarCyan,
      fontSize: AcousticColors.bodyTextSize == null ? 11 : (AcousticColors.bodyTextSize! * 0.75),
      letterSpacing: 1.4,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );
  }
}

// ─────────────────────────── composites ───────────────────────────

/// Section header + body. The most-reused composition in the monorepo.
class AcousticSection extends StatelessWidget {
  const AcousticSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.eyebrow,
  });

  final String title;
  final String? subtitle;
  final String? eyebrow;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final g = AcousticSpacing.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(eyebrow!.toUpperCase(), style: AcousticText.overline(context)),
          SizedBox(height: g.xs),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AcousticText.title(context)),
                  if (subtitle != null) ...[
                    SizedBox(height: g.xs * 0.5),
                    Text(subtitle!, style: AcousticText.caption(context)),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        SizedBox(height: g.sm),
        child,
      ],
    );
  }
}

/// Label/value row. Used across dashboards, settings and detail views.
class AcousticStatTile extends StatelessWidget {
  const AcousticStatTile({
    super.key,
    required this.label,
    required this.value,
    this.hint,
    this.accent,
    this.onTap,
  });

  final String label;
  final String value;
  final String? hint;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AcousticSurface(
      variant: AcousticSurfaceVariant.filled,
      onTap: onTap,
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(), style: AcousticText.overline(context)),
          const SizedBox(height: 6),
          Text(
            value,
            style: AcousticText.title(context).copyWith(
              color: accent ?? AcousticColors.titanium,
              fontSize: 22,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(hint!, style: AcousticText.caption(context)),
          ],
        ],
      ),
    );
  }
}

/// Empty / zero-data state. Keeps "nothing here yet" consistent app-wide.
class AcousticEmptyState extends StatelessWidget {
  const AcousticEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.action,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final g = AcousticSpacing.of(context);
    return AcousticSurface(
      variant: AcousticSurfaceVariant.ghost,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 28, color: AcousticColors.midGray),
            SizedBox(height: g.sm),
          ],
          Text(title, style: AcousticText.title(context), textAlign: TextAlign.center),
          if (message != null) ...[
            SizedBox(height: g.xs),
            Text(
              message!,
              style: AcousticText.caption(context),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            SizedBox(height: g.md),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Thin divider that respects the skin's border colour.
class AcousticDivider extends StatelessWidget {
  const AcousticDivider({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Container(height: 1, color: AcousticColors.midGray.withValues(alpha: 0.35)),
    );
  }
}

/// Badge / chip.
class AcousticBadge extends StatelessWidget {
  const AcousticBadge({
    super.key,
    required this.label,
    this.color,
    this.filled = false,
  });

  final String label;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final g = AcousticSpacing.of(context);
    final c = color ?? AcousticColors.sonarCyan;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: g.xs, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? c : c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: filled ? null : Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? AcousticButton._onColor(c) : c,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Progress meter used for risk/exposure/usage readouts.
class AcousticMeter extends StatelessWidget {
  const AcousticMeter({
    super.key,
    required this.value,
    this.color,
    this.height = 6,
  });

  /// 0.0 – 1.0
  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AcousticColors.sonarCyan;
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: [
          Container(height: height, color: AcousticColors.activeCard),
          FractionallySizedBox(
            widthFactor: v,
            child: Container(height: height, color: c),
          ),
        ],
      ),
    );
  }
}

/// App entrypoint helper: applies the generated per-app skin before `runApp`.
///
/// Typical generated `main.dart` for an app with a skin:
/// ```dart
/// void main() {
///   InforttsDesign.boot(const AppDesignSkin.yorgia());
///   runApp(const MyApp());
/// }
/// ```
///
/// Without a skin this is a no-op and the app keeps canonical Rocky Vision.
abstract final class InforttsDesign {
  static void boot(AcousticDynamicThemeConfig? skin, {Brightness? initialBrightness}) {
    if (skin != null) {
      AcousticColors.applyDynamicTheme(
        skin.merge(acousticDynamicTheme.value),
      );
    }
    if (initialBrightness != null) {
      acousticBrightness.value = initialBrightness;
    }
  }

  static void reset() {
    AcousticColors.resetDynamicTheme();
    acousticBrightness.value = Brightness.dark;
  }
}
