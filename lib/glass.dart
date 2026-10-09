import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'theme.dart';

/// Loads and caches a [ui.FragmentProgram] for [AcousticGlassPanel].
///
/// The infortts_shared shaders are registered under the package-prefixed
/// asset key, but when the package itself is exercised directly (its own
/// test bundle) the unprefixed key applies — both are tried. Any failure
/// (missing asset, platform without runtime shader support, compile error)
/// resolves to `null` so callers degrade to the non-shader panel.
class AcousticGlassShader {
  AcousticGlassShader._();

  static const List<String> defaultKeys = [
    'packages/infortts_shared/shaders/acoustic_glass.frag',
    'shaders/acoustic_glass.frag',
  ];

  static final Map<String, Future<ui.FragmentProgram?>> _cache = {};

  /// Returns the compiled program for [assetKeys], or `null` if none of the
  /// keys could be loaded. Results are cached per key sequence.
  static Future<ui.FragmentProgram?> load(List<String> assetKeys) {
    return _cache.putIfAbsent(assetKeys.join('|'), () async {
      for (final key in assetKeys) {
        try {
          return await ui.FragmentProgram.fromAsset(key);
        } catch (_) {
          // Missing asset or unsupported platform: try the next key.
        }
      }
      return null;
    });
  }

  /// Clears the program cache. Intended for tests.
  @visibleForTesting
  static void debugClearCache() => _cache.clear();
}

/// AcousticGlassPanel: Hardware-accelerated adaptive frosted glass panel.
///
/// Renders the glass fill (tint, luminous inner border, sheen) with a Flutter
/// [ui.FragmentProgram] compiled from `shaders/acoustic_glass.frag`, on top of
/// a compositor [BackdropFilter] frost pass. If the shader asset is missing
/// or the platform does not support runtime shaders, the panel silently
/// degrades to a plain translucent [BackdropFilter]/color panel — never a
/// visual crash.
class AcousticGlassPanel extends StatefulWidget {
  final Widget child;
  final double blurSigma;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? tintColor;

  /// Tint opacity, 0..1.
  final double opacity;

  /// Strength of the shader's luminous inner edge, 0..1. Ignored by the
  /// fallback panel.
  final double borderLuminosity;

  /// Drop-shadow depth in logical px; 0 disables the shadow.
  final double elevation;

  final Border? border;

  /// When false, the shader layer is skipped entirely and the plain
  /// translucent panel is used. Defaults to true.
  final bool enableShader;

  /// Asset keys probed for the glass fragment program, in order.
  final List<String> shaderAssetKeys;

  const AcousticGlassPanel({
    super.key,
    required this.child,
    this.blurSigma = 18.0,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(AcousticTheme.spacingM),
    this.margin,
    this.tintColor,
    this.opacity = 0.65,
    this.borderLuminosity = 0.5,
    this.elevation = 24.0,
    this.border,
    this.enableShader = true,
    this.shaderAssetKeys = AcousticGlassShader.defaultKeys,
  });

  @override
  State<AcousticGlassPanel> createState() => _AcousticGlassPanelState();
}

class _AcousticGlassPanelState extends State<AcousticGlassPanel> {
  ui.FragmentProgram? _program;
  ui.FragmentShader? _shader;
  bool _loadStarted = false;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  @override
  void didUpdateWidget(covariant AcousticGlassPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shaderAssetKeys != widget.shaderAssetKeys) {
      _loadShader();
    }
  }

  Future<void> _loadShader() async {
    if (!widget.enableShader) return;
    if (_loadStarted &&
        _lastRequestedKeys != null &&
        listEquals(_lastRequestedKeys, widget.shaderAssetKeys)) {
      return;
    }
    _loadStarted = true;
    _lastRequestedKeys = widget.shaderAssetKeys;
    final program = await AcousticGlassShader.load(widget.shaderAssetKeys);
    if (!mounted) return;
    setState(() {
      _program = program;
      _shader?.dispose();
      _shader = program?.fragmentShader();
    });
  }

  List<String>? _lastRequestedKeys;

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = acousticBrightness.value == Brightness.light;
    final defaultTint = isLight ? Colors.white : AcousticColors.panelBg;
    final effectiveTint = widget.tintColor ?? defaultTint;

    final effectiveBorder = widget.border ??
        Border.all(
          color: (isLight ? Colors.white : Colors.white24)
              .withValues(alpha: 0.18),
          width: 1.0,
        );

    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      boxShadow: widget.elevation > 0
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: isLight ? 0.06 : 0.28),
                blurRadius: widget.elevation,
                offset: Offset(0, widget.elevation / 3),
              ),
            ]
          : null,
    );

    final useShader = _program != null && _shader != null;

    final inner = Container(
      padding: widget.padding,
      decoration: useShader
          ? null
          : BoxDecoration(
              color: effectiveTint.withValues(alpha: widget.opacity),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: effectiveBorder,
            ),
      child: widget.child,
    );

    return Container(
      margin: widget.margin,
      decoration: decoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: widget.blurSigma,
            sigmaY: widget.blurSigma,
          ),
          child: useShader
              ? CustomPaint(
                  painter: _GlassShaderPainter(
                    shader: _shader!,
                    tint: effectiveTint,
                    tintOpacity: widget.opacity,
                    borderLuminosity: widget.borderLuminosity,
                    cornerRadius: widget.borderRadius,
                    border: effectiveBorder,
                  ),
                  child: inner,
                )
              : inner,
        ),
      ),
    );
  }
}

/// Paints the GPU glass fill via the [AcousticGlassPanel] fragment program,
/// and strokes the logical border on top when one is provided.
class _GlassShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final Color tint;
  final double tintOpacity;
  final double borderLuminosity;
  final double cornerRadius;
  final Border? border;

  _GlassShaderPainter({
    required this.shader,
    required this.tint,
    required this.tintOpacity,
    required this.borderLuminosity,
    required this.cornerRadius,
    required this.border,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, tint.r)
      ..setFloat(3, tint.g)
      ..setFloat(4, tint.b)
      ..setFloat(5, tintOpacity)
      ..setFloat(6, borderLuminosity)
      ..setFloat(7, cornerRadius);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);

    if (border != null) {
      final rrect = RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(cornerRadius),
      );
      final sides = border!;
      final paint = Paint()
        ..style = PaintingStyle.stroke;
      canvas.save();
      canvas.clipRRect(rrect);
      if (sides.top.width > 0) {
        canvas.drawLine(
          Offset.zero,
          Offset(size.width, 0),
          paint
            ..strokeWidth = sides.top.width
            ..color = sides.top.color,
        );
      }
      if (sides.bottom.width > 0) {
        canvas.drawLine(
          Offset(0, size.height),
          Offset(size.width, size.height),
          paint
            ..strokeWidth = sides.bottom.width
            ..color = sides.bottom.color,
        );
      }
      if (sides.left.width > 0) {
        canvas.drawLine(
          Offset.zero,
          Offset(0, size.height),
          paint
            ..strokeWidth = sides.left.width
            ..color = sides.left.color,
        );
      }
      if (sides.right.width > 0) {
        canvas.drawLine(
          Offset(size.width, 0),
          Offset(size.width, size.height),
          paint
            ..strokeWidth = sides.right.width
            ..color = sides.right.color,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _GlassShaderPainter oldDelegate) =>
      oldDelegate.shader != shader ||
      oldDelegate.tint != tint ||
      oldDelegate.tintOpacity != tintOpacity ||
      oldDelegate.borderLuminosity != borderLuminosity ||
      oldDelegate.cornerRadius != cornerRadius ||
      oldDelegate.border != border;
}
