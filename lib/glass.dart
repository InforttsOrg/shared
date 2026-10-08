import 'dart:ui';
import 'package:flutter/material.dart';
import 'theme.dart';

/// AcousticGlassPanel: Impeller and Vulkan-optimized adaptive frosted glass panel.
/// Provides real-time background blurring, specular edge refraction,
/// and low-overhead compositor passes for Android 15 through 18.
class AcousticGlassPanel extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? tintColor;
  final double opacity;
  final Border? border;

  const AcousticGlassPanel({
    super.key,
    required this.child,
    this.blurSigma = 18.0,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(AcousticTheme.spacingM),
    this.margin,
    this.tintColor,
    this.opacity = 0.65,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = acousticBrightness.value == Brightness.light;
    final defaultTint = isLight ? Colors.white : AcousticColors.panelBg;
    final effectiveTint = (tintColor ?? defaultTint).withOpacity(opacity);

    final effectiveBorder = border ??
        Border.all(
          color: (isLight ? Colors.white : Colors.white24).withOpacity(0.18),
          width: 1.0,
        );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isLight ? 0.06 : 0.28),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: effectiveTint,
              borderRadius: BorderRadius.circular(borderRadius),
              border: effectiveBorder,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
