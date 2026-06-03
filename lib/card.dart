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

  const AcousticVolumetricCard({
    super.key,
    required this.child,
    this.padding = AcousticTheme.spacingM,
    this.width,
    this.height,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isSelected ? AcousticColors.activeCard : AcousticColors.panelBg,
        borderRadius: BorderRadius.circular(12.0),
        // Soft volumetric shadow glow (motivated light bloom)
        boxShadow: [
          BoxShadow(
            color: isSelected 
                ? AcousticColors.sonarCyan.withOpacity(0.05) 
                : Colors.black.withOpacity(0.3),
            blurRadius: isSelected ? 32.0 : 16.0,
            offset: const Offset(0, 10),
          ),
          // Subtle inner rim glow represented as a standard low-opacity glow
          BoxShadow(
            color: AcousticColors.sonarCyan.withOpacity(isSelected ? 0.04 : 0.01),
            blurRadius: 12.0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
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
                      AcousticColors.sonarCyan.withOpacity(isSelected ? 0.08 : 0.03),
                      AcousticColors.sonarCyan.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            
            // Rim Border Simulator (1px high-contrast gradient overlay)
            CustomPaint(
              painter: _RimBorderPainter(isSelected: isSelected),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RimBorderPainter extends CustomPainter {
  final bool isSelected;

  _RimBorderPainter({required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12.0));
    
    // Gradient is brightest at the upper-right (motivated rim-light source)
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          isSelected ? AcousticColors.sonarCyan.withOpacity(0.40) : Colors.white.withOpacity(0.12),
          AcousticColors.sonarCyan.withOpacity(0.03),
          Colors.black.withOpacity(0.90),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _RimBorderPainter oldDelegate) {
    return oldDelegate.isSelected != isSelected;
  }
}
