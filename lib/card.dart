import 'package:flutter/material.dart';
import 'theme.dart';

/// A high-performance, minimalist, volumetric container widget.
/// Implements motivated practical rim lighting via gradient borders,
/// radial gradient depth, and generous premium spacing.
class AcousticVolumetricCard extends StatelessWidget {
  final Widget child;
  final double padding;
  final double? width;
  final double? height;
  final bool isSelected;
  final String? appName;
  final Color? accentColor;
  final double borderRadius;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? margin;

  const AcousticVolumetricCard({
    super.key,
    required this.child,
    this.padding = AcousticTheme.spacingM,
    this.width,
    this.height,
    this.isSelected = false,
    this.appName,
    this.accentColor,
    this.borderRadius = 12.0,
    this.backgroundColor,
    this.margin,
  });

  Color _resolveAccent() {
    if (accentColor != null) return accentColor!;
    final name = (appName ?? "").toLowerCase();
    if (name.contains("mitochondria") || name.contains("forensic")) {
      return AcousticColors.sonarCyan;
    } else if (name.contains("yorgia")) {
      return AcousticColors.sonarBlue;
    } else if (name.contains("dickinsonia")) {
      return const Color(0xFF8B5CF6);
    } else if (name.contains("kimberella")) {
      return const Color(0xFF10B981);
    }
    return AcousticColors.sonarCyan;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = _resolveAccent();
    final effectiveBg = backgroundColor ?? (isSelected ? AcousticColors.activeCard : AcousticColors.panelBg);

    Widget cardWidget = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(borderRadius),
        // Soft volumetric shadow glow (motivated light bloom)
        boxShadow: [
          BoxShadow(
            color: isSelected 
                ? effectiveAccent.withOpacity(0.08) 
                : Colors.black.withOpacity(0.35),
            blurRadius: isSelected ? 32.0 : 16.0,
            offset: const Offset(0, 10),
          ),
          // Subtle inner rim glow represented as a standard low-opacity glow
          BoxShadow(
            color: effectiveAccent.withOpacity(isSelected ? 0.05 : 0.015),
            blurRadius: 12.0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Top-Right Motivated Practical Lighting Core (atmospheric gradient)
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      effectiveAccent.withOpacity(isSelected ? 0.10 : 0.04),
                      effectiveAccent.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            
            // Rim Border Simulator (1px high-contrast gradient overlay)
            CustomPaint(
              painter: _RimBorderPainter(
                isSelected: isSelected,
                accentColor: effectiveAccent,
                borderRadius: borderRadius,
              ),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );

    return cardWidget;
  }
}

class _RimBorderPainter extends CustomPainter {
  final bool isSelected;
  final Color accentColor;
  final double borderRadius;

  _RimBorderPainter({
    required this.isSelected,
    required this.accentColor,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    
    // Gradient is brightest at the upper-right (motivated rim-light source)
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          isSelected ? accentColor.withOpacity(0.50) : Colors.white.withOpacity(0.12),
          accentColor.withOpacity(0.05),
          Colors.black.withOpacity(0.85),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _RimBorderPainter oldDelegate) {
    return oldDelegate.isSelected != isSelected ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.borderRadius != borderRadius;
  }
}
